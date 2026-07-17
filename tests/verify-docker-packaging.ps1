# Structural verification of Docker packaging for ROOM 407 (Windows host).
# Asserts packaging files and contracts exist without requiring Docker Engine.

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $Root
$fail = 0

function Require-File([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Error "MISSING: $Path"
        $script:fail = 1
    } else {
        Write-Host "OK file: $Path"
    }
}

function Require-Grep([string]$Path, [string]$Pattern, [string]$Label) {
    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Host "MISSING for grep: $Path ($Label)"
        $script:fail = 1
        return
    }
    if (-not (Select-String -LiteralPath $Path -Pattern $Pattern -Quiet)) {
        Write-Host "MISSING pattern in $Path ($Label): $Pattern"
        $script:fail = 1
    } else {
        Write-Host "OK pattern: $Label"
    }
}

Require-File "Dockerfile"
Require-File "docker-compose.yml"
Require-File "docker-compose.local.yml"
Require-File ".dockerignore"
Require-File "tests/run-headless-tests.sh"
Require-File "tests/run-headless-tests.ps1"

Require-Grep "Dockerfile" "4\.7\.1" "Dockerfile pins Godot 4.7.1"
Require-Grep "Dockerfile" "USER 65532:65532" "Dockerfile non-root user"
Require-Grep "Dockerfile" "HEALTHCHECK" "Dockerfile HEALTHCHECK"
Require-Grep "Dockerfile" "AS builder|AS runtime" "Dockerfile multi-stage stages"
Require-Grep "Dockerfile" "horror-game-suite" "Dockerfile image identity"
Require-Grep "docker-compose.yml" "nguyenson1710/horror-game-suite" "compose image name"
Require-Grep "tests/run-headless-tests.sh" "editor-import" "shell runner editor-import"
Require-Grep "tests/run-headless-tests.sh" "settings-persistence-read" "shell runner last check"
Require-Grep "tests/run-headless-tests.sh" "ALL_TWELVE_HEADLESS_CHECKS_OK" "shell runner completion marker"
Require-Grep "tests/run-headless-tests.sh" "PROGRESSION_TEST_OK" "shell runner progression marker"
Require-Grep "tests/run-headless-tests.ps1" "settings-persistence-read" "ps1 runner last check"

$checks = @(
    "editor-import", "menu", "gameplay", "game-state", "progression",
    "checkpoint-layout", "physical-route", "player-input", "visual-effects",
    "settings-audio", "settings-persistence-write", "settings-persistence-read"
)
foreach ($check in $checks) {
    Require-Grep "tests/run-headless-tests.sh" "\`"$check\`"" "shell check $check"
    Require-Grep "tests/run-headless-tests.ps1" "\`"$check\`"" "ps1 check $check"
}

if ($fail -ne 0) {
    Write-Error "DOCKER_PACKAGING_VERIFY_FAILED"
    exit 1
}
Write-Host "DOCKER_PACKAGING_VERIFY_OK"
