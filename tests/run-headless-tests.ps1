param(
    [string]$Godot = "D:\Tools\Godot-4.7.1\Godot_v4.7.1-stable_win64_console.exe"
)

$ErrorActionPreference = "Stop"
$env:TEMP = Join-Path (Get-Location) ".tmp"
$env:TMP = $env:TEMP
$testProfile = Join-Path $env:TEMP ("godot-user-" + [guid]::NewGuid().ToString("N"))

function Invoke-GodotCheck(
    [string[]]$Arguments,
    [string]$Name,
    [string]$Expected = "",
    [string]$PostScript = ""
) {
    $log = Join-Path ".artifacts" ("test-" + $Name + ".log")
    $engineLog = Join-Path $testProfile ("engine-" + $Name + ".log")
    $consoleLog = Join-Path $testProfile ("console-" + $Name + ".log")
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    & $Godot @Arguments --log-file $engineLog 2>&1 | Tee-Object -FilePath $consoleLog
    $exitCode = $LASTEXITCODE
    $postEngineLog = ""
    $postConsoleLog = ""
    if ($PostScript) {
        $postEngineLog = Join-Path $testProfile ("engine-" + $Name + "-post.log")
        $postConsoleLog = Join-Path $testProfile ("console-" + $Name + "-post.log")
        & $Godot --headless --path (Get-Location).Path --script $PostScript --log-file $postEngineLog 2>&1 |
            Tee-Object -FilePath $postConsoleLog
        $postExitCode = $LASTEXITCODE
        if ($postExitCode -ne 0) {
            $exitCode = $postExitCode
        }
    }
    $ErrorActionPreference = $previousErrorActionPreference
    $combinedOutput = @()
    if (Test-Path -LiteralPath $engineLog) {
        $combinedOutput += Get-Content -LiteralPath $engineLog
    }
    if (Test-Path -LiteralPath $consoleLog) {
        $combinedOutput += Get-Content -LiteralPath $consoleLog
    }
    if ($postEngineLog -and (Test-Path -LiteralPath $postEngineLog)) {
        $combinedOutput += Get-Content -LiteralPath $postEngineLog
    }
    if ($postConsoleLog -and (Test-Path -LiteralPath $postConsoleLog)) {
        $combinedOutput += Get-Content -LiteralPath $postConsoleLog
    }
    $combinedOutput | Set-Content -LiteralPath $log
    if ($exitCode -ne 0) {
        Write-Error "$Name failed with exit code $exitCode. See $log"
    }
    if (Select-String -Path $log -Pattern "ERROR:|SCRIPT ERROR|Parse Error|PROGRESSION_ASSERT|LAYOUT_ASSERT|PHYSICAL_ROUTE_ASSERT|PLAYER_INPUT_ASSERT|VISUAL_EFFECTS_ASSERT|SETTINGS_AUDIO_ASSERT|SETTINGS_PERSISTENCE_ASSERT|ObjectDB instances were leaked|Leaked instance:" -Quiet) {
        Write-Error "$Name reported an engine or progression error. See $log"
    }
    if ($Expected -and -not (Select-String -Path $log -Pattern $Expected -SimpleMatch -Quiet)) {
        Write-Error "$Name did not reach expected marker '$Expected'. See $log"
    }
    Write-Host "$Name OK"
}

try {
    if (-not (Test-Path -LiteralPath $Godot)) {
        Write-Error "Godot executable not found: $Godot"
    }

    $env:APPDATA = Join-Path $testProfile "AppData\Roaming"
    $env:LOCALAPPDATA = Join-Path $testProfile "AppData\Local"
    New-Item -ItemType Directory -Force -Path $env:APPDATA, $env:LOCALAPPDATA | Out-Null
    New-Item -ItemType Directory -Force -Path ".artifacts" | Out-Null

    Invoke-GodotCheck @("--headless", "--path", (Get-Location).Path, "--editor", "--quit") "editor-import" "PROJECT_SETTINGS_STABILITY_OK" "res://tests/project-settings-stability-test.gd"
    Invoke-GodotCheck @("--headless", "--path", (Get-Location).Path, "--scene", "res://scenes/boot/boot.tscn", "--quit-after", "8") "menu"
    Invoke-GodotCheck @("--headless", "--path", (Get-Location).Path, "--scene", "res://scenes/gameplay/gameplay.tscn", "--quit-after", "20") "gameplay"
    Invoke-GodotCheck @("--headless", "--path", (Get-Location).Path, "--script", "res://tests/game-state-test.gd", "--quit-after", "20") "game-state" "GAME_STATE_TEST_OK"
    Invoke-GodotCheck @("--headless", "--path", (Get-Location).Path, "--scene", "res://tests/progression-test.tscn", "--quit-after", "1200") "progression" "PROGRESSION_TEST_OK"
    Invoke-GodotCheck @("--headless", "--path", (Get-Location).Path, "--scene", "res://tests/checkpoint-layout-test.tscn", "--quit-after", "2000") "checkpoint-layout" "CHECKPOINT_LAYOUT_TEST_OK"
    Invoke-GodotCheck @("--headless", "--path", (Get-Location).Path, "--scene", "res://tests/physical-route-smoke-test.tscn", "--quit-after", "3600") "physical-route" "PHYSICAL_ROUTE_SMOKE_TEST_OK"
    Invoke-GodotCheck @("--headless", "--path", (Get-Location).Path, "--scene", "res://tests/player-input-integration-test.tscn", "--quit-after", "600") "player-input" "PLAYER_INPUT_INTEGRATION_TEST_OK"
    Invoke-GodotCheck @("--headless", "--path", (Get-Location).Path, "--scene", "res://tests/visual-effects-test.tscn", "--quit-after", "180") "visual-effects" "VISUAL_EFFECTS_TEST_OK"
    Invoke-GodotCheck @("--headless", "--path", (Get-Location).Path, "--scene", "res://tests/settings-audio-test.tscn", "--quit-after", "600") "settings-audio" "SETTINGS_AUDIO_TEST_OK"
    Invoke-GodotCheck @("--headless", "--path", (Get-Location).Path, "--scene", "res://tests/settings-persistence-write-test.tscn", "--quit-after", "60") "settings-persistence-write" "SETTINGS_PERSISTENCE_WRITE_OK"
    Invoke-GodotCheck @("--headless", "--path", (Get-Location).Path, "--scene", "res://tests/settings-persistence-read-test.tscn", "--quit-after", "60") "settings-persistence-read" "SETTINGS_PERSISTENCE_READ_OK"
}
finally {
    if (Test-Path -LiteralPath $testProfile) {
        $tempRoot = (Resolve-Path -LiteralPath $env:TEMP).Path.TrimEnd("\")
        $profilePath = (Resolve-Path -LiteralPath $testProfile).Path.TrimEnd("\")
        $expectedPrefix = $tempRoot + "\godot-user-"
        if (-not $profilePath.StartsWith($expectedPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            Write-Error "Refusing to remove test profile outside the repository-local temp root: $profilePath"
        }
        Remove-Item -LiteralPath $profilePath -Recurse -Force
    }
}
