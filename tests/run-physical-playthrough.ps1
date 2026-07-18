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
    [string]$EvidenceRoot = ""
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
$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
if (-not $EvidenceRoot) {
    $EvidenceRoot = Join-Path $repositoryRoot ".artifacts\manual-playthrough"
} elseif (-not [System.IO.Path]::IsPathRooted($EvidenceRoot)) {
    $EvidenceRoot = Join-Path $repositoryRoot $EvidenceRoot
}

function Get-FreeGiB([string]$DriveName) {
    $drive = Get-PSDrive -Name $DriveName -ErrorAction SilentlyContinue
    if ($null -eq $drive) {
        return $null
    }
    return [math]::Round($drive.Free / 1GB, 2)
}

function Get-GodotAppUserDataRoots {
    $roots = New-Object System.Collections.Generic.List[string]
    $appDataGodot = Join-Path $env:APPDATA "Godot\app_userdata"
    if (-not (Test-Path -LiteralPath $appDataGodot)) {
        return @()
    }
    # Godot normalizes project config/name for the userdata folder (":" -> "-").
    $candidates = @(
        "ROOM 407: THE LAST SHIFT",
        "ROOM 407- THE LAST SHIFT"
    )
    foreach ($name in $candidates) {
        $path = Join-Path $appDataGodot $name
        if (Test-Path -LiteralPath $path) {
            [void]$roots.Add((Resolve-Path -LiteralPath $path).Path)
        }
    }
    Get-ChildItem -LiteralPath $appDataGodot -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "*ROOM 407*" } |
        ForEach-Object {
            $resolved = (Resolve-Path -LiteralPath $_.FullName).Path
            if (-not $roots.Contains($resolved)) {
                [void]$roots.Add($resolved)
            }
        }
    return @($roots)
}

function Copy-PacingEvidenceSideChannels([string]$DestinationDirectory) {
    $copied = New-Object System.Collections.Generic.List[string]
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
        Copy-Item -LiteralPath $source -Destination $destination -Force
        [void]$copied.Add($destination)
        $index += 1
    }
    return @($copied)
}

