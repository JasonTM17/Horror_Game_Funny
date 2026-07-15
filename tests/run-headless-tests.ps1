param(
    [string]$Godot = "D:\Tools\Godot-4.7.1\Godot_v4.7.1-stable_win64_console.exe"
)

$ErrorActionPreference = "Stop"
$env:TEMP = Join-Path (Get-Location) ".tmp"
$env:TMP = $env:TEMP
New-Item -ItemType Directory -Force -Path ".artifacts" | Out-Null

function Invoke-GodotCheck([string[]]$Arguments, [string]$Name) {
    $log = Join-Path ".artifacts" ("test-" + $Name + ".log")
    & $Godot @Arguments --log-file $log
    if ($LASTEXITCODE -ne 0) {
        Write-Error "$Name failed with exit code $LASTEXITCODE. See $log"
    }
    if (Select-String -Path $log -Pattern "ERROR:|SCRIPT ERROR|Parse Error|PROGRESSION_ASSERT" -Quiet) {
        Write-Error "$Name reported an engine or progression error. See $log"
    }
    Write-Host "$Name OK"
}

if (-not (Test-Path -LiteralPath $Godot)) {
    Write-Error "Godot executable not found: $Godot"
}

Invoke-GodotCheck @("--headless", "--path", (Get-Location).Path, "--editor", "--quit") "editor-import"
Invoke-GodotCheck @("--headless", "--path", (Get-Location).Path, "--scene", "res://scenes/boot/boot.tscn", "--quit-after", "8") "menu"
Invoke-GodotCheck @("--headless", "--path", (Get-Location).Path, "--scene", "res://scenes/gameplay/gameplay.tscn", "--quit-after", "20") "gameplay"
Invoke-GodotCheck @("--headless", "--path", (Get-Location).Path, "--script", "res://tests/game-state-test.gd", "--quit-after", "20") "game-state"
Invoke-GodotCheck @("--headless", "--path", (Get-Location).Path, "--scene", "res://tests/progression-test.tscn", "--quit-after", "180") "progression"
