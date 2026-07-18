function Get-PeMachine([string]$Path) {
    $stream = [System.IO.File]::OpenRead($Path)
    $reader = [System.IO.BinaryReader]::new($stream)
    try {
        if ($stream.Length -lt 64) { throw "Executable is too small to contain a PE header: $Path" }
        $stream.Position = 0x3c
        $peOffset = $reader.ReadInt32()
        if ($peOffset -lt 0 -or ($peOffset + 6) -gt $stream.Length) {
            throw "Executable contains an invalid PE header offset: $Path"
        }
        $stream.Position = $peOffset
        $signature = $reader.ReadUInt32()
        if ($signature -ne 0x00004550) {
            throw ("Expected PE signature 0x00004550, got 0x{0:x8}: {1}" -f $signature,$Path)
        }
        return $reader.ReadUInt16()
    }
    finally {
        $reader.Dispose()
        $stream.Dispose()
    }
}

function Get-TextSha256([string]$Text) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($Text)
        return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace("-","").ToLowerInvariant()
    }
    finally { $sha.Dispose() }
}

function Get-BundlePayloadRecords([string]$BundleRoot) {
    Assert-NoReparsePointPath $root $BundleRoot "Windows export bundle"
    if (-not (Test-Path -LiteralPath $BundleRoot -PathType Container)) {
        throw "Windows export bundle directory is missing: $BundleRoot"
    }
    $records = [System.Collections.Generic.List[object]]::new()
    foreach ($name in $bundlePayloadNames) {
        $path = Join-Path $BundleRoot $name
        Assert-NoReparsePointPath $root $path "Windows export bundle payload '$name'"
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Windows export bundle is missing payload '$name': $BundleRoot"
        }
        $item = Get-Item -LiteralPath $path -Force
        if ($item.Name -cne $name) {
            throw "Windows export bundle payload casing is not canonical: expected '$name', got '$($item.Name)'"
        }
        [void]$records.Add([pscustomobject]@{
            Name = $name
            Path = $path
            Size = [int64]$item.Length
            Hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
        })
    }
    return $records.ToArray()
}

function New-BundleManifestText(
    [string]$RunId,
    [string]$PresetHash,
    [string]$TemplateHash,
    [object[]]$PayloadRecords
) {
    if ($RunId -cnotmatch '^[0-9a-f]{32}$') { throw "Bundle manifest run id is not canonical" }
    foreach ($value in @($PresetHash,$TemplateHash)) {
        if ($value -cnotmatch '^[0-9a-f]{64}$') { throw "Bundle manifest dependency hash is not canonical" }
    }
    $lines = [System.Collections.Generic.List[string]]::new()
    [void]$lines.Add("ROOM407_WINDOWS_BUNDLE_V1")
    [void]$lines.Add("RUN_ID=$RunId")
    [void]$lines.Add("PRESET_SHA256=$PresetHash")
    [void]$lines.Add("TEMPLATE_SHA256=$TemplateHash")
    foreach ($record in $PayloadRecords) {
        [void]$lines.Add("FILE|$($record.Name)|$($record.Size)|$($record.Hash)")
    }
    [void]$lines.Add("WINDOWS_EXPORT_PE=x86_64")
    [void]$lines.Add("WINDOWS_EXPORTED_PROCESS_SMOKE_OK")
    [void]$lines.Add("WINDOWS_EXPORT_VERIFY_OK")
    $body = ([string]::Join("`r`n",$lines))+"`r`n"
    return $body+"BUNDLE_SHA256=$(Get-TextSha256 $body)`r`n"
}