function Get-UniquePacingPayload([string[]]$LogPaths) {
    $payloads = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal
    )
    foreach ($logPath in $LogPaths) {
        if (-not (Test-Path -LiteralPath $logPath)) {
            continue
        }
        foreach ($line in Get-Content -LiteralPath $logPath) {
            $prefixIndex = $line.IndexOf($pacingPrefix, [System.StringComparison]::Ordinal)
            if ($prefixIndex -lt 0) {
                continue
            }
            $json = $line.Substring($prefixIndex + $pacingPrefix.Length).Trim()
            if ($json.StartsWith("{", [System.StringComparison]::Ordinal)) {
                [void]$payloads.Add($json)
            }
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
    $boundaryOrder = @($Payload.boundary_order)
    $targetTotal = @($Payload.target_seconds.total)
    if ($targetTotal.Count -ne 2) {
        throw "Pacing payload does not contain a two-value total target."
    }

    $chapterFailures = @(
        $Payload.chapter_within_target.PSObject.Properties |
            Where-Object { $_.Value -ne $true }
    )
    $checks = [ordered]@{
        eligible_full_run = [bool]$Payload.eligible_full_run
        complete = [bool]$Payload.complete
        initial_stage_lobby = [string]$Payload.initial_stage -eq "lobby"
        boundary_order_valid = [bool]$Payload.boundary_order_valid
        boundary_order_exact = [string]::Join("|", $boundaryOrder) -eq [string]::Join("|", $expectedBoundaryOrder)
        no_missing_milestones = @($Payload.missing_milestones).Count -eq 0
        total_target_metadata = [double]$targetTotal[0] -eq 900.0 -and [double]$targetTotal[1] -eq 1200.0
        active_time_in_target = [double]$Payload.active_gameplay_seconds -ge [double]$targetTotal[0] -and [double]$Payload.active_gameplay_seconds -le [double]$targetTotal[1]
        every_chapter_in_target = $chapterFailures.Count -eq 0
        within_target = $Payload.within_target -eq $true
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
        active_gameplay_seconds = [double]$Payload.active_gameplay_seconds
        wall_clock_seconds = [double]$Payload.wall_clock_seconds
        paused_seconds = [double]$Payload.paused_seconds
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

function Write-EvidenceFiles([string]$Directory, [object]$Summary) {
    $jsonPath = Join-Path $Directory "summary.json"
    $markdownPath = Join-Path $Directory "summary.md"
    $Summary | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

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
        "- Launch performed: ``$($Summary.launch_performed)``",
        "- Launch mode: ``$($Summary.launch_mode)``",
        "- Engine exit: ``$($Summary.engine_exit_code)``",
        "- Physical input confirmed: ``$($Summary.physical_input_confirmed)``",
        "- Capture reference: ``$($Summary.capture_reference)``",
        "- Log failure count: ``$($Summary.log_failure_count)``",
        "- Pacing parsed: ``$($Summary.pacing_parsed)``",
        "- Pacing pass: ``$($Summary.pacing_pass)``",
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
    $markdown | Set-Content -LiteralPath $markdownPath -Encoding UTF8
}

if (-not (Test-Path -LiteralPath (Join-Path $repositoryRoot "project.godot"))) {
    throw "project.godot was not found below $repositoryRoot"
}

$repositoryCommitBefore = [string](git -C $repositoryRoot rev-parse HEAD)
$repositoryBranchBefore = [string](git -C $repositoryRoot branch --show-current)
$repositoryDirtyBefore = @(git -C $repositoryRoot status --porcelain).Count -ne 0
$runId = (Get-Date).ToString("yyyyMMdd-HHmmss-fff")
$evidenceDirectory = Join-Path $EvidenceRoot $runId
New-Item -ItemType Directory -Force -Path $evidenceDirectory | Out-Null
$startedAt = (Get-Date).ToUniversalTime()
$diskBefore = [ordered]@{ C = Get-FreeGiB "C"; D = Get-FreeGiB "D" }
$sourceLogs = @()
$launchPerformed = [string]::IsNullOrWhiteSpace($AnalyzeLog)
$engineExitCode = $null
$godotVersion = ""

if ($launchPerformed) {
    if (-not (Test-Path -LiteralPath $Godot)) {
        throw "Godot executable not found: $Godot"
    }
    $godotVersion = [string](& $Godot --version 2>&1 | Select-Object -First 1)
    $engineLog = Join-Path $evidenceDirectory "engine.log"
    $consoleLog = Join-Path $evidenceDirectory "console.log"
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

    $previousPreference = $ErrorActionPreference
    Push-Location $repositoryRoot
    try {
        $ErrorActionPreference = "Continue"
        & $Godot @arguments 2>&1 | Tee-Object -FilePath $consoleLog
        $engineExitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousPreference
        Pop-Location
    }

    # Harvest last-run side-channel even when editor/game processes split.
    $sideChannels = @(Copy-PacingEvidenceSideChannels $evidenceDirectory)
    if ($sideChannels.Count -gt 0) {
        $sourceLogs += $sideChannels
        Write-Host "HARVESTED_PACING_SIDE_CHANNEL_COUNT=$($sideChannels.Count)"
    } else {
        Write-Host "HARVESTED_PACING_SIDE_CHANNEL_COUNT=0"
    }
} else {
    $analyzeLogPath = $AnalyzeLog
    if (-not [System.IO.Path]::IsPathRooted($analyzeLogPath)) {
        $analyzeLogPath = Join-Path $repositoryRoot $analyzeLogPath
    }
    $resolvedLog = (Resolve-Path -LiteralPath $analyzeLogPath).Path
    $sourceLogs = @($resolvedLog)
}

$pacingVerdict = $null
$pacingError = ""
try {
    $payload = Get-UniquePacingPayload $sourceLogs
    $pacingVerdict = Get-PacingVerdict $payload
} catch {
    $pacingError = $_.Exception.Message
}

$captureProvided = -not [string]::IsNullOrWhiteSpace($CaptureReference)
$logFailures = @(Get-UniqueLogFailures $sourceLogs)
$pacingPass = $null -ne $pacingVerdict -and [bool]$pacingVerdict.passed
$enginePassed = $launchPerformed -and $engineExitCode -eq 0 -and $logFailures.Count -eq 0
$repositoryCommitAfter = [string](git -C $repositoryRoot rev-parse HEAD)
$repositoryBranchAfter = [string](git -C $repositoryRoot branch --show-current)
$repositoryDirtyAfter = @(git -C $repositoryRoot status --porcelain).Count -ne 0
$repositoryStable = -not $repositoryDirtyBefore -and -not $repositoryDirtyAfter -and $repositoryCommitBefore -eq $repositoryCommitAfter -and $repositoryBranchBefore -eq $repositoryBranchAfter
$evidencePackageReady = $enginePassed -and $pacingPass -and $repositoryStable -and [bool]$ConfirmPhysicalInput -and $captureProvided
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
    started_at_utc = $startedAt.ToString("o")
    ended_at_utc = $endedAt.ToString("o")
    launch_performed = $launchPerformed
    launch_mode = if ($launchPerformed) { $LaunchMode } else { "AnalyzeLog" }
    engine_exit_code = $engineExitCode
    physical_input_confirmed = [bool]$ConfirmPhysicalInput
    capture_reference = $CaptureReference
    capture_reference_provided = $captureProvided
    source_logs = $sourceLogs
    log_failure_count = $logFailures.Count
    log_failure_lines = $logFailures
    pacing_parsed = $null -ne $pacingVerdict
    pacing_pass = $pacingPass
    pacing_verdict = $pacingVerdict
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
