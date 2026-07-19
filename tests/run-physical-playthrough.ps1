[CmdletBinding()]
param(
    [string]$Godot = "D:\Tools\Godot-4.7.1\Godot_v4.7.1-stable_win64_console.exe",
    [ValidateSet("EditorF5", "ProjectRun")]
    # ProjectRun binds --log-file to the game process. EditorF5 only logs the
    # editor host; F5 spawns a separate game process whose prints are not captured.
    [string]$LaunchMode = "ProjectRun",
    [string]$CaptureReference = "",
    [switch]$ConfirmPhysicalInput,
    [string]$AnalyzeLog = "",
    [string]$EvidenceRoot = "",
    [ValidateRange(60, 14400)]
    [int]$LaunchTimeoutSeconds = 7200,
    [ValidateRange(1048576, 67108864)]
    [int64]$MaxCombinedOutputBytes = 16777216
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$pacingPrefix = "PLAYTHROUGH_PACING: "
$pacingSideChannelRelative = "playthrough_pacing_last.txt"
$expectedBoundaryOrder = @(
    "lobby",
    "floor4_dark",
    "floor4_powered",
    "memory_loop",
    "room_407",
    "chase",
    "ending",
    "credits"
)
$expectedChapterTargets = [ordered]@{
    opening = @(120.0, 180.0)
    floor4 = @(180.0, 240.0)
    memory_loop = @(240.0, 300.0)
    room407 = @(180.0, 240.0)
    chase_ending = @(120.0, 180.0)
}
$expectedChapterBoundaries = [ordered]@{
    opening = @("lobby", "floor4_dark")
    floor4 = @("floor4_dark", "memory_loop")
    memory_loop = @("memory_loop", "room_407")
    room407 = @("room_407", "chase")
    chase_ending = @("chase", "credits")
}
$maxPacingSideChannelBytes = [int64](1MB)
$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$physicalJobRunnerSource = Join-Path $PSScriptRoot "windows-export-job-runner.cs"
$artifactRoot = [System.IO.Path]::GetFullPath((Join-Path $repositoryRoot ".artifacts")).TrimEnd("\")
if (-not $EvidenceRoot) {
    $EvidenceRoot = Join-Path $repositoryRoot ".artifacts\manual-playthrough"
} elseif (-not [System.IO.Path]::IsPathRooted($EvidenceRoot)) {
    $EvidenceRoot = Join-Path $repositoryRoot $EvidenceRoot
}
$EvidenceRoot = [System.IO.Path]::GetFullPath($EvidenceRoot).TrimEnd("\")
$artifactPrefix = $artifactRoot + [System.IO.Path]::DirectorySeparatorChar
if ($EvidenceRoot -ne $artifactRoot -and -not $EvidenceRoot.StartsWith($artifactPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "EvidenceRoot must stay below the repository .artifacts directory: $EvidenceRoot"
}

function Assert-ContainedArtifactPath([string]$Path, [string]$Label) {
    $fullPath = [System.IO.Path]::GetFullPath($Path).TrimEnd("\")
    if ($fullPath -ne $artifactRoot -and -not $fullPath.StartsWith($artifactPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "$Label must stay below the repository .artifacts directory: $fullPath"
    }
    return $fullPath
}

function Get-FreeGiB([string]$DriveName) {
    $drive = Get-PSDrive -Name $DriveName -ErrorAction SilentlyContinue
    if ($null -eq $drive) {
        return $null
    }
    return [math]::Round($drive.Free / 1GB, 2)
}

function Assert-RegularEvidenceDirectory([string]$Path, [string]$Label) {
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "Expected evidence directory was not found ($Label): $Path"
    }
    $item = Get-Item -LiteralPath $Path -Force
    if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Refusing reparse-point evidence directory ($Label): $Path"
    }
    return $item
}

function Assert-NoReparsePointAncestors([string]$Path, [string]$Label, [switch]$AllowMissing) {
    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $pathRoot = [System.IO.Path]::GetPathRoot($fullPath)
    if ([string]::IsNullOrWhiteSpace($pathRoot)) {
        throw "Could not determine path root ($Label): $fullPath"
    }
    $current = $pathRoot
    $relative = $fullPath.Substring($pathRoot.Length)
    $parts = $relative.Split([char[]]@('\', '/'), [System.StringSplitOptions]::RemoveEmptyEntries)
    for ($index = 0; $index -lt $parts.Count; $index += 1) {
        $current = Join-Path $current $parts[$index]
        if (-not (Test-Path -LiteralPath $current)) {
            if ($AllowMissing) {
                continue
            }
            throw "Expected evidence path component was not found ($Label): $current"
        }
        $item = Get-Item -LiteralPath $current -Force
        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Refusing reparse-point evidence path component ($Label): $current"
        }
        if ($index -lt ($parts.Count - 1) -and -not $item.PSIsContainer) {
            throw "Evidence path ancestor is not a directory ($Label): $current"
        }
    }
    return $fullPath
}

function Assert-SafeEvidenceDestinationPath(
    [string]$TrustedRoot,
    [string]$TargetPath,
    [string]$Label
) {
    $trustedFull = [System.IO.Path]::GetFullPath($TrustedRoot).TrimEnd("\")
    $targetFull = [System.IO.Path]::GetFullPath($TargetPath).TrimEnd("\")
    $trustedPrefix = $trustedFull + [System.IO.Path]::DirectorySeparatorChar
    if ($targetFull -ne $trustedFull -and -not $targetFull.StartsWith($trustedPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "$Label escaped its trusted evidence root: $targetFull"
    }
    if (-not (Test-Path -LiteralPath $trustedFull -PathType Container)) {
        throw "$Label trusted evidence root is not a directory: $trustedFull"
    }
    [void](Assert-NoReparsePointAncestors $trustedFull "$Label trusted root")
    [void](Assert-NoReparsePointAncestors $targetFull $Label -AllowMissing)
    return $targetFull
}

function Remove-SafeEvidenceFile(
    [string]$TrustedRoot,
    [string]$TargetPath,
    [string]$Label
) {
    $targetFull = Assert-SafeEvidenceDestinationPath $TrustedRoot $TargetPath $Label
    if (-not (Test-Path -LiteralPath $targetFull)) {
        return
    }
    $targetItem = Get-Item -LiteralPath $targetFull -Force -ErrorAction Stop
    if ($targetItem.PSIsContainer -or
        ($targetItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "$Label is not a regular evidence file: $targetFull"
    }
    Remove-Item -LiteralPath $targetFull -Force -ErrorAction Stop
}

function Initialize-RegularEvidenceDirectory([string]$TrustedRoot, [string]$TargetPath, [string]$Label) {
    $trustedFull = [System.IO.Path]::GetFullPath($TrustedRoot).TrimEnd("\")
    $targetFull = [System.IO.Path]::GetFullPath($TargetPath).TrimEnd("\")
    $trustedPrefix = $trustedFull + [System.IO.Path]::DirectorySeparatorChar
    if ($targetFull -ne $trustedFull -and -not $targetFull.StartsWith($trustedPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Evidence directory escaped its trusted root ($Label): $targetFull"
    }

    $trustedParent = Split-Path -Parent $trustedFull
    [void](Assert-NoReparsePointAncestors $trustedParent "$Label trusted parent")
    if (-not (Test-Path -LiteralPath $trustedFull)) {
        try {
            New-Item -ItemType Directory -Path $trustedFull | Out-Null
        } catch {
            if (-not (Test-Path -LiteralPath $trustedFull -PathType Container)) {
                throw
            }
        }
    }
    [void](Assert-RegularEvidenceDirectory $trustedFull "$Label trusted root")

    $current = $trustedFull
    $relative = if ($targetFull -eq $trustedFull) { "" } else { $targetFull.Substring($trustedPrefix.Length) }
    foreach ($part in $relative.Split([char[]]@('\', '/'), [System.StringSplitOptions]::RemoveEmptyEntries)) {
        $current = Join-Path $current $part
        if (-not (Test-Path -LiteralPath $current)) {
            try {
                New-Item -ItemType Directory -Path $current | Out-Null
            } catch {
                if (-not (Test-Path -LiteralPath $current -PathType Container)) {
                    throw
                }
            }
        }
        [void](Assert-RegularEvidenceDirectory $current $Label)
    }
    return $targetFull
}

function Get-GodotAppUserDataRoots {
    $roots = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )
    if ([string]::IsNullOrWhiteSpace($env:APPDATA)) {
        throw "APPDATA is required to locate Godot evidence side-channels."
    }
    $appDataRoot = [System.IO.Path]::GetFullPath($env:APPDATA)
    if (-not (Test-Path -LiteralPath $appDataRoot -PathType Container)) {
        return @()
    }
    [void](Assert-RegularEvidenceDirectory $appDataRoot "APPDATA")
    [void](Assert-NoReparsePointAncestors $appDataRoot "APPDATA ancestors")
    $godotDirectory = Join-Path $appDataRoot "Godot"
    if (-not (Test-Path -LiteralPath $godotDirectory -PathType Container)) {
        return @()
    }
    [void](Assert-RegularEvidenceDirectory $godotDirectory "APPDATA/Godot")
    [void](Assert-NoReparsePointAncestors $godotDirectory "APPDATA/Godot ancestors")
    $appDataGodot = Join-Path $godotDirectory "app_userdata"
    if (-not (Test-Path -LiteralPath $appDataGodot)) {
        return @()
    }
    [void](Assert-RegularEvidenceDirectory $appDataGodot "APPDATA/Godot/app_userdata")
    [void](Assert-NoReparsePointAncestors $appDataGodot "APPDATA/Godot/app_userdata ancestors")
    # Godot normalizes project config/name for the userdata folder (":" -> "-").
    $candidates = @(
        "ROOM 407: THE LAST SHIFT",
        "ROOM 407- THE LAST SHIFT"
    )
    foreach ($name in $candidates) {
        $path = Join-Path $appDataGodot $name
        if (Test-Path -LiteralPath $path) {
            [void](Assert-RegularEvidenceDirectory $path "Godot project candidate")
            [void](Assert-NoReparsePointAncestors $path "Godot project candidate ancestors")
            [void]$roots.Add([System.IO.Path]::GetFullPath($path))
        }
    }
    Get-ChildItem -LiteralPath $appDataGodot -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "*ROOM 407*" } |
        ForEach-Object {
            [void](Assert-RegularEvidenceDirectory $_.FullName "Godot project candidate")
            [void](Assert-NoReparsePointAncestors $_.FullName "Godot project candidate ancestors")
            $candidatePath = [System.IO.Path]::GetFullPath($_.FullName)
            if (-not $roots.Contains($candidatePath)) {
                [void]$roots.Add($candidatePath)
            }
        }
    return @($roots)
}

function Assert-RegularEvidenceFile([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Expected regular evidence file was not found: $Path"
    }
    $item = Get-Item -LiteralPath $Path -Force
    if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Refusing reparse-point evidence file: $Path"
    }
    return $item
}

function Get-EvidenceFileIdentity([string]$Path) {
    $item = Assert-RegularEvidenceFile $Path
    return [pscustomobject][ordered]@{
        full_name = [System.IO.Path]::GetFullPath($item.FullName)
        size_bytes = [int64]$item.Length
        last_write_utc = $item.LastWriteTimeUtc.ToString("o")
        creation_time_utc = $item.CreationTimeUtc.ToString("o")
        attributes = [int]$item.Attributes
    }
}

function Test-EvidenceFileIdentityEqual([object]$Expected, [object]$Actual) {
    return $Expected.full_name -eq $Actual.full_name -and
        [int64]$Expected.size_bytes -eq [int64]$Actual.size_bytes -and
        $Expected.last_write_utc -eq $Actual.last_write_utc -and
        $Expected.creation_time_utc -eq $Actual.creation_time_utc -and
        [int]$Expected.attributes -eq [int]$Actual.attributes
}

function New-PacingEvidenceRecord([string]$SourcePath, [string]$RootPath, [object]$Identity, [string]$Sha256) {
    return [pscustomobject][ordered]@{
        root = $RootPath
        source_path = $SourcePath
        sha256 = $Sha256
        size_bytes = [int64]$Identity.size_bytes
        last_write_utc = $Identity.last_write_utc
    }
}

function New-PacingEvidenceRejection([string]$SourcePath, [string]$RootPath, [string[]]$Reasons, [object]$Identity = $null) {
    $record = [ordered]@{
        root = $RootPath
        source_path = $SourcePath
        sha256 = $null
        size_bytes = $null
        last_write_utc = $null
        rejection_reasons = @($Reasons)
    }
    if ($null -ne $Identity) {
        $record.size_bytes = [int64]$Identity.size_bytes
        $record.last_write_utc = $Identity.last_write_utc
    }
    return [pscustomobject]$record
}

function Copy-PacingEvidenceSnapshot(
    [string]$SourcePath,
    [string]$RootPath,
    [string]$DestinationPath,
    [scriptblock]$TestSnapshotHook = $null,
    [string]$DestinationTrustedRoot = ""
) {
    $preIdentity = $null
    $postIdentity = $null
    $snapshotHash = $null
    $snapshotSize = [int64]0
    $destinationCreated = $false
    $snapshotAccepted = $false
    if ([string]::IsNullOrWhiteSpace($DestinationTrustedRoot)) {
        $DestinationTrustedRoot = Split-Path -Parent ([System.IO.Path]::GetFullPath($DestinationPath))
    }
    try {
        $DestinationPath = Assert-SafeEvidenceDestinationPath $DestinationTrustedRoot $DestinationPath "Pacing evidence snapshot destination"
    } catch {
        return [pscustomobject]@{ accepted = $false; containment_unsafe = $true; record = (New-PacingEvidenceRejection $SourcePath $RootPath @("destination_root_not_regular_or_reparse", $_.Exception.Message)) }
    }
    try {
        [void](Assert-RegularEvidenceDirectory $RootPath "Godot project candidate")
    } catch {
        return [pscustomobject]@{ accepted = $false; containment_unsafe = $true; record = (New-PacingEvidenceRejection $SourcePath $RootPath @("source_root_not_regular_or_reparse")) }
    }
    try {
        $preIdentity = Get-EvidenceFileIdentity $SourcePath
    } catch {
        return [pscustomobject]@{ accepted = $false; containment_unsafe = $false; record = (New-PacingEvidenceRejection $SourcePath $RootPath @("source_not_regular_or_reparse")) }
    }
    if ([int64]$preIdentity.size_bytes -gt $maxPacingSideChannelBytes) {
        return [pscustomobject]@{ accepted = $false; containment_unsafe = $false; record = (New-PacingEvidenceRejection $SourcePath $RootPath @("source_exceeds_size_limit") $preIdentity) }
    }

    try {
        [void](Assert-NoReparsePointAncestors $SourcePath "Pacing evidence source before open")
        # Open the source before invoking the deterministic test hook. The open
        # handle is the byte snapshot; path metadata is only a supplemental
        # identity check. Delete sharing lets the regression exercise a rename
        # race while this handle remains bound to the original file.
        $sourceStream = New-Object System.IO.FileStream($SourcePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, ([System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete))
    } catch {
        return [pscustomobject]@{ accepted = $false; containment_unsafe = $false; record = (New-PacingEvidenceRejection $SourcePath $RootPath @("source_open_failed") $preIdentity) }
    }

    try {
        try {
            $openedIdentity = Get-EvidenceFileIdentity $SourcePath
        } catch {
            return [pscustomobject]@{ accepted = $false; containment_unsafe = $false; record = (New-PacingEvidenceRejection $SourcePath $RootPath @("source_not_regular_or_reparse") $preIdentity) }
        }
        if (-not (Test-EvidenceFileIdentityEqual $preIdentity $openedIdentity)) {
            return [pscustomobject]@{ accepted = $false; containment_unsafe = $false; record = (New-PacingEvidenceRejection $SourcePath $RootPath @("source_identity_changed_during_snapshot") $preIdentity) }
        }

        if ($null -ne $TestSnapshotHook) {
            & $TestSnapshotHook $SourcePath "after_pre_identity"
        }
        [void](Assert-SafeEvidenceDestinationPath $DestinationTrustedRoot $DestinationPath "Pacing evidence snapshot destination before create")
        # CreateNew prevents truncating a pre-existing leaf and avoids following
        # a leaf that appeared between validation and creation.
        $destinationStream = New-Object System.IO.FileStream($DestinationPath, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
        $destinationCreated = $true
        try {
            $hasher = [System.Security.Cryptography.SHA256]::Create()
            try {
                $buffer = New-Object byte[] 65536
                $snapshotSize = [int64]0
                while (($read = $sourceStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                    if (($snapshotSize + $read) -gt $maxPacingSideChannelBytes) {
                        return [pscustomobject]@{ accepted = $false; containment_unsafe = $false; record = (New-PacingEvidenceRejection $SourcePath $RootPath @("source_exceeds_size_limit") $preIdentity) }
                    }
                    [void]$hasher.TransformBlock($buffer, 0, $read, $buffer, 0)
                    $destinationStream.Write($buffer, 0, $read)
                    $snapshotSize += $read
                }
                [void]$hasher.TransformFinalBlock((New-Object byte[] 0), 0, 0)
                $snapshotHash = ([System.BitConverter]::ToString($hasher.Hash)).Replace("-", "").ToLowerInvariant()
            } finally {
                $hasher.Dispose()
            }
            $destinationStream.Flush($true)
        } finally {
            $destinationStream.Dispose()
        }

        try {
            $postIdentity = Get-EvidenceFileIdentity $SourcePath
        } catch {
            return [pscustomobject]@{ accepted = $false; containment_unsafe = $false; record = (New-PacingEvidenceRejection $SourcePath $RootPath @("source_not_regular_or_reparse") $preIdentity) }
        }
        $postPathHash = $null
        try {
            $postPathHash = (Get-FileHash -LiteralPath $SourcePath -Algorithm SHA256).Hash.ToLowerInvariant()
        } catch {
            return [pscustomobject]@{ accepted = $false; containment_unsafe = $false; record = (New-PacingEvidenceRejection $SourcePath $RootPath @("source_hash_verification_failed") $preIdentity) }
        }
        if (-not (Test-EvidenceFileIdentityEqual $preIdentity $postIdentity) -or
            $snapshotSize -ne [int64]$preIdentity.size_bytes -or
            $postPathHash -ne $snapshotHash) {
            return [pscustomobject]@{ accepted = $false; containment_unsafe = $false; record = (New-PacingEvidenceRejection $SourcePath $RootPath @("source_identity_changed_during_snapshot") $preIdentity) }
        }
        if ($null -ne $TestSnapshotHook) {
            & $TestSnapshotHook $SourcePath "before_destination_verification" $DestinationPath
        }
        [void](Assert-SafeEvidenceDestinationPath $DestinationTrustedRoot $DestinationPath "Pacing evidence snapshot destination verification")
        $destinationIdentity = Get-EvidenceFileIdentity $DestinationPath
        $destinationHash = (Get-FileHash -LiteralPath $DestinationPath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($destinationIdentity.size_bytes -ne $snapshotSize -or $destinationHash -ne $snapshotHash) {
            return [pscustomobject]@{ accepted = $false; containment_unsafe = $false; record = (New-PacingEvidenceRejection $SourcePath $RootPath @("snapshot_copy_verification_failed") $preIdentity) }
        }
        $snapshotAccepted = $true
        return [pscustomobject]@{ accepted = $true; containment_unsafe = $false; record = (New-PacingEvidenceRecord $SourcePath $RootPath $preIdentity $snapshotHash) }
    } catch {
        return [pscustomobject]@{ accepted = $false; containment_unsafe = $false; record = (New-PacingEvidenceRejection $SourcePath $RootPath @("snapshot_failed") $preIdentity) }
    } finally {
        $sourceStream.Dispose()
        if ($destinationCreated -and (Test-Path -LiteralPath $DestinationPath)) {
            # The caller promotes a snapshot only after all freshness checks. A rejected
            # snapshot must not remain available as a potentially misleading payload.
            # Revalidate the full destination path before cleanup; if a component was
            # swapped to a reparse point, leave it untouched rather than deleting by
            # pathname outside the trusted evidence root.
            if (-not $snapshotAccepted) {
                try {
                    [void](Assert-SafeEvidenceDestinationPath $DestinationTrustedRoot $DestinationPath "Pacing evidence rejected snapshot cleanup")
                    $destinationItem = Get-Item -LiteralPath $DestinationPath -Force -ErrorAction Stop
                    if (($destinationItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -eq 0) {
                        Remove-Item -LiteralPath $DestinationPath -Force -ErrorAction SilentlyContinue
                    }
                } catch {
                    # Preserve an unsafe/replaced path for diagnosis; never follow it
                    # during rejection cleanup.
                }
            }
        }
    }
}

function Get-PacingEvidenceRecord([string]$SourcePath, [string]$RootPath) {
    $identity = Get-EvidenceFileIdentity $SourcePath
    return New-PacingEvidenceRecord $SourcePath $RootPath $identity (Get-FileHash -LiteralPath $SourcePath -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Prepare-PacingEvidenceSideChannels(
    [string]$DestinationDirectory,
    [scriptblock]$TestClearHook = $null
) {
    $archiveDirectory = Join-Path $DestinationDirectory "prelaunch-stale-sidechannels"
    $archiveDirectory = Initialize-RegularEvidenceDirectory $DestinationDirectory $archiveDirectory "prelaunch pacing archive directory"
    $records = New-Object System.Collections.Generic.List[object]
    $rejected = New-Object System.Collections.Generic.List[object]
    $integrityPassed = $true
    $index = 0
    foreach ($root in Get-GodotAppUserDataRoots) {
        $source = Join-Path $root $pacingSideChannelRelative
        if (-not (Test-Path -LiteralPath $source)) {
            continue
        }
        $candidateIndex = $index
        $index += 1
        $destination = Join-Path $archiveDirectory ("playthrough_pacing_last-$candidateIndex.txt")
        $snapshot = Copy-PacingEvidenceSnapshot $source $root $destination $null $DestinationDirectory
        if (-not $snapshot.accepted) {
            [void]$rejected.Add($snapshot.record)
            $integrityPassed = $false
            continue
        }
        $record = $snapshot.record
        $quarantine = Join-Path $root (".room407-pacing-prelaunch-" + [guid]::NewGuid().ToString("N") + ".quarantine")
        $preservedPath = $null
        try {
            if ($null -ne $TestClearHook) {
                & $TestClearHook $source "before_quarantine"
            }
            Move-Item -LiteralPath $source -Destination $quarantine
            $quarantineIdentity = Get-EvidenceFileIdentity $quarantine
            $quarantineHash = (Get-FileHash -LiteralPath $quarantine -Algorithm SHA256).Hash.ToLowerInvariant()
            if ([int64]$quarantineIdentity.size_bytes -ne [int64]$record.size_bytes -or $quarantineHash -ne $record.sha256) {
                throw "quarantined_source_does_not_match_archive"
            }
            if (Test-Path -LiteralPath $source) {
                throw "source_reappeared_after_quarantine"
            }
        } catch {
            if (Test-Path -LiteralPath $quarantine) {
                if (-not (Test-Path -LiteralPath $source)) {
                    try {
                        Move-Item -LiteralPath $quarantine -Destination $source
                        $preservedPath = $source
                    } catch {
                        $preservedPath = $quarantine
                    }
                } else {
                    $preservedPath = $quarantine
                }
            }
            $rejection = New-PacingEvidenceRejection $source $root @(
                "prelaunch_archive_or_clear_failed",
                $_.Exception.Message
            ) $null
            $rejection | Add-Member -NotePropertyName archive_path -NotePropertyValue $destination
            $rejection | Add-Member -NotePropertyName preserved_source_path -NotePropertyValue $preservedPath
            [void]$rejected.Add($rejection)
            $integrityPassed = $false
            continue
        }
        $record | Add-Member -NotePropertyName archive_path -NotePropertyValue $destination
        # Keep the exact stale source under a unique non-runtime filename. Clearing
        # the canonical path is atomic, and no later path-based delete can remove a
        # same-size/same-timestamp replacement that appeared during preparation.
        $record | Add-Member -NotePropertyName quarantine_path -NotePropertyValue $quarantine
        [void]$records.Add($record)
    }
    return [pscustomobject][ordered]@{
        integrity_passed = $integrityPassed
        archived_count = $records.Count
        records = $records.ToArray()
        rejected = $rejected.ToArray()
    }
}

function Copy-PacingEvidenceSideChannels(
    [string]$DestinationDirectory,
    [datetime]$NotBeforeUtc,
    [string[]]$BaselineHashes,
    [scriptblock]$TestSnapshotHook = $null
) {
    [void](Assert-NoReparsePointAncestors $DestinationDirectory "Pacing harvest destination directory")
    [void](Assert-RegularEvidenceDirectory $DestinationDirectory "Pacing harvest destination directory")
    $copied = New-Object System.Collections.Generic.List[object]
    $rejected = New-Object System.Collections.Generic.List[object]
    $baselineHashSet = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )
    foreach ($hash in @($BaselineHashes)) {
        if (-not [string]::IsNullOrWhiteSpace($hash)) {
            [void]$baselineHashSet.Add($hash)
        }
    }
    # The side-channel is only supporting evidence. It must be written strictly
    # after the recorded launch instant; there is intentionally no clock tolerance.
    $freshnessThresholdUtc = $NotBeforeUtc
    $integrityPassed = $true
    $index = 0
    foreach ($root in Get-GodotAppUserDataRoots) {
        $source = Join-Path $root $pacingSideChannelRelative
        if (-not (Test-Path -LiteralPath $source)) {
            continue
        }
        $destName = if ($index -eq 0) {
            $pacingSideChannelRelative
        } else {
            "playthrough_pacing_last-$index.txt"
        }
        $destination = Join-Path $DestinationDirectory $destName
        $snapshot = Copy-PacingEvidenceSnapshot $source $root $destination $TestSnapshotHook $DestinationDirectory
        if (-not $snapshot.accepted) {
            [void]$rejected.Add($snapshot.record)
            # Snapshot/open/reparse/identity/copy anomalies mean the harvest was
            # not anomaly-free, even though rejected bytes are never consumed.
            $integrityPassed = $false
            continue
        }
        $record = $snapshot.record
        $rejectionReasons = New-Object System.Collections.Generic.List[string]
        $lastWriteUtc = [datetime]::Parse(
            [string]$record.last_write_utc,
            [System.Globalization.CultureInfo]::InvariantCulture,
            [System.Globalization.DateTimeStyles]::RoundtripKind
        ).ToUniversalTime()
        if ($lastWriteUtc -le $freshnessThresholdUtc) {
            [void]$rejectionReasons.Add("last_write_at_or_before_launch")
        }
        if ($baselineHashSet.Contains($record.sha256)) {
            [void]$rejectionReasons.Add("hash_matches_prelaunch_baseline")
        }
        if ($rejectionReasons.Count -gt 0) {
            Remove-SafeEvidenceFile $DestinationDirectory $destination "Rejected pacing evidence cleanup"
            $record | Add-Member -NotePropertyName rejection_reasons -NotePropertyValue @($rejectionReasons)
            [void]$rejected.Add($record)
            continue
        }
        $record | Add-Member -NotePropertyName evidence_path -NotePropertyValue $destination
        [void]$copied.Add($record)
        $index += 1
    }
    return [pscustomobject][ordered]@{
        integrity_passed = $integrityPassed
        freshness_not_before_utc = $NotBeforeUtc.ToString("o")
        freshness_threshold_utc = $freshnessThresholdUtc.ToString("o")
        copied_count = $copied.Count
        rejected_count = $rejected.Count
        copied = $copied.ToArray()
        rejected = $rejected.ToArray()
    }
}

function Assert-PacingJsonPropertyMultiplicity([string]$Json) {
    if ($Json.Length -gt $maxPacingSideChannelBytes) {
        throw "Pacing JSON exceeds the $maxPacingSideChannelBytes-character limit."
    }

    $expectedCounts = [System.Collections.Generic.Dictionary[string, int]]::new(
        [System.StringComparer]::Ordinal
    )
    $addExpected = {
        param([string]$Name, [int]$Count)
        if ($expectedCounts.ContainsKey($Name)) {
            $expectedCounts[$Name] += $Count
        } else {
            $expectedCounts.Add($Name, $Count)
        }
    }
    foreach ($name in @(
        "eligible_full_run", "complete", "within_target", "initial_stage",
        "active_gameplay_seconds", "wall_clock_seconds", "paused_seconds",
        "boundary_order", "boundary_order_valid", "missing_milestones",
        "stage_active_seconds", "stage_wall_seconds", "chapter_active_seconds",
        "chapter_within_target", "target_seconds"
    )) {
        & $addExpected $name 1
    }
    foreach ($name in $expectedBoundaryOrder) {
        & $addExpected $name 2
    }
    foreach ($name in $expectedChapterTargets.Keys) {
        & $addExpected $name 3
    }
    & $addExpected "total" 1

    $actualCounts = [System.Collections.Generic.Dictionary[string, int]]::new(
        [System.StringComparer]::Ordinal
    )
    for ($index = 0; $index -lt $Json.Length; $index += 1) {
        if ($Json[$index] -ne '"') {
            continue
        }
        $stringStart = $index + 1
        $hasEscape = $false
        $escaped = $false
        $closed = $false
        for ($index += 1; $index -lt $Json.Length; $index += 1) {
            $character = $Json[$index]
            if ($escaped) {
                $escaped = $false
                continue
            }
            if ($character -eq '\') {
                $hasEscape = $true
                $escaped = $true
                continue
            }
            if ($character -eq '"') {
                $closed = $true
                break
            }
        }
        if (-not $closed) {
            throw "Pacing JSON contains an unterminated string."
        }
        $next = $index + 1
        while ($next -lt $Json.Length -and [char]::IsWhiteSpace($Json[$next])) {
            $next += 1
        }
        if ($next -ge $Json.Length -or $Json[$next] -ne ':') {
            continue
        }
        if ($hasEscape) {
            throw "Pacing JSON property names must use unescaped canonical ASCII keys."
        }
        $propertyName = $Json.Substring($stringStart, $index - $stringStart)
        if (-not $expectedCounts.ContainsKey($propertyName)) {
            throw "Pacing JSON contains unexpected property '$propertyName'."
        }
        if ($actualCounts.ContainsKey($propertyName)) {
            $actualCounts[$propertyName] += 1
        } else {
            $actualCounts.Add($propertyName, 1)
        }
    }

    foreach ($expected in $expectedCounts.GetEnumerator()) {
        $actual = if ($actualCounts.ContainsKey($expected.Key)) { $actualCounts[$expected.Key] } else { 0 }
        if ($actual -ne $expected.Value) {
            throw "Pacing JSON property '$($expected.Key)' must occur exactly $($expected.Value) time(s); found $actual."
        }
    }
}

function Get-UniquePacingPayload([string[]]$LogPaths, [hashtable]$ExpectedHashesByPath = @{}) {
    $payloads = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal
    )
    $normalizedExpectedHashes = [System.Collections.Generic.Dictionary[string,string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )
    foreach ($entry in $ExpectedHashesByPath.GetEnumerator()) {
        $expectedPath = [System.IO.Path]::GetFullPath([string]$entry.Key)
        $expectedHash = [string]$entry.Value
        if ($normalizedExpectedHashes.ContainsKey($expectedPath)) {
            if ($normalizedExpectedHashes[$expectedPath] -cne $expectedHash) {
                throw "Conflicting hashes were supplied for verified pacing side-channel: $expectedPath"
            }
            continue
        }
        $normalizedExpectedHashes.Add($expectedPath, $expectedHash)
    }
    $seenVerifiedPaths = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )
    foreach ($logPath in $LogPaths) {
        $fullLogPath = [System.IO.Path]::GetFullPath($logPath)
        $isVerifiedSideChannel = $normalizedExpectedHashes.ContainsKey($fullLogPath)
        if (-not (Test-Path -LiteralPath $logPath)) {
            if ($isVerifiedSideChannel) {
                throw "Verified pacing side-channel is missing: $fullLogPath"
            }
            continue
        }
        [void](Assert-NoReparsePointAncestors $fullLogPath "Pacing source log")
        [void](Assert-RegularEvidenceFile $fullLogPath)
        $stream = New-Object System.IO.FileStream($fullLogPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
        $pathPayloadCount = 0
        try {
            if ($isVerifiedSideChannel) {
                [void]$seenVerifiedPaths.Add($fullLogPath)
                if ($stream.Length -gt $maxPacingSideChannelBytes) {
                    throw "Verified pacing side-channel exceeds the size limit: $fullLogPath"
                }
                $hasher = [System.Security.Cryptography.SHA256]::Create()
                try {
                    $actualHash = ([System.BitConverter]::ToString($hasher.ComputeHash($stream))).Replace("-", "").ToLowerInvariant()
                } finally {
                    $hasher.Dispose()
                }
                if ($actualHash -ne $normalizedExpectedHashes[$fullLogPath]) {
                    throw "Verified pacing side-channel changed before parsing: $fullLogPath"
                }
                $stream.Position = 0
            }
            $reader = New-Object System.IO.StreamReader(
                $stream,
                [System.Text.UTF8Encoding]::new($false, $true),
                $true,
                4096,
                $true
            )
            try {
                while (-not $reader.EndOfStream) {
                    $line = $reader.ReadLine()
                    $trimmedLine = $line.TrimStart()
                    if (-not $trimmedLine.StartsWith($pacingPrefix, [System.StringComparison]::Ordinal)) {
                        continue
                    }
                    $json = $trimmedLine.Substring($pacingPrefix.Length).Trim()
                    if ($json.StartsWith("{", [System.StringComparison]::Ordinal)) {
                        Assert-PacingJsonPropertyMultiplicity $json
                        $pathPayloadCount += 1
                        [void]$payloads.Add($json)
                    }
                }
            } finally {
                $reader.Dispose()
            }
        } finally {
            $stream.Dispose()
        }
        if ($isVerifiedSideChannel -and $pathPayloadCount -ne 1) {
            throw "Verified pacing side-channel must contain exactly one PLAYTHROUGH_PACING payload; found $pathPayloadCount`: $fullLogPath"
        }
    }
    foreach ($expectedPath in $normalizedExpectedHashes.Keys) {
        if (-not $seenVerifiedPaths.Contains($expectedPath)) {
            throw "Verified pacing side-channel was not supplied as a source log: $expectedPath"
        }
    }
    if ($payloads.Count -eq 0) {
        throw "No PLAYTHROUGH_PACING payload was found in the same-run logs."
    }
    if ($payloads.Count -ne 1) {
        throw "Found $($payloads.Count) distinct pacing payloads; refusing to mix runs."
    }
    return (@($payloads)[0] | ConvertFrom-Json)
}

function Get-PacingVerdict([object]$Payload) {
    $requireProperty = {
        param([object]$Object, [string]$Name, [string]$Context)
        if ($null -eq $Object) {
            throw "Pacing payload is missing object '$Context'."
        }
        $property = $Object.PSObject.Properties[$Name]
        if ($null -eq $property) {
            throw "Pacing payload is missing '$Context.$Name'."
        }
        return $property
    }
    $requireBoolean = {
        param([object]$Value, [string]$Context)
        if ($Value -isnot [bool]) {
            throw "Pacing payload field '$Context' must be a JSON boolean."
        }
        return [bool]$Value
    }
    $requireNumber = {
        param([object]$Value, [string]$Context)
        $allowedTypes = @(
            "System.Byte", "System.SByte", "System.Int16", "System.UInt16",
            "System.Int32", "System.UInt32", "System.Int64", "System.UInt64",
            "System.Single", "System.Double", "System.Decimal"
        )
        if ($null -eq $Value -or $allowedTypes -notcontains $Value.GetType().FullName) {
            throw "Pacing payload field '$Context' must be a JSON number."
        }
        $number = [double]$Value
        if ([double]::IsNaN($number) -or [double]::IsInfinity($number)) {
            throw "Pacing payload field '$Context' must be finite."
        }
        return $number
    }
    $requireArray = {
        param([object]$Value, [string]$Context)
        if ($Value -isnot [System.Array]) {
            throw "Pacing payload field '$Context' must be a JSON array."
        }
    }
    $requireExactKeys = {
        param([object]$Object, [string[]]$ExpectedNames, [string]$Context)
        if ($null -eq $Object) {
            throw "Pacing payload is missing object '$Context'."
        }
        $actualNames = @($Object.PSObject.Properties | ForEach-Object { $_.Name })
        $expectedSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
        $actualSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
        foreach ($expectedName in $ExpectedNames) { [void]$expectedSet.Add($expectedName) }
        foreach ($actualName in $actualNames) { [void]$actualSet.Add($actualName) }
        $missing = @($ExpectedNames | Where-Object { -not $actualSet.Contains($_) })
        $unexpected = @($actualNames | Where-Object { -not $expectedSet.Contains($_) })
        if ($missing.Count -gt 0 -or $unexpected.Count -gt 0) {
            throw "Pacing payload object '$Context' must contain exactly: $([string]::Join(', ', $ExpectedNames))."
        }
    }

    & $requireExactKeys $Payload @(
        "eligible_full_run", "complete", "within_target", "initial_stage",
        "active_gameplay_seconds", "wall_clock_seconds", "paused_seconds",
        "boundary_order", "boundary_order_valid", "missing_milestones",
        "stage_active_seconds", "stage_wall_seconds", "chapter_active_seconds",
        "chapter_within_target", "target_seconds"
    ) "payload"

    $eligibleFullRun = & $requireBoolean ((& $requireProperty $Payload "eligible_full_run" "payload").Value) "eligible_full_run"
    $complete = & $requireBoolean ((& $requireProperty $Payload "complete" "payload").Value) "complete"
    $boundaryOrderValid = & $requireBoolean ((& $requireProperty $Payload "boundary_order_valid" "payload").Value) "boundary_order_valid"
    $withinTargetReported = & $requireBoolean ((& $requireProperty $Payload "within_target" "payload").Value) "within_target"

    $initialStage = (& $requireProperty $Payload "initial_stage" "payload").Value
    if ($initialStage -isnot [string]) {
        throw "Pacing payload field 'initial_stage' must be a JSON string."
    }
    $boundaryOrderValue = (& $requireProperty $Payload "boundary_order" "payload").Value
    & $requireArray $boundaryOrderValue "boundary_order"
    $boundaryOrder = @($boundaryOrderValue)
    if (@($boundaryOrder | Where-Object { $_ -isnot [string] }).Count -gt 0) {
        throw "Pacing payload field 'boundary_order' must contain only strings."
    }
    $missingMilestonesValue = (& $requireProperty $Payload "missing_milestones" "payload").Value
    & $requireArray $missingMilestonesValue "missing_milestones"
    $missingMilestones = @($missingMilestonesValue)
    if (@($missingMilestones | Where-Object { $_ -isnot [string] }).Count -gt 0) {
        throw "Pacing payload field 'missing_milestones' must contain only strings."
    }

    $targetSeconds = (& $requireProperty $Payload "target_seconds" "payload").Value
    $chapterNames = @($expectedChapterTargets.Keys)
    $targetNames = @($chapterNames + "total")
    & $requireExactKeys $targetSeconds $targetNames "target_seconds"
    $chapterTargetMetadataMatches = $true
    foreach ($chapter in $chapterNames) {
        $targetValue = (& $requireProperty $targetSeconds $chapter "target_seconds").Value
        & $requireArray $targetValue "target_seconds.$chapter"
        $actualTarget = @($targetValue)
        if ($actualTarget.Count -ne 2) {
            throw "Pacing payload field 'target_seconds.$chapter' must contain exactly two numbers."
        }
        $actualMinimum = & $requireNumber $actualTarget[0] "target_seconds.$chapter[0]"
        $actualMaximum = & $requireNumber $actualTarget[1] "target_seconds.$chapter[1]"
        $expectedTarget = @($expectedChapterTargets[$chapter])
        if ($actualMinimum -ne [double]$expectedTarget[0] -or $actualMaximum -ne [double]$expectedTarget[1]) {
            $chapterTargetMetadataMatches = $false
        }
    }
    $targetTotalValue = (& $requireProperty $targetSeconds "total" "target_seconds").Value
    & $requireArray $targetTotalValue "target_seconds.total"
    $targetTotal = @($targetTotalValue)
    if ($targetTotal.Count -ne 2) {
        throw "Pacing payload field 'target_seconds.total' must contain exactly two numbers."
    }
    $targetTotalMinimum = & $requireNumber $targetTotal[0] "target_seconds.total[0]"
    $targetTotalMaximum = & $requireNumber $targetTotal[1] "target_seconds.total[1]"
    $totalTargetMetadataMatches = $targetTotalMinimum -eq 900.0 -and $targetTotalMaximum -eq 1200.0

    $stageActiveObject = (& $requireProperty $Payload "stage_active_seconds" "payload").Value
    $stageWallObject = (& $requireProperty $Payload "stage_wall_seconds" "payload").Value
    $stageNames = @($expectedBoundaryOrder)
    & $requireExactKeys $stageActiveObject $stageNames "stage_active_seconds"
    & $requireExactKeys $stageWallObject $stageNames "stage_wall_seconds"
    $stageActiveValues = @{}
    $stageWallValues = @{}
    $stageFieldsSane = $true
    $previousActive = -1.0
    $previousWall = -1.0
    foreach ($stage in $stageNames) {
        $stageActive = & $requireNumber ((& $requireProperty $stageActiveObject $stage "stage_active_seconds").Value) "stage_active_seconds.$stage"
        $stageWall = & $requireNumber ((& $requireProperty $stageWallObject $stage "stage_wall_seconds").Value) "stage_wall_seconds.$stage"
        $stageActiveValues[$stage] = $stageActive
        $stageWallValues[$stage] = $stageWall
        if ($stageActive -lt $previousActive -or $stageWall -lt $previousWall -or $stageWall -lt $stageActive) {
            $stageFieldsSane = $false
        }
        $previousActive = $stageActive
        $previousWall = $stageWall
    }

    $chapterSeconds = (& $requireProperty $Payload "chapter_active_seconds" "payload").Value
    $chapterVerdicts = (& $requireProperty $Payload "chapter_within_target" "payload").Value
    & $requireExactKeys $chapterSeconds $chapterNames "chapter_active_seconds"
    & $requireExactKeys $chapterVerdicts $chapterNames "chapter_within_target"
    $chapterDurationsInTarget = $true
    $chapterVerdictsRecomputed = $true
    $chapterDurationsConsistent = $true
    $reportedChaptersInTarget = $true
    $chapterDurationTotal = 0.0
    foreach ($chapter in $chapterNames) {
        $duration = & $requireNumber ((& $requireProperty $chapterSeconds $chapter "chapter_active_seconds").Value) "chapter_active_seconds.$chapter"
        $reportedVerdict = & $requireBoolean ((& $requireProperty $chapterVerdicts $chapter "chapter_within_target").Value) "chapter_within_target.$chapter"
        $expectedTarget = @($expectedChapterTargets[$chapter])
        $computedVerdict = $duration -ge [double]$expectedTarget[0] -and $duration -le [double]$expectedTarget[1]
        $chapterBoundaries = @($expectedChapterBoundaries[$chapter])
        $stageDuration = $stageActiveValues[$chapterBoundaries[1]] - $stageActiveValues[$chapterBoundaries[0]]
        if ([math]::Abs($stageDuration - $duration) -gt 0.02) {
            $chapterDurationsConsistent = $false
        }
        $chapterDurationTotal += $duration
        if (-not $computedVerdict) {
            $chapterDurationsInTarget = $false
        }
        if ($reportedVerdict -ne $computedVerdict) {
            $chapterVerdictsRecomputed = $false
        }
        if (-not $reportedVerdict) {
            $reportedChaptersInTarget = $false
        }
    }

    $activeGameplaySeconds = & $requireNumber ((& $requireProperty $Payload "active_gameplay_seconds" "payload").Value) "active_gameplay_seconds"
    $wallClockSeconds = & $requireNumber ((& $requireProperty $Payload "wall_clock_seconds" "payload").Value) "wall_clock_seconds"
    $pausedSeconds = & $requireNumber ((& $requireProperty $Payload "paused_seconds" "payload").Value) "paused_seconds"
    if ([math]::Abs($stageActiveValues["lobby"]) -gt 0.02 -or
        [math]::Abs($stageActiveValues["credits"] - $activeGameplaySeconds) -gt 0.02 -or
        [math]::Abs($stageWallValues["credits"] - $wallClockSeconds) -gt 0.02) {
        $stageFieldsSane = $false
    }
    $computedTotalInTarget = $activeGameplaySeconds -ge 900.0 -and $activeGameplaySeconds -le 1200.0
    $timeFieldsSane = $activeGameplaySeconds -ge 0.0 -and
        $wallClockSeconds -ge $activeGameplaySeconds -and
        $pausedSeconds -ge 0.0 -and
        $pausedSeconds -le $wallClockSeconds -and
        $activeGameplaySeconds -le (($wallClockSeconds - $pausedSeconds) + 0.02)
    $chapterDurationSumMatchesTotal = [math]::Abs($chapterDurationTotal - $activeGameplaySeconds) -le 0.06

    $checks = [ordered]@{
        eligible_full_run = $eligibleFullRun
        complete = $complete
        initial_stage_lobby = $initialStage -ceq "lobby"
        boundary_order_valid = $boundaryOrderValid
        boundary_order_exact = [string]::Join("|", $boundaryOrder) -ceq [string]::Join("|", $expectedBoundaryOrder)
        no_missing_milestones = $missingMilestones.Count -eq 0
        total_target_metadata = $totalTargetMetadataMatches
        active_time_in_target = $computedTotalInTarget
        every_chapter_in_target = $chapterDurationsInTarget -and $reportedChaptersInTarget -and $chapterVerdictsRecomputed
        within_target = $computedTotalInTarget -and ($withinTargetReported -eq $computedTotalInTarget)
        chapter_target_metadata = $chapterTargetMetadataMatches
        chapter_durations_in_target = $chapterDurationsInTarget
        chapter_verdicts_recomputed = $chapterVerdictsRecomputed
        chapter_durations_consistent = $chapterDurationsConsistent
        chapter_duration_sum_matches_total = $chapterDurationSumMatchesTotal
        time_fields_sane = $timeFieldsSane -and $stageFieldsSane
    }
    $failedChecks = @(
        $checks.GetEnumerator() |
            Where-Object { -not [bool]$_.Value } |
            ForEach-Object { $_.Key }
    )
    return [pscustomobject][ordered]@{
        passed = $failedChecks.Count -eq 0
        failed_checks = $failedChecks
        checks = [pscustomobject]$checks
        active_gameplay_seconds = $activeGameplaySeconds
        wall_clock_seconds = $wallClockSeconds
        paused_seconds = $pausedSeconds
        payload = $Payload
    }
}

function Get-UniqueLogFailures([string[]]$LogPaths) {
    $failurePattern = "ERROR:|SCRIPT ERROR|Parse Error|ObjectDB instances were leaked|Leaked instance:"
    $failures = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal
    )
    foreach ($logPath in $LogPaths) {
        if (-not (Test-Path -LiteralPath $logPath)) {
            continue
        }
        foreach ($match in Select-String -LiteralPath $logPath -Pattern $failurePattern) {
            [void]$failures.Add($match.Line.Trim())
        }
    }
    return @($failures)
}

function Test-EvidencePackageReady(
    [bool]$EnginePassed,
    [bool]$PacingPassed,
    [bool]$SideChannelIntegrityPassed,
    [bool]$RepositoryStable,
    [bool]$PhysicalInputConfirmed,
    [bool]$CaptureProvided
) {
    return $EnginePassed -and
        $PacingPassed -and
        $SideChannelIntegrityPassed -and
        $RepositoryStable -and
        $PhysicalInputConfirmed -and
        $CaptureProvided
}

function Write-SafeEvidenceTextFile(
    [string]$TrustedDirectory,
    [string]$Path,
    [string]$Text
) {
    $safePath = Assert-SafeEvidenceDestinationPath $TrustedDirectory $Path "Evidence summary output"
    $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($Text + [Environment]::NewLine)
    $stream = New-Object System.IO.FileStream($safePath, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
    try {
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush($true)
    } finally {
        $stream.Dispose()
    }
}

function Write-EvidenceFiles([string]$Directory, [object]$Summary) {
    $jsonPath = Join-Path $Directory "summary.json"
    $markdownPath = Join-Path $Directory "summary.md"
    $jsonText = $Summary | ConvertTo-Json -Depth 20
    Write-SafeEvidenceTextFile $Directory $jsonPath $jsonText

    $checkLines = @()
    if ($null -ne $Summary.pacing_verdict) {
        foreach ($check in $Summary.pacing_verdict.checks.PSObject.Properties) {
            $mark = if ([bool]$check.Value) { "x" } else { " " }
            $checkLines += "- [$mark] $($check.Name)"
        }
    }
    $markdown = @(
        "# Physical Playthrough Evidence",
        "",
        "- Run ID: ``$($Summary.run_id)``",
        "- Repository commit: ``$($Summary.repository_commit_before)``",
        "- Repository stable/clean: ``$($Summary.repository_stable)``",
        "- Godot version: ``$($Summary.godot_version)``",
        "- Version probe timeout seconds: ``$($Summary.version_probe_timeout_seconds)``",
        "- Version probe output limit bytes: ``$($Summary.version_probe_max_combined_output_bytes)``",
        "- Version probe stdout: ``$($Summary.version_probe_stdout_log)``",
        "- Version probe stderr: ``$($Summary.version_probe_stderr_log)``",
        "- Launch performed: ``$($Summary.launch_performed)``",
        "- Launch mode: ``$($Summary.launch_mode)``",
        "- Engine exit: ``$($Summary.engine_exit_code)``",
        "- Physical input confirmed: ``$($Summary.physical_input_confirmed)``",
        "- Capture reference: ``$($Summary.capture_reference)``",
        "- Log failure count: ``$($Summary.log_failure_count)``",
        "- Pacing parsed: ``$($Summary.pacing_parsed)``",
        "- Pacing pass: ``$($Summary.pacing_pass)``",
        "- Side-channel baseline archived: ``$($Summary.pacing_side_channel_baseline.Count)``",
        "- Side-channel harvested: ``$($Summary.pacing_side_channel_harvest.Count)``",
        "- Side-channel rejected: ``$($Summary.pacing_side_channel_rejected.Count)``",
        "- Side-channel integrity: ``$($Summary.pacing_side_channel_integrity_passed)``",
        "- Evidence package ready: ``$($Summary.evidence_package_ready)``",
        "- Human review still required: ``$($Summary.review_required)``",
        "- Error: ``$($Summary.error)``",
        "",
        "## Pacing Checks",
        ""
    ) + $checkLines + @(
        "",
        "## Human Review Checklist",
        "",
        "- [ ] Recording starts at the boot menu, uses START SHIFT, and reaches visible credits.",
        "- [ ] Physical keyboard/mouse input is visible or otherwise attributable to this run.",
        "- [ ] Complete traversal has no soft-lock, door/collision snag, shortcut, or test-method use.",
        "- [ ] Chase readability, capture recovery, distance, collision, and fairness are acceptable.",
        "- [ ] Darkness, flashlight, blackout, grain/flicker, guide lights, and ending are readable and comfortable.",
        "- [ ] Phone, ambience, footsteps, radio, chase, failure, ending, and bus balance are audible and appropriate.",
        "- [ ] Pause, mouse capture, Settings, comfort toggles, fullscreen, save, and relaunch behavior are acceptable.",
        "- [ ] Capture timestamps, commit, logs, and pacing payload all refer to this same run.",
        "- [ ] Reviewer name/date/notes are attached before Phase 7 or the project goal is closed."
    )
    Write-SafeEvidenceTextFile $Directory $markdownPath ([string]::Join([Environment]::NewLine, $markdown))
}

function ConvertTo-NativeProcessArgument([string]$Value) {
    if ($Value.Length -gt 0 -and $Value -notmatch '[\s"]') {
        return $Value
    }
    $escaped = [regex]::Replace($Value, '(\\*)"', '$1$1\"')
    $escaped = [regex]::Replace($escaped, '(\\+)$', '$1$1')
    return '"' + $escaped + '"'
}

function Invoke-GodotPhysicalProcess(
    [string]$Executable,
    [string[]]$Arguments,
    [string]$StandardOutputPath,
    [string]$StandardErrorPath,
    [int]$TimeoutSeconds,
    [int64]$CombinedOutputByteLimit
) {
    if ($TimeoutSeconds -le 0) {
        throw "Physical process timeout must be positive."
    }
    if ($CombinedOutputByteLimit -le 0) {
        throw "Physical process combined output limit must be positive."
    }
    $stdoutFull = [System.IO.Path]::GetFullPath($StandardOutputPath)
    $stderrFull = [System.IO.Path]::GetFullPath($StandardErrorPath)
    if ($stdoutFull -eq $stderrFull) {
        throw "Physical process stdout and stderr paths must be different."
    }
    foreach ($outputPath in @($stdoutFull, $stderrFull)) {
        $outputParent = Split-Path -Parent $outputPath
        [void](Assert-NoReparsePointAncestors $outputParent "Physical process output parent")
        [void](Assert-RegularEvidenceDirectory $outputParent "Physical process output parent")
        if (Test-Path -LiteralPath $outputPath) {
            $outputItem = Get-Item -LiteralPath $outputPath -Force
            if ($outputItem.PSIsContainer -or
                ($outputItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "Physical process output path is not a regular file: $outputPath"
            }
        }
    }

    if ($null -eq ("Room407ExportJobRun" -as [type])) {
        if (-not (Test-Path -LiteralPath $physicalJobRunnerSource -PathType Leaf)) {
            throw "Windows Job Object runner source is missing: $physicalJobRunnerSource"
        }
        Add-Type -Path $physicalJobRunnerSource
    }

    $nativeArguments = (($Arguments | ForEach-Object {
        ConvertTo-NativeProcessArgument ([string]$_)
    }) -join " ")
    $commandLine = ConvertTo-NativeProcessArgument $Executable
    if (-not [string]::IsNullOrWhiteSpace($nativeArguments)) {
        $commandLine += " " + $nativeArguments
    }

    $run = $null
    $processException = $null
    $processId = $null
    $processStartedAtUtc = $null
    $processExitCode = $null
    try {
        $run = [Room407ExportJobRun]::LaunchInteractive(
            $Executable,
            $commandLine,
            (Get-Location).ProviderPath,
            $stdoutFull,
            $stderrFull,
            $CombinedOutputByteLimit
        )
        $processId = [int]$run.ProcessId
        $processStartedAtUtc = [datetime]$run.StartedAtUtc
        if (-not $run.WaitForExit($TimeoutSeconds * 1000)) {
            try {
                $run.TerminateTreeAndWait(10000)
            } catch {
                throw "Physical Godot run timed out after $TimeoutSeconds seconds and process-tree shutdown failed: $($_.Exception.Message)"
            }
            throw "Physical Godot run timed out after $TimeoutSeconds seconds"
        }
        $processExitCode = [int]$run.GetExitCode()
        $run.EnsureNoDescendants(10000)
    } catch {
        $processException = $_.Exception
    } finally {
        if ($null -ne $run) {
            try {
                $run.EnsureNoDescendants(10000)
            } catch {
                if ($null -eq $processException) {
                    $processException = $_.Exception
                } else {
                    $processException = [System.Exception]::new(
                        "$($processException.Message); process-tree cleanup also failed: $($_.Exception.Message)",
                        $processException
                    )
                }
            }
            try {
                if (-not $run.WaitForOutputDrain(10000)) {
                    throw "Physical process output pumps did not drain before the watchdog deadline."
                }
            } catch {
                if ($null -eq $processException) {
                    $processException = $_.Exception
                } else {
                    $processException = [System.Exception]::new(
                        "$($processException.Message); output-pump cleanup also failed: $($_.Exception.Message)",
                        $processException
                    )
                }
            }
            try {
                $run.Dispose()
            } catch {
                if ($null -eq $processException) {
                    $processException = $_.Exception
                } else {
                    $processException = [System.Exception]::new(
                        "$($processException.Message); Job Object disposal also failed: $($_.Exception.Message)",
                        $processException
                    )
                }
            }
        }
    }
    if ($null -ne $processException) {
        throw $processException
    }

    $stdoutLength = ([System.IO.FileInfo]$stdoutFull).Length
    $stderrLength = ([System.IO.FileInfo]$stderrFull).Length
    if ($stdoutLength + $stderrLength -gt $CombinedOutputByteLimit) {
        throw "Physical process output exceeded the combined output limit of $CombinedOutputByteLimit bytes after drain."
    }
    $stdout = [System.IO.File]::ReadAllText($stdoutFull)
    $stderr = [System.IO.File]::ReadAllText($stderrFull)
    return [pscustomobject][ordered]@{
        process_id = $processId
        started_at_utc = $processStartedAtUtc
        exit_code = $processExitCode
        stdout = [string]$stdout
        stderr = [string]$stderr
    }
}

if (-not (Test-Path -LiteralPath (Join-Path $repositoryRoot "project.godot"))) {
    throw "project.godot was not found below $repositoryRoot"
}

$EvidenceRoot = Initialize-RegularEvidenceDirectory $artifactRoot $EvidenceRoot "physical playthrough evidence root"
$repositoryCommitBefore = [string](git -C $repositoryRoot rev-parse HEAD)
$repositoryBranchBefore = [string](git -C $repositoryRoot branch --show-current)
$repositoryDirtyBefore = @(git -C $repositoryRoot status --porcelain).Count -ne 0
$runId = (Get-Date).ToString("yyyyMMdd-HHmmss-fff")
$evidenceDirectory = Join-Path $EvidenceRoot $runId
$evidenceDirectory = Initialize-RegularEvidenceDirectory $EvidenceRoot $evidenceDirectory "physical playthrough run directory"
$startedAt = (Get-Date).ToUniversalTime()
$diskBefore = [ordered]@{ C = Get-FreeGiB "C"; D = Get-FreeGiB "D" }
$sourceLogs = @()
$verifiedSideChannelHashes = @{}
$launchPerformed = [string]::IsNullOrWhiteSpace($AnalyzeLog)
$engineExitCode = $null
$godotVersion = ""
$versionProbeTimeoutSeconds = 30
$versionProbeMaxCombinedOutputBytes = [int64]65536
$versionProbeStdoutLog = ""
$versionProbeStderrLog = ""
$consoleStdoutLog = ""
$consoleStderrLog = ""
$sideChannelPreparation = [pscustomobject][ordered]@{
    integrity_passed = $true
    archived_count = 0
    records = @()
    rejected = @()
}
$sideChannelHarvest = [pscustomobject][ordered]@{
    integrity_passed = $true
    freshness_not_before_utc = $null
    freshness_threshold_utc = $null
    copied_count = 0
    rejected_count = 0
    copied = @()
    rejected = @()
}

if ($launchPerformed) {
    if (-not (Test-Path -LiteralPath $Godot)) {
        throw "Godot executable not found: $Godot"
    }
    $versionProbeStdoutLog = Join-Path $evidenceDirectory "godot-version-stdout.log"
    $versionProbeStderrLog = Join-Path $evidenceDirectory "godot-version-stderr.log"
    Push-Location $repositoryRoot
    try {
        $versionProbe = Invoke-GodotPhysicalProcess `
            $Godot `
            @("--version") `
            $versionProbeStdoutLog `
            $versionProbeStderrLog `
            $versionProbeTimeoutSeconds `
            $versionProbeMaxCombinedOutputBytes
    } finally {
        Pop-Location
    }
    if ([int]$versionProbe.exit_code -ne 0) {
        throw "Godot version probe exited with code $([int]$versionProbe.exit_code)."
    }
    $versionProbeOutput = [string]$versionProbe.stdout
    if (-not [string]::IsNullOrWhiteSpace([string]$versionProbe.stderr)) {
        if (-not [string]::IsNullOrEmpty($versionProbeOutput) -and -not $versionProbeOutput.EndsWith([Environment]::NewLine, [StringComparison]::Ordinal)) {
            $versionProbeOutput += [Environment]::NewLine
        }
        $versionProbeOutput += [string]$versionProbe.stderr
    }
    $versionLines = @($versionProbeOutput -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($versionLines.Count -eq 0) {
        throw "Godot version probe produced no version text."
    }
    $godotVersion = [string]$versionLines[0]
    $engineLog = Join-Path $evidenceDirectory "engine.log"
    $consoleLog = Join-Path $evidenceDirectory "console.log"
    $consoleStdoutLog = Join-Path $evidenceDirectory "console-stdout.log"
    $consoleStderrLog = Join-Path $evidenceDirectory "console-stderr.log"
    $sourceLogs = @($engineLog, $consoleLog)
    $arguments = @("--path", $repositoryRoot, "--log-file", $engineLog)
    if ($LaunchMode -eq "EditorF5") {
        $arguments = @("--editor") + $arguments
        Write-Host "Godot Editor will open. Press F5, choose START SHIFT (not Continue), play to visible credits, then close the game and editor."
        Write-Warning "EditorF5 does not attach --log-file to the F5 game process. Payload harvest relies on user://playthrough_pacing_last.txt after credits. Prefer -LaunchMode ProjectRun for direct game logging."
    } else {
        Write-Host "The configured main scene will open directly. Choose START SHIFT (not Continue), play to visible credits, then quit."
    }
    Write-Host "Keep the same-run recording active. Evidence will be written to $evidenceDirectory"

    # A prior run must never be usable as evidence for this launch. Archive it
    # for audit, clear it fail-closed, then bind the later harvest to the actual
    # Godot process creation time returned by the operating system.
    $sideChannelPreparation = Prepare-PacingEvidenceSideChannels $evidenceDirectory
    $baselineHashes = @($sideChannelPreparation.records | ForEach-Object { [string]$_.sha256 })
    Push-Location $repositoryRoot
    try {
        $godotRun = Invoke-GodotPhysicalProcess `
            $Godot `
            $arguments `
            $consoleStdoutLog `
            $consoleStderrLog `
            $LaunchTimeoutSeconds `
            $MaxCombinedOutputBytes
    } finally {
        Pop-Location
    }
    $launchStartedAtUtc = [datetime]$godotRun.started_at_utc
    $engineExitCode = [int]$godotRun.exit_code
    $consoleOutput = [string]$godotRun.stdout
    if (-not [string]::IsNullOrEmpty([string]$godotRun.stderr)) {
        if (-not [string]::IsNullOrEmpty($consoleOutput) -and -not $consoleOutput.EndsWith([Environment]::NewLine, [StringComparison]::Ordinal)) {
            $consoleOutput += [Environment]::NewLine
        }
        $consoleOutput += [string]$godotRun.stderr
    }
    [System.IO.File]::WriteAllText($consoleLog, $consoleOutput, [System.Text.UTF8Encoding]::new($false))
    if (-not [string]::IsNullOrWhiteSpace($consoleOutput)) {
        Write-Host $consoleOutput.TrimEnd()
    }

    # Harvest last-run side-channel even when editor/game processes split.
    $sideChannelHarvest = Copy-PacingEvidenceSideChannels $evidenceDirectory $launchStartedAtUtc $baselineHashes
    $sideChannels = @($sideChannelHarvest.copied | ForEach-Object { [string]$_.evidence_path })
    foreach ($record in @($sideChannelHarvest.copied)) {
        $verifiedSideChannelHashes[[System.IO.Path]::GetFullPath([string]$record.evidence_path)] = [string]$record.sha256
    }
    if ($sideChannels.Count -gt 0) {
        $sourceLogs += $sideChannels
        Write-Host "HARVESTED_PACING_SIDE_CHANNEL_COUNT=$($sideChannels.Count)"
    } else {
        Write-Host "HARVESTED_PACING_SIDE_CHANNEL_COUNT=0"
    }
    Write-Host "REJECTED_PACING_SIDE_CHANNEL_COUNT=$($sideChannelHarvest.rejected_count)"
} else {
    $analyzeLogPath = $AnalyzeLog
    if (-not [System.IO.Path]::IsPathRooted($analyzeLogPath)) {
        $analyzeLogPath = Join-Path $repositoryRoot $analyzeLogPath
    }
    $requestedLog = Assert-ContainedArtifactPath $analyzeLogPath "AnalyzeLog"
    [void](Assert-NoReparsePointAncestors $requestedLog "AnalyzeLog requested path")
    $resolvedLog = (Resolve-Path -LiteralPath $requestedLog).Path
    [void](Assert-ContainedArtifactPath $resolvedLog "AnalyzeLog resolved path")
    [void](Assert-NoReparsePointAncestors $resolvedLog "AnalyzeLog")
    [void](Assert-RegularEvidenceFile $resolvedLog)
    $sourceLogs = @($resolvedLog)
}

$pacingVerdict = $null
$pacingError = ""
try {
    $payload = Get-UniquePacingPayload $sourceLogs $verifiedSideChannelHashes
    $pacingVerdict = Get-PacingVerdict $payload
} catch {
    $pacingError = $_.Exception.Message
}

$captureProvided = -not [string]::IsNullOrWhiteSpace($CaptureReference)
$logFailures = @(Get-UniqueLogFailures $sourceLogs)
$pacingPass = $null -ne $pacingVerdict -and [bool]$pacingVerdict.passed
$enginePassed = $launchPerformed -and $engineExitCode -eq 0 -and $logFailures.Count -eq 0
$pacingSideChannelIntegrityPassed = [bool]$sideChannelPreparation.integrity_passed -and [bool]$sideChannelHarvest.integrity_passed
$repositoryCommitAfter = [string](git -C $repositoryRoot rev-parse HEAD)
$repositoryBranchAfter = [string](git -C $repositoryRoot branch --show-current)
$repositoryDirtyAfter = @(git -C $repositoryRoot status --porcelain).Count -ne 0
$repositoryStable = -not $repositoryDirtyBefore -and -not $repositoryDirtyAfter -and $repositoryCommitBefore -eq $repositoryCommitAfter -and $repositoryBranchBefore -eq $repositoryBranchAfter
$evidencePackageReady = Test-EvidencePackageReady `
    $enginePassed `
    $pacingPass `
    $pacingSideChannelIntegrityPassed `
    $repositoryStable `
    ([bool]$ConfirmPhysicalInput) `
    $captureProvided
$endedAt = (Get-Date).ToUniversalTime()
$summary = [pscustomobject][ordered]@{
    run_id = $runId
    repository_commit_before = $repositoryCommitBefore.Trim()
    repository_commit_after = $repositoryCommitAfter.Trim()
    repository_branch_before = $repositoryBranchBefore.Trim()
    repository_branch_after = $repositoryBranchAfter.Trim()
    repository_dirty_before = $repositoryDirtyBefore
    repository_dirty_after = $repositoryDirtyAfter
    repository_stable = $repositoryStable
    godot_executable = $Godot
    godot_version = $godotVersion.Trim()
    version_probe_timeout_seconds = $versionProbeTimeoutSeconds
    version_probe_max_combined_output_bytes = $versionProbeMaxCombinedOutputBytes
    version_probe_stdout_log = $versionProbeStdoutLog
    version_probe_stderr_log = $versionProbeStderrLog
    started_at_utc = $startedAt.ToString("o")
    ended_at_utc = $endedAt.ToString("o")
    launch_performed = $launchPerformed
    launch_mode = if ($launchPerformed) { $LaunchMode } else { "AnalyzeLog" }
    engine_exit_code = $engineExitCode
    launch_timeout_seconds = $LaunchTimeoutSeconds
    max_combined_output_bytes = $MaxCombinedOutputBytes
    console_stdout_log = $consoleStdoutLog
    console_stderr_log = $consoleStderrLog
    physical_input_confirmed = [bool]$ConfirmPhysicalInput
    capture_reference = $CaptureReference
    capture_reference_provided = $captureProvided
    source_logs = $sourceLogs
    log_failure_count = $logFailures.Count
    log_failure_lines = $logFailures
    pacing_parsed = $null -ne $pacingVerdict
    pacing_pass = $pacingPass
    pacing_verdict = $pacingVerdict
    pacing_side_channel_baseline = @($sideChannelPreparation.records)
    pacing_side_channel_preparation_rejected = @($sideChannelPreparation.rejected)
    pacing_side_channel_harvest = @($sideChannelHarvest.copied)
    pacing_side_channel_rejected = @($sideChannelHarvest.rejected)
    pacing_side_channel_integrity_passed = $pacingSideChannelIntegrityPassed
    pacing_side_channel_freshness_not_before_utc = $sideChannelHarvest.freshness_not_before_utc
    pacing_side_channel_freshness_threshold_utc = $sideChannelHarvest.freshness_threshold_utc
    evidence_package_ready = $evidencePackageReady
    review_required = $true
    error = $pacingError
    disk_free_gib_before = [pscustomobject]$diskBefore
    disk_free_gib_after = [pscustomobject][ordered]@{ C = Get-FreeGiB "C"; D = Get-FreeGiB "D" }
}
Write-EvidenceFiles $evidenceDirectory $summary

Write-Host "PHYSICAL_PLAYTHROUGH_EVIDENCE_DIR=$evidenceDirectory"
Write-Host "PACING_PASS=$pacingPass"
Write-Host "EVIDENCE_PACKAGE_READY=$evidencePackageReady"
if (-not $evidencePackageReady) {
    Write-Warning "Evidence is incomplete or outside target. See summary.md; this run must not close the manual release gate."
    exit 2
}
exit 0