function Get-VerifiedBundleIdentity([string]$BundleRoot) {
    Assert-NoReparsePointPath $root $BundleRoot "Windows export bundle identity"
    if (-not (Test-Path -LiteralPath $BundleRoot -PathType Container)) {
        throw "Windows export bundle directory is missing: $BundleRoot"
    }
    $items = @(Get-ChildItem -LiteralPath $BundleRoot -Force)
    $expectedNames = @($bundlePayloadNames)+@("VERIFY_COMPLETE.txt")
    if ($items.Count -ne $expectedNames.Count) {
        throw "Windows export bundle must contain exactly $($expectedNames.Count) files, got $($items.Count): $BundleRoot"
    }
    foreach ($item in $items) {
        if ($item.PSIsContainer -or -not ($expectedNames -ccontains $item.Name)) {
            throw "Windows export bundle contains an unexpected entry '$($item.Name)': $BundleRoot"
        }
        Assert-NoReparsePointPath $root $item.FullName "Windows export bundle entry '$($item.Name)'"
    }

    $records = @(Get-BundlePayloadRecords $BundleRoot)
    $exeRecord = $records | Where-Object Name -ceq "ROOM_407_THE_LAST_SHIFT.exe"
    if ((Get-PeMachine $exeRecord.Path) -ne 0x8664) {
        throw "Windows export bundle executable is not PE x86_64: $BundleRoot"
    }
    $copyrightRecord = $records | Where-Object Name -ceq "GODOT_COPYRIGHT.txt"
    if ($copyrightRecord.Hash -cne $expectedGodotCopyrightHash) {
        throw "Windows export bundle contains an unpinned Godot copyright inventory: $BundleRoot"
    }

    $manifestPath = Join-Path $BundleRoot "VERIFY_COMPLETE.txt"
    $manifestBytes = [System.IO.File]::ReadAllBytes($manifestPath)
    $manifestText = [System.Text.UTF8Encoding]::new($false,$true).GetString($manifestBytes)
    $format = $null
    $bundleId = $null
    if ($manifestText.StartsWith("ROOM407_WINDOWS_BUNDLE_V1`r`n",[System.StringComparison]::Ordinal)) {
        $lines = $manifestText.Split(@("`r`n"),[System.StringSplitOptions]::None)
        if ($lines.Count -ne 17 -or $lines[16] -cne "") {
            throw "Windows export V1 completion manifest has a non-canonical line count"
        }
        if ($lines[1] -cnotmatch '^RUN_ID=(?<value>[0-9a-f]{32})$') { throw "Windows export manifest RUN_ID is invalid" }
        $manifestRunId = $Matches['value']
        if ($lines[2] -cnotmatch '^PRESET_SHA256=(?<value>[0-9a-f]{64})$') { throw "Windows export manifest PRESET_SHA256 is invalid" }
        $manifestPresetHash = $Matches['value']
        if ($lines[3] -cnotmatch '^TEMPLATE_SHA256=(?<value>[0-9a-f]{64})$') { throw "Windows export manifest TEMPLATE_SHA256 is invalid" }
        $manifestTemplateHash = $Matches['value']
        $expectedManifest = New-BundleManifestText $manifestRunId $manifestPresetHash $manifestTemplateHash $records
        if ($manifestText -cne $expectedManifest) {
            throw "Windows export V1 completion manifest does not exactly bind the bundle payloads"
        }
        $bundleId = $lines[15].Substring("BUNDLE_SHA256=".Length)
        $format = "V1"
    }
    else {
        $legacyPattern = '\AWINDOWS_EXPORT_SHA256=(?<hash>[0-9a-f]{64})\r\nWINDOWS_EXPORT_SIZE_BYTES=(?<size>[1-9][0-9]*)\r\nWINDOWS_EXPORT_PE=x86_64\r\nWINDOWS_EXPORTED_PROCESS_SMOKE_OK\r\n\z'
        $legacyMatch = [regex]::Match($manifestText,$legacyPattern,[System.Text.RegularExpressions.RegexOptions]::CultureInvariant)
        if (-not $legacyMatch.Success) {
            throw "Windows export completion manifest is neither canonical V1 nor the pinned legacy format"
        }
        if ($legacyMatch.Groups['hash'].Value -cne $exeRecord.Hash -or [int64]$legacyMatch.Groups['size'].Value -ne $exeRecord.Size) {
            throw "Legacy Windows export completion manifest does not match its executable"
        }
        $format = "Legacy"
    }

    $identityLines = [System.Collections.Generic.List[string]]::new()
    foreach ($record in $records) {
        [void]$identityLines.Add("$($record.Name)|$($record.Size)|$($record.Hash)")
    }
    $manifestHash = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
    [void]$identityLines.Add("VERIFY_COMPLETE.txt|$($manifestBytes.Length)|$manifestHash")
    $fingerprint = Get-TextSha256 (([string]::Join("`n",$identityLines))+"`n")
    if ($null -eq $bundleId) { $bundleId = $fingerprint }
    return [pscustomobject]@{
        Root=$BundleRoot
        Format=$format
        BundleId=$bundleId
        Fingerprint=$fingerprint
        ExportHash=$exeRecord.Hash
        SizeBytes=[int64]$exeRecord.Size
    }
}

