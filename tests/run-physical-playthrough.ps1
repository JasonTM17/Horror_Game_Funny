[CmdletBinding()]
param(
    [string]$Godot = "D:\Tools\Godot-4.7.1\Godot_v4.7.1-stable_win64_console.exe",
    [ValidateSet("EditorF5", "ProjectRun")]
    [string]$LaunchMode = "EditorF5",
    [string]$CaptureReference = "",
    [switch]$ConfirmPhysicalInput,
    [string]$AnalyzeLog = "",
    [string]$EvidenceRoot = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$pacingPrefix = "PLAYTHROUGH_PACING: "
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
        "- Launch performed: ``$($Summary.launch_performed)``",
        "- Launch mode: ``$($Summary.launch_mode)``",
        "- Engine exit: ``$($Summary.engine_exit_code)``",
        "- Physical input confirmed: ``$($Summary.physical_input_confirmed)``",
        "- Capture reference: ``$($Summary.capture_reference)``",
        "- Pacing parsed: ``$($Summary.pacing_parsed)``",
        "- Pacing pass: ``$($Summary.pacing_pass)``",
        "- Manual gate ready: ``$($Summary.manual_gate_ready)``",
        "- Error: ``$($Summary.error)``",
        "",
        "## Pacing Checks",
        ""
    ) + $checkLines
    $markdown | Set-Content -LiteralPath $markdownPath -Encoding UTF8
}

if (-not (Test-Path -LiteralPath (Join-Path $repositoryRoot "project.godot"))) {
    throw "project.godot was not found below $repositoryRoot"
}

$runId = (Get-Date).ToString("yyyyMMdd-HHmmss-fff")
$evidenceDirectory = Join-Path $EvidenceRoot $runId
New-Item -ItemType Directory -Force -Path $evidenceDirectory | Out-Null
$startedAt = (Get-Date).ToUniversalTime()
$diskBefore = [ordered]@{ C = Get-FreeGiB "C"; D = Get-FreeGiB "D" }
$sourceLogs = @()
$launchPerformed = [string]::IsNullOrWhiteSpace($AnalyzeLog)
$engineExitCode = $null

if ($launchPerformed) {
    if (-not (Test-Path -LiteralPath $Godot)) {
        throw "Godot executable not found: $Godot"
    }
    $engineLog = Join-Path $evidenceDirectory "engine.log"
    $consoleLog = Join-Path $evidenceDirectory "console.log"
    $sourceLogs = @($engineLog, $consoleLog)
    $arguments = @("--path", $repositoryRoot, "--log-file", $engineLog)
    if ($LaunchMode -eq "EditorF5") {
        $arguments = @("--editor") + $arguments
        Write-Host "Godot Editor will open. Press F5, choose START SHIFT (not Continue), play to visible credits, then close the game and editor."
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
$pacingPass = $null -ne $pacingVerdict -and [bool]$pacingVerdict.passed
$enginePassed = $launchPerformed -and $engineExitCode -eq 0
$manualGateReady = $enginePassed -and $pacingPass -and [bool]$ConfirmPhysicalInput -and $captureProvided
$endedAt = (Get-Date).ToUniversalTime()
$summary = [pscustomobject][ordered]@{
    run_id = $runId
    repository_commit = (git -C $repositoryRoot rev-parse HEAD)
    started_at_utc = $startedAt.ToString("o")
    ended_at_utc = $endedAt.ToString("o")
    launch_performed = $launchPerformed
    launch_mode = if ($launchPerformed) { $LaunchMode } else { "AnalyzeLog" }
    engine_exit_code = $engineExitCode
    physical_input_confirmed = [bool]$ConfirmPhysicalInput
    capture_reference = $CaptureReference
    capture_reference_provided = $captureProvided
    source_logs = $sourceLogs
    pacing_parsed = $null -ne $pacingVerdict
    pacing_pass = $pacingPass
    pacing_verdict = $pacingVerdict
    manual_gate_ready = $manualGateReady
    error = $pacingError
    disk_free_gib_before = [pscustomobject]$diskBefore
    disk_free_gib_after = [pscustomobject][ordered]@{ C = Get-FreeGiB "C"; D = Get-FreeGiB "D" }
}
Write-EvidenceFiles $evidenceDirectory $summary

Write-Host "PHYSICAL_PLAYTHROUGH_EVIDENCE_DIR=$evidenceDirectory"
Write-Host "PACING_PASS=$pacingPass"
Write-Host "MANUAL_GATE_READY=$manualGateReady"
if (-not $manualGateReady) {
    Write-Warning "Evidence is incomplete or outside target. See summary.md; this run must not close the manual release gate."
    exit 2
}
exit 0
