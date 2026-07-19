[CmdletBinding()]
param(
    [string]$RunnerPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RunnerPath)) {
    $RunnerPath = Join-Path $PSScriptRoot "run-physical-playthrough.ps1"
}

function Assert-Condition([bool]$Condition, [string]$Message) {
    if (-not $Condition) {
        throw "Assertion failed: $Message"
    }
}

function Import-RunnerFunctions([string]$Path) {
    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $Path,
        [ref]$tokens,
        [ref]$parseErrors
    )
    Assert-Condition ($parseErrors.Count -eq 0) "Runner must parse before its functions are imported."

    $needed = @(
        "Assert-RegularEvidenceDirectory",
        "Get-GodotAppUserDataRoots",
        "Assert-RegularEvidenceFile",
        "Get-EvidenceFileIdentity",
        "Test-EvidenceFileIdentityEqual",
        "New-PacingEvidenceRecord",
        "New-PacingEvidenceRejection",
        "Copy-PacingEvidenceSnapshot",
        "Get-PacingEvidenceRecord",
        "Prepare-PacingEvidenceSideChannels",
        "Copy-PacingEvidenceSideChannels",
        "Test-EvidencePackageReady"
    )
    $definitions = @{}
    foreach ($definition in $ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
    }, $true)) {
        $definitions[$definition.Name] = $definition.Extent.Text
    }
    foreach ($name in $needed) {
        Assert-Condition $definitions.ContainsKey($name) "Runner is missing required side-channel function: $name"
        $functionPattern = "(?im)^\s*function\s+" + [regex]::Escape($name) + "\b"
        $scopedDefinition = [regex]::Replace($definitions[$name], $functionPattern, "function script:$name", 1)
        Invoke-Expression $scopedDefinition
    }
}

function Assert-RunnerPublicContract([string]$Path) {
    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $Path,
        [ref]$tokens,
        [ref]$parseErrors
    )
    Assert-Condition ($parseErrors.Count -eq 0) "Runner must parse before its public contract is checked."

    $expectedParameters = [ordered]@{
        Godot = '"D:\Tools\Godot-4.7.1\Godot_v4.7.1-stable_win64_console.exe"'
        LaunchMode = '"ProjectRun"'
        CaptureReference = '""'
        ConfirmPhysicalInput = $null
        AnalyzeLog = '""'
        EvidenceRoot = '""'
    }
    $actualParameters = @($ast.ParamBlock.Parameters)
    Assert-Condition ($actualParameters.Count -eq $expectedParameters.Count) "Runner parameter count must remain stable."
    $parameterIndex = 0
    foreach ($expectedName in $expectedParameters.Keys) {
        $parameter = $actualParameters[$parameterIndex]
        Assert-Condition ($parameter.Name.VariablePath.UserPath -eq $expectedName) "Runner parameter order/name changed: expected $expectedName."
        $actualDefault = if ($null -eq $parameter.DefaultValue) { $null } else { $parameter.DefaultValue.Extent.Text }
        Assert-Condition ($actualDefault -eq $expectedParameters[$expectedName]) "Runner default changed for parameter: $expectedName."
        $parameterIndex += 1
    }

    $runnerText = Get-Content -LiteralPath $Path -Raw
    $legacySummaryFields = @(
        "run_id",
        "repository_commit_before",
        "repository_commit_after",
        "repository_branch_before",
        "repository_branch_after",
        "repository_dirty_before",
        "repository_dirty_after",
        "repository_stable",
        "godot_executable",
        "godot_version",
        "started_at_utc",
        "ended_at_utc",
        "launch_performed",
        "launch_mode",
        "engine_exit_code",
        "physical_input_confirmed",
        "capture_reference",
        "capture_reference_provided",
        "source_logs",
        "log_failure_count",
        "log_failure_lines",
        "pacing_parsed",
        "pacing_pass",
        "pacing_verdict",
        "evidence_package_ready",
        "review_required",
        "error",
        "disk_free_gib_before",
        "disk_free_gib_after"
    )
    foreach ($field in $legacySummaryFields) {
        $fieldPattern = "(?m)^\s*" + [regex]::Escape($field) + "\s*="
        Assert-Condition ($runnerText -match $fieldPattern) "Runner is missing legacy summary field: $field."
    }
    foreach ($field in @(
        "pacing_side_channel_baseline",
        "pacing_side_channel_preparation_rejected",
        "pacing_side_channel_harvest",
        "pacing_side_channel_rejected",
        "pacing_side_channel_integrity_passed",
        "pacing_side_channel_freshness_not_before_utc",
        "pacing_side_channel_freshness_threshold_utc"
    )) {
        $fieldPattern = "(?m)^\s*" + [regex]::Escape($field) + "\s*="
        Assert-Condition ($runnerText -match $fieldPattern) "Runner is missing additive side-channel summary field: $field."
    }
    foreach ($marker in @(
        "PHYSICAL_PLAYTHROUGH_EVIDENCE_DIR=",
        "PACING_PASS=",
        "EVIDENCE_PACKAGE_READY="
    )) {
        Assert-Condition $runnerText.Contains($marker) "Runner is missing public marker: $marker."
    }
}