function Get-BundleState([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        return [pscustomobject]@{Exists=$false;Identity=$null;ValidationError=$null}
    }
    try {
        return [pscustomobject]@{Exists=$true;Identity=(Get-VerifiedBundleIdentity $Path);ValidationError=$null}
    }
    catch {
        return [pscustomobject]@{Exists=$true;Identity=$null;ValidationError=$_.Exception.Message}
    }
}

function Test-BundleMatchesIdentity([string]$Path,[object]$ExpectedIdentity) {
    if ($null -eq $ExpectedIdentity -or -not (Test-Path -LiteralPath $Path)) { return $false }
    try {
        $actual = Get-VerifiedBundleIdentity $Path
        return $actual.Fingerprint -ceq $ExpectedIdentity.Fingerprint
    }
    catch { return $false }
}

function Remove-TrustedDirectoryTree([string]$Path,[string]$Context) {
    if (-not (Test-Path -LiteralPath $Path)) { return }
    Assert-NoReparsePointPath $root $Path $Context
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "$Context is not a directory: $Path"
    }
    Remove-Item -LiteralPath $Path -Recurse -Force
}

function Move-TrustedDirectory([string]$Source,[string]$Destination,[string]$Context) {
    Assert-NoReparsePointPath $root $Source "$Context source"
    Assert-NoReparsePointPath $root $Destination "$Context destination"
    if (-not (Test-Path -LiteralPath $Source -PathType Container)) { throw "$Context source is missing: $Source" }
    if (Test-Path -LiteralPath $Destination) { throw "$Context destination already exists: $Destination" }
    [System.IO.Directory]::Move($Source,$Destination)
}

function Remove-StaleVerifierDirectories([string]$Parent,[string]$NamePrefix,[string]$Context) {
    if (-not (Test-Path -LiteralPath $Parent -PathType Container)) { return }
    Assert-NoReparsePointPath $root $Parent "$Context parent"
    foreach ($directory in @(Get-ChildItem -LiteralPath $Parent -Directory -Force)) {
        if ($directory.Name.StartsWith($NamePrefix,[System.StringComparison]::OrdinalIgnoreCase)) {
            Remove-TrustedDirectoryTree $directory.FullName "$Context '$($directory.Name)'"
        }
    }
}

function Recover-PreviousWindowsExport(
    [string]$OutputRoot,
    [string]$RollbackRoot,
    [string]$RecoveryQuarantine
) {
    $outputState = Get-BundleState $OutputRoot
    if ($null -ne $outputState.Identity) { return $outputState.Identity }
    $rollbackState = Get-BundleState $RollbackRoot
    if ($null -eq $rollbackState.Identity) {
        if ($outputState.Exists) {
            throw "Existing Windows export is invalid and no verified rollback exists: $($outputState.ValidationError)"
        }
        if ($rollbackState.Exists) {
            throw "Windows export output is missing and rollback is invalid: $($rollbackState.ValidationError)"
        }
        return $null
    }

    $quarantined = $false
    try {
        if ($outputState.Exists) {
            Move-TrustedDirectory $OutputRoot $RecoveryQuarantine "Windows export recovery quarantine"
            $quarantined = $true
        }
        Move-TrustedDirectory $RollbackRoot $OutputRoot "Windows export crash recovery"
        $restored = Get-VerifiedBundleIdentity $OutputRoot
        if ($restored.Fingerprint -cne $rollbackState.Identity.Fingerprint) {
            throw "Recovered Windows export does not match the verified rollback identity"
        }
        if ($quarantined) {
            Remove-TrustedDirectoryTree $RecoveryQuarantine "Windows export recovery quarantine cleanup"
        }
        Write-Host "WINDOWS_EXPORT_RECOVERED_PREVIOUS_OK"
        return $restored
    }
    catch {
        $recoveryError = $_
        try {
            if ((Test-Path -LiteralPath $OutputRoot) -and -not (Test-Path -LiteralPath $RollbackRoot)) {
                Move-TrustedDirectory $OutputRoot $RollbackRoot "Windows export recovery unwind"
            }
            if ($quarantined -and (Test-Path -LiteralPath $RecoveryQuarantine) -and -not (Test-Path -LiteralPath $OutputRoot)) {
                Move-TrustedDirectory $RecoveryQuarantine $OutputRoot "Windows export recovery quarantine restore"
            }
        }
        catch { throw "$($recoveryError.Exception.Message); recovery unwind also failed: $($_.Exception.Message)" }
        throw $recoveryError
    }
}

