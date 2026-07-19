[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RunnerPath = Join-Path $PSScriptRoot "run-physical-playthrough.ps1"
$runnerItem = Get-Item -LiteralPath $RunnerPath -Force -ErrorAction Stop
if (($runnerItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
    throw "Refusing to import runner functions from a reparse point: $RunnerPath"
}

function Assert-Condition([bool]$Condition, [string]$Message) {
    if (-not $Condition) {
        throw "Assertion failed: $Message"
    }
}

function Copy-JsonObject([object]$Value) {
    return $Value | ConvertTo-Json -Depth 20 | ConvertFrom-Json
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
        "Assert-ContainedArtifactPath",
        "Assert-NoReparsePointAncestors",
        "Assert-SafeEvidenceDestinationPath",
        "Remove-SafeEvidenceFile",
        "Initialize-RegularEvidenceDirectory",
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
        "Assert-PacingJsonPropertyMultiplicity",
        "Get-UniquePacingPayload",
        "Get-PacingVerdict",
        "Test-EvidencePackageReady",
        "ConvertTo-NativeProcessArgument",
        "Invoke-GodotPhysicalProcess"
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

    # Runner snapshot helpers read these script-scope constants. Mirror them here
    # so imported functions remain StrictMode-safe outside the runner script file.
    $script:maxPacingSideChannelBytes = [int64](1MB)
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
        LaunchTimeoutSeconds = '7200'
        MaxCombinedOutputBytes = '16777216'
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
        "pacing_side_channel_freshness_threshold_utc",
        "launch_timeout_seconds",
        "max_combined_output_bytes",
        "version_probe_timeout_seconds",
        "version_probe_max_combined_output_bytes",
        "version_probe_stdout_log",
        "version_probe_stderr_log",
        "console_stdout_log",
        "console_stderr_log"
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
    Assert-Condition $runnerText.Contains('[Room407ExportJobRun]::LaunchInteractive') "Physical launch must use the bounded interactive Job Object API."
    Assert-Condition $runnerText.Contains('$versionProbe = Invoke-GodotPhysicalProcess') "Godot --version must use the bounded physical-process helper."
    Assert-Condition ($runnerText -notmatch '(?m)&\s*\$Godot(?:\s|$)') "The main runner must not invoke a user-supplied Godot executable outside the bounded Job helper."
    Assert-Condition $runnerText.Contains('$processStartedAtUtc = [datetime]$run.StartedAtUtc') "Launch freshness must bind to the OS process creation time exposed by the Job runner."
    Assert-Condition ($runnerText -notmatch 'ReadToEndAsync|\.WaitForExit\(\)') "Physical launch must not use unbounded in-memory reads or an infinite wait."
    Assert-Condition ($runnerText -notmatch '\$launchStartedAtUtc\s*=\s*\(Get-Date') "Launch freshness must not use a timestamp captured before process start."
}

$originalAppData = $env:APPDATA
$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("room407-pacing-evidence-" + [guid]::NewGuid().ToString("N"))

try {
    New-Item -ItemType Directory -Path $temporaryRoot | Out-Null
    $env:APPDATA = Join-Path $temporaryRoot "appdata"
    $pacingPrefix = "PLAYTHROUGH_PACING: "
    $pacingSideChannelRelative = "playthrough_pacing_last.txt"
    $expectedBoundaryOrder = @(
        "lobby", "floor4_dark", "floor4_powered", "memory_loop",
        "room_407", "chase", "ending", "credits"
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
    $physicalJobRunnerSource = Join-Path $PSScriptRoot "windows-export-job-runner.cs"
    $artifactRoot = [System.IO.Path]::GetFullPath((Join-Path $temporaryRoot "artifact-root")).TrimEnd("\")
    $artifactPrefix = $artifactRoot + [System.IO.Path]::DirectorySeparatorChar
    Assert-RunnerPublicContract $RunnerPath
    Import-RunnerFunctions $RunnerPath

    Assert-Condition (Test-EvidencePackageReady $true $true $true $true $true $true) "All readiness gates true must produce a ready package."
    Assert-Condition (-not (Test-EvidencePackageReady $true $true $false $true $true $true)) "Side-channel integrity failure must block readiness."
    Assert-Condition (-not (Test-EvidencePackageReady $false $true $true $true $true $true)) "Engine/analyze-only failure must block readiness."
    Assert-Condition (-not (Test-EvidencePackageReady $true $true $true $false $true $true)) "Repository instability must block readiness."
    Assert-Condition (-not (Test-EvidencePackageReady $true $true $true $true $false $true)) "Missing physical input confirmation must block readiness."
    Assert-Condition (-not (Test-EvidencePackageReady $true $true $true $true $true $false)) "Missing capture reference must block readiness."

    $processProbeRoot = Join-Path $temporaryRoot "process-probes"
    New-Item -ItemType Directory -Path $processProbeRoot | Out-Null
    $processBoundaryStdout = Join-Path $processProbeRoot "boundary.stdout.log"
    $processBoundaryStderr = Join-Path $processProbeRoot "boundary.stderr.log"
    $processBoundaryBefore = (Get-Date).ToUniversalTime()
    $processBoundaryProbe = Invoke-GodotPhysicalProcess `
        (Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe") `
        @("-NoProfile", "-NonInteractive", "-Command", "Write-Output PROCESS_BOUNDARY_OK") `
        $processBoundaryStdout `
        $processBoundaryStderr `
        10 `
        65536
    $processBoundaryAfter = (Get-Date).ToUniversalTime()
    Assert-Condition ($processBoundaryProbe.exit_code -eq 0 -and $processBoundaryProbe.stdout.Contains("PROCESS_BOUNDARY_OK")) "Process-bound launch helper must execute and capture output."
    Assert-Condition ($processBoundaryProbe.started_at_utc -ge $processBoundaryBefore.AddSeconds(-1) -and $processBoundaryProbe.started_at_utc -le $processBoundaryAfter.AddSeconds(1)) "Launch boundary must be the child process creation time."

    $argumentProbeScript = Join-Path $processProbeRoot "argument-probe.ps1"
    [System.IO.File]::WriteAllText(
        $argumentProbeScript,
        'param([string]$Value) [Console]::Out.WriteLine([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Value)))',
        [System.Text.UTF8Encoding]::new($false)
    )
    $argumentProbeValue = 'value with spaces "quoted" and trailing\\'
    $argumentProbeExpected = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($argumentProbeValue))
    $argumentProbe = Invoke-GodotPhysicalProcess `
        (Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe") `
        @("-NoProfile", "-NonInteractive", "-File", $argumentProbeScript, "-Value", $argumentProbeValue) `
        (Join-Path $processProbeRoot "argument.stdout.log") `
        (Join-Path $processProbeRoot "argument.stderr.log") `
        10 `
        65536
    Assert-Condition ($argumentProbe.exit_code -eq 0 -and $argumentProbe.stdout.Trim() -ceq $argumentProbeExpected) "Native argument quoting must preserve spaces, quotes, and trailing backslashes."

    $timeoutChildScript = Join-Path $processProbeRoot "timeout-child.ps1"
    $timeoutParentScript = Join-Path $processProbeRoot "timeout-parent.ps1"
    $timeoutSurvivalMarker = Join-Path $processProbeRoot "timeout-child-survived.txt"
    [System.IO.File]::WriteAllText(
        $timeoutChildScript,
        'param([string]$Marker) Start-Sleep -Seconds 4; [IO.File]::WriteAllText($Marker, "survived")',
        [System.Text.UTF8Encoding]::new($false)
    )
    $timeoutParentSource = @'
param([string]$ChildScript, [string]$Marker)
$powershell = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
Start-Process -FilePath $powershell -ArgumentList @(
    "-NoProfile", "-NonInteractive", "-File", $ChildScript, "-Marker", $Marker
) -WindowStyle Hidden
Start-Sleep -Seconds 30
'@
    [System.IO.File]::WriteAllText($timeoutParentScript, $timeoutParentSource, [System.Text.UTF8Encoding]::new($false))
    $timeoutError = $null
    try {
        $null = Invoke-GodotPhysicalProcess `
            (Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe") `
            @("-NoProfile", "-NonInteractive", "-File", $timeoutParentScript, "-ChildScript", $timeoutChildScript, "-Marker", $timeoutSurvivalMarker) `
            (Join-Path $processProbeRoot "timeout.stdout.log") `
            (Join-Path $processProbeRoot "timeout.stderr.log") `
            1 `
            65536
    } catch {
        $timeoutError = $_
    }
    Assert-Condition ($null -ne $timeoutError -and $timeoutError.Exception.Message -like "*timed out after 1 seconds*") "Physical process timeout must fail with its exact watchdog marker."
    Start-Sleep -Seconds 5
    Assert-Condition (-not (Test-Path -LiteralPath $timeoutSurvivalMarker)) "Physical timeout must terminate the whole descendant tree."

    $overflowScript = Join-Path $processProbeRoot "overflow.ps1"
    [System.IO.File]::WriteAllText(
        $overflowScript,
        '[Console]::Out.Write("O" * 131072); [Console]::Error.Write("E" * 131072); Start-Sleep -Seconds 30',
        [System.Text.UTF8Encoding]::new($false)
    )
    $overflowStdout = Join-Path $processProbeRoot "overflow.stdout.log"
    $overflowStderr = Join-Path $processProbeRoot "overflow.stderr.log"
    $overflowError = $null
    try {
        $null = Invoke-GodotPhysicalProcess `
            (Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe") `
            @("-NoProfile", "-NonInteractive", "-File", $overflowScript) `
            $overflowStdout `
            $overflowStderr `
            10 `
            4096
    } catch {
        $overflowError = $_
    }
    Assert-Condition ($null -ne $overflowError -and $overflowError.Exception.Message -like "*combined output limit of 4096 bytes*") "Physical process output overflow must fail with its exact byte-limit marker."
    $overflowBytes = ([System.IO.FileInfo]$overflowStdout).Length + ([System.IO.FileInfo]$overflowStderr).Length
    Assert-Condition ($overflowBytes -le 4096) "Bounded output pumps must never retain more than the combined byte limit."
    Write-Host "PHYSICAL_EVIDENCE_PROCESS_BOUNDARY_REGRESSION_OK"

    $containedRoot = Join-Path $temporaryRoot "artifact-root"
    $containedEvidence = Join-Path $containedRoot "manual\nested"
    $initializedEvidence = Initialize-RegularEvidenceDirectory $containedRoot $containedEvidence "regression evidence root"
    Assert-Condition ($initializedEvidence -eq [System.IO.Path]::GetFullPath($containedEvidence)) "Contained evidence directories must initialize below their trusted root."
    $escapeError = $null
    try {
        $null = Initialize-RegularEvidenceDirectory $containedRoot (Join-Path $containedRoot "..\escaped") "regression escape"
    } catch {
        $escapeError = $_
    }
    Assert-Condition ($null -ne $escapeError -and $escapeError.Exception.Message -like "*escaped its trusted root*") "EvidenceRoot traversal must be rejected before directories are created."
    $outsideAnalyzeError = $null
    try {
        $null = Assert-ContainedArtifactPath (Join-Path $temporaryRoot "outside.log") "AnalyzeLog regression"
    } catch {
        $outsideAnalyzeError = $_
    }
    Assert-Condition ($null -ne $outsideAnalyzeError -and $outsideAnalyzeError.Exception.Message -like "*below the repository .artifacts directory*") "AnalyzeLog paths outside .artifacts must be rejected."

    $validPacingPayload = [pscustomobject][ordered]@{
        eligible_full_run = $true
        complete = $true
        within_target = $true
        initial_stage = "lobby"
        active_gameplay_seconds = 990.0
        wall_clock_seconds = 1020.0
        paused_seconds = 30.0
        boundary_order = @($expectedBoundaryOrder)
        boundary_order_valid = $true
        missing_milestones = @()
        stage_active_seconds = [pscustomobject][ordered]@{
            lobby = 0.0
            floor4_dark = 150.0
            floor4_powered = 200.0
            memory_loop = 360.0
            room_407 = 630.0
            chase = 840.0
            ending = 980.0
            credits = 990.0
        }
        stage_wall_seconds = [pscustomobject][ordered]@{
            lobby = 0.0
            floor4_dark = 155.0
            floor4_powered = 205.0
            memory_loop = 365.0
            room_407 = 635.0
            chase = 845.0
            ending = 995.0
            credits = 1020.0
        }
        chapter_active_seconds = [pscustomobject][ordered]@{
            opening = 150.0
            floor4 = 210.0
            memory_loop = 270.0
            room407 = 210.0
            chase_ending = 150.0
        }
        chapter_within_target = [pscustomobject][ordered]@{
            opening = $true
            floor4 = $true
            memory_loop = $true
            room407 = $true
            chase_ending = $true
        }
        target_seconds = [pscustomobject][ordered]@{
            opening = @(120.0, 180.0)
            floor4 = @(180.0, 240.0)
            memory_loop = @(240.0, 300.0)
            room407 = @(180.0, 240.0)
            chase_ending = @(120.0, 180.0)
            total = @(900.0, 1200.0)
        }
    }
    $validVerdict = Get-PacingVerdict (Copy-JsonObject $validPacingPayload)
    Assert-Condition $validVerdict.passed "A structurally valid in-target pacing payload must pass."

    $uppercaseInitialStagePayload = Copy-JsonObject $validPacingPayload
    $uppercaseInitialStagePayload.initial_stage = "LOBBY"
    $uppercaseInitialStageVerdict = Get-PacingVerdict $uppercaseInitialStagePayload
    Assert-Condition (-not $uppercaseInitialStageVerdict.passed -and @($uppercaseInitialStageVerdict.failed_checks) -contains "initial_stage_lobby") "Initial stage matching must be case-sensitive."

    $validPacingJson = $validPacingPayload | ConvertTo-Json -Depth 20 -Compress
    Assert-PacingJsonPropertyMultiplicity $validPacingJson
    $duplicateKeyJson = '{"eligible_full_run":true,' + $validPacingJson.Substring(1)
    $duplicateKeyError = $null
    try {
        Assert-PacingJsonPropertyMultiplicity $duplicateKeyJson
    } catch {
        $duplicateKeyError = $_
    }
    Assert-Condition ($null -ne $duplicateKeyError -and $duplicateKeyError.Exception.Message -like "*eligible_full_run*must occur exactly*") "Duplicate JSON keys must be rejected before ConvertFrom-Json can collapse them."

    $stringBooleanPayload = Copy-JsonObject $validPacingPayload
    $stringBooleanPayload.eligible_full_run = "false"
    $stringBooleanError = $null
    try {
        $null = Get-PacingVerdict $stringBooleanPayload
    } catch {
        $stringBooleanError = $_
    }
    Assert-Condition ($null -ne $stringBooleanError -and $stringBooleanError.Exception.Message -like "*must be a JSON boolean*") "String booleans must be rejected instead of coercing to true."

    $missingTargetPayload = Copy-JsonObject $validPacingPayload
    $missingTargetPayload.target_seconds.PSObject.Properties.Remove("room407")
    $missingTargetError = $null
    try {
        $null = Get-PacingVerdict $missingTargetPayload
    } catch {
        $missingTargetError = $_
    }
    Assert-Condition ($null -ne $missingTargetError -and $missingTargetError.Exception.Message -like "*must contain exactly*") "Missing chapter target metadata must be rejected."

    $emptyVerdictPayload = Copy-JsonObject $validPacingPayload
    $emptyVerdictPayload.chapter_within_target = [pscustomobject]@{}
    $emptyVerdictError = $null
    try {
        $null = Get-PacingVerdict $emptyVerdictPayload
    } catch {
        $emptyVerdictError = $_
    }
    $emptyVerdictErrorMessage = if ($null -eq $emptyVerdictError) { "<none>" } else { $emptyVerdictError.Exception.Message }
    Assert-Condition ($null -ne $emptyVerdictError -and $emptyVerdictErrorMessage -like "*chapter_within_target*") "Empty chapter verdict metadata must be rejected (error=$emptyVerdictErrorMessage)."

    $wrongTargetPayload = Copy-JsonObject $validPacingPayload
    $wrongTargetPayload.target_seconds.room407 = @(0.0, 9999.0)
    $wrongTargetVerdict = Get-PacingVerdict $wrongTargetPayload
    Assert-Condition (-not $wrongTargetVerdict.passed -and @($wrongTargetVerdict.failed_checks) -contains "chapter_target_metadata") "Changed chapter target ranges must fail the verdict."

    $falseChapterPayload = Copy-JsonObject $validPacingPayload
    $falseChapterPayload.chapter_active_seconds.room407 = 10.0
    $falseChapterVerdict = Get-PacingVerdict $falseChapterPayload
    Assert-Condition (-not $falseChapterVerdict.passed -and @($falseChapterVerdict.failed_checks) -contains "chapter_verdicts_recomputed") "Reported chapter booleans must be recomputed from chapter durations."
    Write-Host "PHYSICAL_EVIDENCE_PACING_SCHEMA_REGRESSION_OK"

    $userDataRoot = Join-Path $env:APPDATA "Godot\app_userdata\ROOM 407- THE LAST SHIFT"
    $sideChannelPath = Join-Path $userDataRoot $pacingSideChannelRelative
    $evidenceRoot = Join-Path $temporaryRoot "evidence"
    New-Item -ItemType Directory -Force -Path $userDataRoot, $evidenceRoot | Out-Null

    # A stale file is preserved for audit, then removed before the fresh launch boundary.
    [System.IO.File]::WriteAllText($sideChannelPath, "stale-payload", [System.Text.UTF8Encoding]::new($false))
    ([System.IO.FileInfo]$sideChannelPath).LastWriteTimeUtc = (Get-Date).ToUniversalTime().AddMinutes(-10)
    $prepared = Prepare-PacingEvidenceSideChannels $evidenceRoot
    $preparedDiagnostic = $prepared | ConvertTo-Json -Depth 8 -Compress
    Assert-Condition ($prepared.archived_count -eq 1) "Pre-launch stale side-channel must be archived (result=$preparedDiagnostic)."
    Assert-Condition (-not (Test-Path -LiteralPath $sideChannelPath)) "Pre-launch stale side-channel must be deleted fail-closed."
    $archived = @($prepared.records)[0]
    Assert-Condition (Test-Path -LiteralPath $archived.archive_path) "Archived stale side-channel must remain in the evidence package."
    Assert-Condition ($archived.sha256 -eq (Get-FileHash -LiteralPath $archived.archive_path -Algorithm SHA256).Hash.ToLowerInvariant()) "Archived side-channel hash must be verified."
    Assert-Condition (Test-Path -LiteralPath $archived.quarantine_path) "The exact stale source must remain under a non-runtime quarantine name."
    Assert-Condition ($archived.sha256 -eq (Get-FileHash -LiteralPath $archived.quarantine_path -Algorithm SHA256).Hash.ToLowerInvariant()) "Quarantined stale source must match the archived snapshot."
    $baselineHashes = @($prepared.records | ForEach-Object { [string]$_.sha256 })

    # Replacing the canonical path with same-size, same-timestamp bytes after the
    # snapshot must never let preparation delete those replacement bytes.
    $clearRaceEvidenceRoot = Join-Path $temporaryRoot "clear-race-evidence"
    New-Item -ItemType Directory -Force -Path $clearRaceEvidenceRoot | Out-Null
    $clearOriginal = "original-payload"
    $clearReplacement = "swapped!-payload"
    Assert-Condition ($clearOriginal.Length -eq $clearReplacement.Length) "Clear-race fixture strings must have equal length."
    $clearTimestamp = (Get-Date).ToUniversalTime().AddMinutes(-5)
    [System.IO.File]::WriteAllText($sideChannelPath, $clearOriginal, [System.Text.UTF8Encoding]::new($false))
    ([System.IO.FileInfo]$sideChannelPath).LastWriteTimeUtc = $clearTimestamp
    $clearReplacementPath = Join-Path $temporaryRoot "clear-race-replacement.txt"
    $clearDisplacedPath = Join-Path $temporaryRoot "clear-race-displaced.txt"
    [System.IO.File]::WriteAllText($clearReplacementPath, $clearReplacement, [System.Text.UTF8Encoding]::new($false))
    ([System.IO.FileInfo]$clearReplacementPath).LastWriteTimeUtc = $clearTimestamp
    $clearRaceHook = {
        param($Path, $Phase)
        if ($Phase -eq "before_quarantine") {
            Move-Item -LiteralPath $Path -Destination $clearDisplacedPath
            Move-Item -LiteralPath $clearReplacementPath -Destination $Path
            ([System.IO.FileInfo]$Path).LastWriteTimeUtc = $clearTimestamp
        }
    }
    $clearRace = Prepare-PacingEvidenceSideChannels $clearRaceEvidenceRoot $clearRaceHook
    Assert-Condition (-not $clearRace.integrity_passed -and $clearRace.archived_count -eq 0) "A same-metadata pre-clear replacement must fail preparation integrity."
    Assert-Condition ($clearRace.rejected.Count -eq 1 -and @($clearRace.rejected[0].rejection_reasons) -contains "quarantined_source_does_not_match_archive") "Pre-clear replacement rejection must identify the hash mismatch."
    Assert-Condition (Test-Path -LiteralPath $sideChannelPath) "A replacement detected during clear must be preserved."
    Assert-Condition ((Get-Content -LiteralPath $sideChannelPath -Raw) -eq $clearReplacement) "Preparation must not delete or overwrite the detected replacement."
    Assert-Condition (Test-Path -LiteralPath $clearRace.rejected[0].archive_path) "Rejected clear-race archive must remain diagnosable."
    Assert-Condition ((Get-Content -LiteralPath $clearRace.rejected[0].archive_path -Raw) -eq $clearOriginal) "Rejected clear-race archive must preserve the snapshotted original."
    Remove-Item -LiteralPath $sideChannelPath -Force

    # The one-line side-channel has a hard size ceiling before any bulk copy.
    $oversizePath = Join-Path $userDataRoot "oversize-pacing.txt"
    $oversizeDestination = Join-Path $evidenceRoot "oversize-pacing-copy.txt"
    $oversizeStream = [System.IO.File]::Open($oversizePath, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
    try {
        $oversizeStream.SetLength($maxPacingSideChannelBytes + 1)
    } finally {
        $oversizeStream.Dispose()
    }
    $oversizeSnapshot = Copy-PacingEvidenceSnapshot $oversizePath $userDataRoot $oversizeDestination
    Assert-Condition (-not $oversizeSnapshot.accepted -and @($oversizeSnapshot.record.rejection_reasons) -contains "source_exceeds_size_limit") "Oversize pacing evidence must be rejected before copying."
    Assert-Condition (-not (Test-Path -LiteralPath $oversizeDestination)) "Oversize pacing evidence must leave no destination payload."
    Remove-Item -LiteralPath $oversizePath -Force

    # A junction below the trusted destination root must not redirect a snapshot
    # write or rejection cleanup outside the evidence tree.
    $destinationContainmentRoot = Join-Path $temporaryRoot "destination-containment"
    $destinationOutsideRoot = Join-Path $temporaryRoot "destination-outside"
    $destinationJunction = Join-Path $destinationContainmentRoot "linked"
    $destinationContainmentSource = Join-Path $userDataRoot "destination-containment-source.txt"
    New-Item -ItemType Directory -Force -Path $destinationContainmentRoot, $destinationOutsideRoot | Out-Null
    [System.IO.File]::WriteAllText($destinationContainmentSource, "PAYLOAD", [System.Text.UTF8Encoding]::new($false))
    $destinationJunctionSupported = $false
    try {
        New-Item -ItemType Junction -Path $destinationJunction -Target $destinationOutsideRoot | Out-Null
        $destinationJunctionSupported = $true
    } catch {
        Write-Host "PHYSICAL_EVIDENCE_DESTINATION_CONTAINMENT_REGRESSION_SKIPPED=$($_.Exception.GetType().Name)"
    }
    if ($destinationJunctionSupported) {
        $outsideDestination = Join-Path $destinationOutsideRoot "escaped.txt"
        $junctionDestination = Join-Path $destinationJunction "escaped.txt"
        $junctionSnapshot = Copy-PacingEvidenceSnapshot $destinationContainmentSource $userDataRoot $junctionDestination $null $destinationContainmentRoot
        Assert-Condition (-not $junctionSnapshot.accepted -and $junctionSnapshot.containment_unsafe) "Destination junction traversal must be rejected."
        Assert-Condition (-not (Test-Path -LiteralPath $outsideDestination)) "Destination junction rejection must not write or delete outside the evidence root."
        Write-Host "PHYSICAL_EVIDENCE_DESTINATION_CONTAINMENT_REGRESSION_OK"
    }
    Remove-Item -LiteralPath $destinationContainmentSource -Force

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

    $verifiedHashMap = @{
        ([System.IO.Path]::GetFullPath([string]$freshCopy.evidence_path)) = [string]$freshCopy.sha256
    }

    # A verified side-channel is not optional provenance. It must contribute
    # exactly one canonical payload even when another same-run log already has
    # a valid payload that could otherwise mask an empty/foreign side-channel.
    $aggregateLogPath = Join-Path $evidenceRoot "aggregate-valid.log"
    [System.IO.File]::WriteAllText(
        $aggregateLogPath,
        $pacingPrefix + $validPacingJson + [Environment]::NewLine,
        [System.Text.UTF8Encoding]::new($false)
    )
    $missingVerifiedPayloadError = $null
    try {
        $null = Get-UniquePacingPayload @(
            $aggregateLogPath,
            [string]$freshCopy.evidence_path
        ) $verifiedHashMap
    } catch {
        $missingVerifiedPayloadError = $_
    }
    Assert-Condition (
        $null -ne $missingVerifiedPayloadError -and
        $missingVerifiedPayloadError.Exception.Message -like "*must contain exactly one PLAYTHROUGH_PACING payload; found 0*"
    ) "A hash-verified side-channel with no pacing payload must fail even when another log supplies a valid payload."

    $missingVerifiedPath = Join-Path $evidenceRoot "missing-verified-side-channel.txt"
    $missingVerifiedHashMap = @{
        ([System.IO.Path]::GetFullPath($missingVerifiedPath)) = ("0" * 64)
    }
    $missingVerifiedPathError = $null
    try {
        $null = Get-UniquePacingPayload @($aggregateLogPath, $missingVerifiedPath) $missingVerifiedHashMap
    } catch {
        $missingVerifiedPathError = $_
    }
    Assert-Condition (
        $null -ne $missingVerifiedPathError -and
        $missingVerifiedPathError.Exception.Message -like "*Verified pacing side-channel is missing*"
    ) "A missing hash-bound side-channel must fail instead of silently falling back to another log."

    $duplicateVerifiedPath = Join-Path $evidenceRoot "duplicate-verified-side-channel.txt"
    [System.IO.File]::WriteAllText(
        $duplicateVerifiedPath,
        ($pacingPrefix + $validPacingJson) +
            [Environment]::NewLine +
            ($pacingPrefix + $validPacingJson),
        [System.Text.UTF8Encoding]::new($false)
    )
    $duplicateVerifiedHashMap = @{
        ([System.IO.Path]::GetFullPath($duplicateVerifiedPath)) =
            (Get-FileHash -LiteralPath $duplicateVerifiedPath -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    $duplicateVerifiedPayloadError = $null
    try {
        $null = Get-UniquePacingPayload @($aggregateLogPath, $duplicateVerifiedPath) $duplicateVerifiedHashMap
    } catch {
        $duplicateVerifiedPayloadError = $_
    }
    Assert-Condition (
        $null -ne $duplicateVerifiedPayloadError -and
        $duplicateVerifiedPayloadError.Exception.Message -like "*must contain exactly one PLAYTHROUGH_PACING payload; found 2*"
    ) "A hash-verified side-channel must not contain duplicate payload lines (error=$($duplicateVerifiedPayloadError.Exception.Message))."

    $tamperedEvidenceBytes = New-Object byte[] ([int]$freshCopy.size_bytes)
    for ($byteIndex = 0; $byteIndex -lt $tamperedEvidenceBytes.Length; $byteIndex += 1) {
        $tamperedEvidenceBytes[$byteIndex] = [byte][char]'X'
    }
    [System.IO.File]::WriteAllBytes($freshCopy.evidence_path, $tamperedEvidenceBytes)
    $verifiedReopenError = $null
    try {
        $null = Get-UniquePacingPayload @([string]$freshCopy.evidence_path) $verifiedHashMap
    } catch {
        $verifiedReopenError = $_
    }
    Assert-Condition ($null -ne $verifiedReopenError -and $verifiedReopenError.Exception.Message -like "*changed before parsing*") "A verified side-channel replacement must be rejected from the same open parsing handle."

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

    # The hook executes after the source handle is bound. Swap the pathname to a
    # different payload with identical metadata; path metadata alone must never
    # let the replacement bytes pass as the opened source.
    $swapLaunchStartedAtUtc = (Get-Date).ToUniversalTime().AddSeconds(-1)
    $swapTimestamp = (Get-Date).ToUniversalTime().AddMinutes(-2)
    [System.IO.File]::WriteAllText($sideChannelPath, "source-A", [System.Text.UTF8Encoding]::new($false))
    ([System.IO.FileInfo]$sideChannelPath).CreationTimeUtc = $swapTimestamp
    ([System.IO.FileInfo]$sideChannelPath).LastWriteTimeUtc = $swapTimestamp
    $replacementPath = Join-Path $temporaryRoot "snapshot-replacement.txt"
    $displacedPath = Join-Path $temporaryRoot "snapshot-displaced.txt"
    [System.IO.File]::WriteAllText($replacementPath, "source-B", [System.Text.UTF8Encoding]::new($false))
    ([System.IO.FileInfo]$replacementPath).CreationTimeUtc = $swapTimestamp
    ([System.IO.FileInfo]$replacementPath).LastWriteTimeUtc = $swapTimestamp
    $swapHook = {
        param($Path, $Phase)
        if ($Phase -eq "after_pre_identity") {
            Move-Item -LiteralPath $Path -Destination $displacedPath -Force
            Move-Item -LiteralPath $replacementPath -Destination $Path -Force
            ([System.IO.FileInfo]$Path).CreationTimeUtc = $swapTimestamp
            ([System.IO.FileInfo]$Path).LastWriteTimeUtc = $swapTimestamp
        }
    }
    $swapEvidenceRoot = Join-Path $temporaryRoot "swap-evidence"
    New-Item -ItemType Directory -Force -Path $swapEvidenceRoot | Out-Null
    $swapped = Copy-PacingEvidenceSideChannels $swapEvidenceRoot $swapLaunchStartedAtUtc $baselineHashes $swapHook
    Assert-Condition ($swapped.copied_count -eq 0 -and $swapped.rejected_count -eq 1) "A source swapped during the snapshot must be rejected."
    Assert-Condition (@($swapped.rejected[0].rejection_reasons) -contains "source_identity_changed_during_snapshot") "Source-swap rejection reason must be recorded."
    Assert-Condition (-not $swapped.integrity_passed) "Source-swap anomaly must fail harvest integrity."
    Assert-Condition (-not (Test-Path -LiteralPath (Join-Path $swapEvidenceRoot $pacingSideChannelRelative))) "Source-swap anomaly must leave no destination payload."
    Assert-Condition ((Get-Content -LiteralPath $sideChannelPath -Raw) -eq "source-B") "Source-swap rejection must leave the replacement path untouched."

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
        $junctionLogTarget = Join-Path $junctionTarget "analyze.log"
        [System.IO.File]::WriteAllText($junctionLogTarget, "log", [System.Text.UTF8Encoding]::new($false))
        $junctionLogError = $null
        try {
            $null = Assert-NoReparsePointAncestors (Join-Path $appDataJunction "analyze.log") "AnalyzeLog regression"
        } catch {
            $junctionLogError = $_
        }
        Assert-Condition ($null -ne $junctionLogError -and $junctionLogError.Exception.Message -like "*Refusing reparse-point evidence path component*") "AnalyzeLog ancestors must reject junction traversal."

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