$originalAppData = $env:APPDATA
$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("room407-pacing-evidence-" + [guid]::NewGuid().ToString("N"))

try {
    $env:APPDATA = Join-Path $temporaryRoot "appdata"
    $pacingSideChannelRelative = "playthrough_pacing_last.txt"
    Assert-RunnerPublicContract $RunnerPath
    Import-RunnerFunctions $RunnerPath

    Assert-Condition (Test-EvidencePackageReady $true $true $true $true $true $true) "All readiness gates true must produce a ready package."
    Assert-Condition (-not (Test-EvidencePackageReady $true $true $false $true $true $true)) "Side-channel integrity failure must block readiness."
    Assert-Condition (-not (Test-EvidencePackageReady $false $true $true $true $true $true)) "Engine/analyze-only failure must block readiness."
    Assert-Condition (-not (Test-EvidencePackageReady $true $true $true $false $true $true)) "Repository instability must block readiness."
    Assert-Condition (-not (Test-EvidencePackageReady $true $true $true $true $false $true)) "Missing physical input confirmation must block readiness."
    Assert-Condition (-not (Test-EvidencePackageReady $true $true $true $true $true $false)) "Missing capture reference must block readiness."

    $userDataRoot = Join-Path $env:APPDATA "Godot\app_userdata\ROOM 407- THE LAST SHIFT"
    $sideChannelPath = Join-Path $userDataRoot $pacingSideChannelRelative
    $evidenceRoot = Join-Path $temporaryRoot "evidence"
    New-Item -ItemType Directory -Force -Path $userDataRoot, $evidenceRoot | Out-Null

    # A stale file is preserved for audit, then removed before the fresh launch boundary.
    [System.IO.File]::WriteAllText($sideChannelPath, "stale-payload", [System.Text.UTF8Encoding]::new($false))
    ([System.IO.FileInfo]$sideChannelPath).LastWriteTimeUtc = (Get-Date).ToUniversalTime().AddMinutes(-10)
    $prepared = Prepare-PacingEvidenceSideChannels $evidenceRoot
    Assert-Condition ($prepared.archived_count -eq 1) "Pre-launch stale side-channel must be archived."
    Assert-Condition (-not (Test-Path -LiteralPath $sideChannelPath)) "Pre-launch stale side-channel must be deleted fail-closed."
    $archived = @($prepared.records)[0]
    Assert-Condition (Test-Path -LiteralPath $archived.archive_path) "Archived stale side-channel must remain in the evidence package."
    Assert-Condition ($archived.sha256 -eq (Get-FileHash -LiteralPath $archived.archive_path -Algorithm SHA256).Hash.ToLowerInvariant()) "Archived side-channel hash must be verified."
    $baselineHashes = @($prepared.records | ForEach-Object { [string]$_.sha256 })

    # No new file means no harvest.
    $launchStartedAtUtc = (Get-Date).ToUniversalTime()
    $noNew = Copy-PacingEvidenceSideChannels $evidenceRoot $launchStartedAtUtc $baselineHashes
    Assert-Condition ($noNew.copied_count -eq 0 -and $noNew.rejected_count -eq 0) "No new side-channel must produce no harvest."

    # A post-launch rewrite with the same content is still unacceptable: it could be an old result restored by another process.
    [System.IO.File]::WriteAllText($sideChannelPath, "stale-payload", [System.Text.UTF8Encoding]::new($false))
    ([System.IO.FileInfo]$sideChannelPath).LastWriteTimeUtc = (Get-Date).ToUniversalTime()
    $sameHash = Copy-PacingEvidenceSideChannels $evidenceRoot $launchStartedAtUtc $baselineHashes
    Assert-Condition ($sameHash.copied_count -eq 0 -and $sameHash.rejected_count -eq 1) "Baseline-identical side-channel must be rejected."
    Assert-Condition (@($sameHash.rejected[0].rejection_reasons) -contains "hash_matches_prelaunch_baseline") "Same-hash rejection reason must be recorded."
    Assert-Condition $sameHash.integrity_passed "Baseline-hash exclusion must remain non-fatal."

    # A unique payload in the former two-second tolerance window is stale.
    [System.IO.File]::WriteAllText($sideChannelPath, "unique-inside-former-tolerance", [System.Text.UTF8Encoding]::new($false))
    ([System.IO.FileInfo]$sideChannelPath).LastWriteTimeUtc = $launchStartedAtUtc.AddSeconds(-1)
    $formerTolerance = Copy-PacingEvidenceSideChannels $evidenceRoot $launchStartedAtUtc $baselineHashes
    Assert-Condition ($formerTolerance.copied_count -eq 0 -and $formerTolerance.rejected_count -eq 1) "Unique payload inside the former two-second tolerance must be rejected."
    Assert-Condition (@($formerTolerance.rejected[0].rejection_reasons) -contains "last_write_at_or_before_launch") "Former-tolerance rejection reason must be recorded."
    Assert-Condition $formerTolerance.integrity_passed "Stale timestamp exclusion must remain non-fatal."

    # The boundary itself is not fresh: only writes strictly after launch are usable.
    [System.IO.File]::WriteAllText($sideChannelPath, "unique-at-launch-boundary", [System.Text.UTF8Encoding]::new($false))
    ([System.IO.FileInfo]$sideChannelPath).LastWriteTimeUtc = $launchStartedAtUtc
    $exactBoundary = Copy-PacingEvidenceSideChannels $evidenceRoot $launchStartedAtUtc $baselineHashes
    Assert-Condition ($exactBoundary.copied_count -eq 0 -and $exactBoundary.rejected_count -eq 1) "Payload timestamped exactly at launch must be rejected."
    Assert-Condition (@($exactBoundary.rejected[0].rejection_reasons) -contains "last_write_at_or_before_launch") "Exact-boundary rejection reason must be recorded."
    Assert-Condition $exactBoundary.integrity_passed "Exact-boundary exclusion must remain non-fatal."

    # Only a fresh payload with a changed hash is copied, and that copy is byte-for-byte verified.
    # Pin launch time first, then force a strictly later write timestamp so this case is
    # deterministic even when wall-clock resolution collapses both Get-Date calls.
    $freshLaunchStartedAtUtc = (Get-Date).ToUniversalTime()
    [System.IO.File]::WriteAllText($sideChannelPath, "fresh-changed-payload", [System.Text.UTF8Encoding]::new($false))
    ([System.IO.FileInfo]$sideChannelPath).LastWriteTimeUtc = $freshLaunchStartedAtUtc.AddSeconds(1)
    $fresh = Copy-PacingEvidenceSideChannels $evidenceRoot $freshLaunchStartedAtUtc $baselineHashes
    Assert-Condition ($fresh.copied_count -eq 1 -and $fresh.rejected_count -eq 0) "Fresh changed side-channel must be harvested."
    $freshCopy = @($fresh.copied)[0]
    Assert-Condition (Test-Path -LiteralPath $freshCopy.evidence_path) "Fresh side-channel copy must exist."
    Assert-Condition ($freshCopy.sha256 -eq (Get-FileHash -LiteralPath $freshCopy.evidence_path -Algorithm SHA256).Hash.ToLowerInvariant()) "Fresh side-channel copy hash must match its source."
    Assert-Condition ($freshCopy.size_bytes -eq ([System.IO.FileInfo]$freshCopy.evidence_path).Length) "Fresh side-channel copy size must match the accepted snapshot."

    # A hook can corrupt the finished destination just before its verification.
    # The rejected snapshot must be removed, rather than lingering as a payload.
    [System.IO.File]::WriteAllText($sideChannelPath, "snapshot-destination-verification-source", [System.Text.UTF8Encoding]::new($false))
    $rejectedSnapshotPath = Join-Path $evidenceRoot "rejected-snapshot.txt"
    $destinationVerificationHook = {
        param($Path, $Phase, $DestinationPath)
        if ($Phase -eq "before_destination_verification") {
            [System.IO.File]::WriteAllText($DestinationPath, "corrupted-after-copy", [System.Text.UTF8Encoding]::new($false))
        }
    }
    $rejectedSnapshot = Copy-PacingEvidenceSnapshot $sideChannelPath $userDataRoot $rejectedSnapshotPath $destinationVerificationHook
    Assert-Condition (-not $rejectedSnapshot.accepted) "Destination verification corruption must reject the snapshot."
    Assert-Condition (@($rejectedSnapshot.record.rejection_reasons) -contains "snapshot_copy_verification_failed") "Destination verification rejection reason must be recorded."
    Assert-Condition (-not (Test-Path -LiteralPath $rejectedSnapshotPath)) "Rejected snapshot destination must be removed."

    # The same destination-verification anomaly must make the aggregate harvest
    # fail integrity and leave no accepted side-channel payload.
    $integrityEvidenceRoot = Join-Path $temporaryRoot "integrity-evidence"
    New-Item -ItemType Directory -Force -Path $integrityEvidenceRoot | Out-Null
    $integrityLaunchStartedAtUtc = (Get-Date).ToUniversalTime().AddSeconds(-1)
    [System.IO.File]::WriteAllText($sideChannelPath, "harvest-destination-verification-source", [System.Text.UTF8Encoding]::new($false))
    ([System.IO.FileInfo]$sideChannelPath).LastWriteTimeUtc = (Get-Date).ToUniversalTime()
    $destinationVerificationHarvest = Copy-PacingEvidenceSideChannels $integrityEvidenceRoot $integrityLaunchStartedAtUtc $baselineHashes $destinationVerificationHook
    $integrityDestination = Join-Path $integrityEvidenceRoot $pacingSideChannelRelative
    Assert-Condition (-not $destinationVerificationHarvest.integrity_passed) "Destination verification anomaly must fail harvest integrity."
    Assert-Condition ($destinationVerificationHarvest.copied_count -eq 0 -and $destinationVerificationHarvest.rejected_count -eq 1) "Destination verification anomaly must leave no accepted harvest record."
    Assert-Condition (-not (Test-Path -LiteralPath $integrityDestination)) "Destination verification anomaly must leave no destination payload."

    # The hook executes after the pre-snapshot identity check and before the only
    # source stream opens. It makes an in-harvest path swap deterministic without
    # sleeping or launching Godot; the changed identity must never be accepted.
    $swapLaunchStartedAtUtc = (Get-Date).ToUniversalTime().AddSeconds(-1)
    [System.IO.File]::WriteAllText($sideChannelPath, "snapshot-before-swap", [System.Text.UTF8Encoding]::new($false))
    ([System.IO.FileInfo]$sideChannelPath).LastWriteTimeUtc = (Get-Date).ToUniversalTime()
    $replacementPath = Join-Path $temporaryRoot "snapshot-replacement.txt"
    $displacedPath = Join-Path $temporaryRoot "snapshot-displaced.txt"
    [System.IO.File]::WriteAllText($replacementPath, "snapshot-after-deterministic-swap-with-different-length", [System.Text.UTF8Encoding]::new($false))
    ([System.IO.FileInfo]$replacementPath).LastWriteTimeUtc = (Get-Date).ToUniversalTime()
    $swapHook = {
        param($Path, $Phase)
        if ($Phase -eq "after_pre_identity") {
            Move-Item -LiteralPath $Path -Destination $displacedPath -Force
            Move-Item -LiteralPath $replacementPath -Destination $Path -Force
        }
    }
    $swapEvidenceRoot = Join-Path $temporaryRoot "swap-evidence"
    New-Item -ItemType Directory -Force -Path $swapEvidenceRoot | Out-Null
    $swapped = Copy-PacingEvidenceSideChannels $swapEvidenceRoot $swapLaunchStartedAtUtc $baselineHashes $swapHook
    Assert-Condition ($swapped.copied_count -eq 0 -and $swapped.rejected_count -eq 1) "A source swapped during the snapshot must be rejected."
    Assert-Condition (@($swapped.rejected[0].rejection_reasons) -contains "source_identity_changed_during_snapshot") "Source-swap rejection reason must be recorded."
    Assert-Condition (-not $swapped.integrity_passed) "Source-swap anomaly must fail harvest integrity."
    Assert-Condition (-not (Test-Path -LiteralPath (Join-Path $swapEvidenceRoot $pacingSideChannelRelative))) "Source-swap anomaly must leave no destination payload."

    # Junctions are reparse points. If the platform can create them, discovery
    # must stop before a side-channel could be followed outside APPDATA.
    $appDataPath = $env:APPDATA
    $junctionTarget = Join-Path $temporaryRoot "junction-target"
    $appDataJunction = Join-Path $temporaryRoot "appdata-junction"
    $junctionSupported = $false
    try {
        New-Item -ItemType Directory -Force -Path $junctionTarget | Out-Null
        New-Item -ItemType Junction -Path $appDataJunction -Target $junctionTarget | Out-Null
        $junctionSupported = ((Get-Item -LiteralPath $appDataJunction -Force).Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0
    } catch {
        Write-Host "PHYSICAL_EVIDENCE_REPARSE_REGRESSION_SKIPPED=$($_.Exception.GetType().Name)"
    }
    if ($junctionSupported) {
        try {
            $env:APPDATA = $appDataJunction
            $reparseError = $null
            try {
                $null = @(Get-GodotAppUserDataRoots)
            } catch {
                $reparseError = $_
            }
            Assert-Condition ($null -ne $reparseError -and $reparseError.Exception.Message -like "*Refusing reparse-point evidence directory (APPDATA)*") "APPDATA junction must be rejected fail-closed."
        } finally {
            $env:APPDATA = $appDataPath
        }

        $candidateTarget = Join-Path $temporaryRoot "candidate-junction-target"
        $candidateJunction = Join-Path (Split-Path -Parent $userDataRoot) "ROOM 407 candidate-junction"
        New-Item -ItemType Directory -Force -Path $candidateTarget | Out-Null
        New-Item -ItemType Junction -Path $candidateJunction -Target $candidateTarget | Out-Null
        $candidateError = $null
        try {
            $null = @(Get-GodotAppUserDataRoots)
        } catch {
            $candidateError = $_
        }
        $candidateErrorMessage = if ($null -eq $candidateError) { "<none>" } else { $candidateError.Exception.Message }
        Assert-Condition ($null -ne $candidateError -and $candidateErrorMessage -like "*Refusing reparse-point evidence directory (Godot project candidate)*") "Project candidate junction must be rejected fail-closed (error=$candidateErrorMessage)."
        Write-Host "PHYSICAL_EVIDENCE_REPARSE_REGRESSION_OK"
    }

    Write-Host "PHYSICAL_EVIDENCE_SIDECHANNEL_REGRESSION_OK"
} finally {
    $env:APPDATA = $originalAppData
    if (Test-Path -LiteralPath $temporaryRoot) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
    }
}