function Restore-PreviousWindowsExportBundle(
    [string]$OutputRoot,
    [string]$RollbackRoot,
    [string]$FailedRoot,
    [object]$ExpectedPreviousIdentity,
    [object]$ExpectedNewIdentity,
    [ref]$PublishActivated,
    [ref]$PreviousOutputMoved
) {
    foreach ($entry in @(
        @{Path=$OutputRoot;Label="rollback output"},
        @{Path=$RollbackRoot;Label="rollback previous"},
        @{Path=$FailedRoot;Label="rollback quarantine"}
    )) { Assert-NoReparsePointPath $root $entry.Path "Windows export $($entry.Label)" }

    if ($null -ne $ExpectedPreviousIdentity) {
        if (Test-BundleMatchesIdentity $OutputRoot $ExpectedPreviousIdentity) {
            $PublishActivated.Value=$false
            $PreviousOutputMoved.Value=$false
            if (Test-Path -LiteralPath $FailedRoot) {
                if (-not (Test-BundleMatchesIdentity $FailedRoot $ExpectedNewIdentity)) { throw "Rollback quarantine has an unrecognized identity" }
                Remove-TrustedDirectoryTree $FailedRoot "Windows export rollback quarantine cleanup"
            }
            return
        }
        if (-not (Test-BundleMatchesIdentity $RollbackRoot $ExpectedPreviousIdentity)) {
            throw "Verified previous Windows export is not present in the rollback slot"
        }
        if (Test-Path -LiteralPath $OutputRoot) {
            if (-not (Test-BundleMatchesIdentity $OutputRoot $ExpectedNewIdentity)) { throw "Current Windows export has an unrecognized identity during rollback" }
            if (Test-Path -LiteralPath $FailedRoot) { throw "Rollback quarantine already exists before current output was quarantined" }
            Move-TrustedDirectory $OutputRoot $FailedRoot "Windows export rollback quarantine"
        }
        elseif (Test-Path -LiteralPath $FailedRoot) {
            if (-not (Test-BundleMatchesIdentity $FailedRoot $ExpectedNewIdentity)) { throw "Rollback quarantine has an unrecognized identity" }
        }
        Move-TrustedDirectory $RollbackRoot $OutputRoot "Windows export rollback restore"
        $PublishActivated.Value=$false
        $PreviousOutputMoved.Value=$false
        if (-not (Test-BundleMatchesIdentity $OutputRoot $ExpectedPreviousIdentity)) {
            throw "Restored Windows export does not match its previous bundle identity"
        }
        if (Test-Path -LiteralPath $FailedRoot) {
            Remove-TrustedDirectoryTree $FailedRoot "Windows export rollback quarantine cleanup"
        }
        return
    }

    if (Test-Path -LiteralPath $RollbackRoot) { throw "Initial Windows export rollback unexpectedly found a previous bundle" }
    if (Test-Path -LiteralPath $OutputRoot) {
        if (-not (Test-BundleMatchesIdentity $OutputRoot $ExpectedNewIdentity)) { throw "Initial Windows export rollback found an unrecognized output identity" }
        if (Test-Path -LiteralPath $FailedRoot) { throw "Initial Windows export rollback quarantine already exists" }
        Move-TrustedDirectory $OutputRoot $FailedRoot "Initial Windows export rollback quarantine"
    }
    $PublishActivated.Value=$false
    $PreviousOutputMoved.Value=$false
    if (Test-Path -LiteralPath $FailedRoot) {
        if (-not (Test-BundleMatchesIdentity $FailedRoot $ExpectedNewIdentity)) { throw "Initial Windows export rollback quarantine has an unrecognized identity" }
        Remove-TrustedDirectoryTree $FailedRoot "Initial Windows export rollback quarantine cleanup"
    }
}
