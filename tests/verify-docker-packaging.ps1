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

function Require-NoGrep([string]$Path, [string]$Pattern, [string]$Label) {
    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Host "MISSING for grep: $Path ($Label)"
        $script:fail = 1
        return
    }
    if (Select-String -LiteralPath $Path -Pattern $Pattern -Quiet) {
        Write-Host "FORBIDDEN pattern in $Path ($Label): $Pattern"
        $script:fail = 1
    } else {
        Write-Host "OK absent: $Label"
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
Require-Grep "Dockerfile" "GODOT_SHA256|sha256sum" "Dockerfile pins Godot download checksum"
Require-Grep "docker-compose.yml" "nguyenson1710/horror-game-suite" "compose image name"
Require-Grep ".dockerignore" "\.env" "dockerignore excludes dotenv"
Require-Grep ".dockerignore" "docs/media" "dockerignore excludes docs-only cover media"
Require-Grep ".gitignore" "\.env" "gitignore excludes dotenv"
Require-NoGrep ".github/workflows/docker-suite.yml" "^\s*if:.*secrets\." "workflow condition does not reference secrets directly"
Require-Grep ".github/workflows/docker-suite.yml" "^\s*if: github\.ref == 'refs/heads/main' && github\.event_name == 'push'$" "publish step remains main-push only"
Require-Grep ".github/workflows/docker-suite.yml" '^\s*DOCKERHUB_USERNAME: \$\{\{ secrets\.DOCKERHUB_USERNAME \}\}$' "publish username stays step-scoped"
Require-Grep ".github/workflows/docker-suite.yml" '^\s*DOCKERHUB_TOKEN: \$\{\{ secrets\.DOCKERHUB_TOKEN \}\}$' "publish token stays step-scoped"
Require-Grep ".github/workflows/docker-suite.yml" 'DOCKERHUB_USERNAME' "publish still references Docker Hub username"
Require-Grep ".github/workflows/docker-suite.yml" 'publish skipped' "publish skips when secrets are absent"
Require-Grep ".github/workflows/docker-suite.yml" "permissions:" "workflow sets least-privilege permissions"
Require-Grep ".github/workflows/ci.yml" "permissions:" "ci workflow sets least-privilege permissions"
Require-Grep "tests/run-headless-tests.sh" "editor-import" "shell runner editor-import"
Require-Grep "tests/run-headless-tests.sh" "settings-persistence-read" "shell runner last check"
Require-Grep "tests/run-headless-tests.sh" "ALL_TWELVE_HEADLESS_CHECKS_OK" "shell runner completion marker"
Require-Grep "tests/run-headless-tests.sh" "PROGRESSION_TEST_OK" "shell runner progression marker"
Require-Grep "tests/run-headless-tests.sh" "quit-after 120000" "shell runner physical-route frame budget"
Require-Grep "tests/run-headless-tests.ps1" "120000" "ps1 runner physical-route frame budget"
Require-Grep "tests/run-headless-tests.ps1" "settings-persistence-read" "ps1 runner last check"

$checks = @(
    "editor-import", "menu", "gameplay", "game-state", "progression",
    "checkpoint-layout", "physical-route", "player-input", "visual-effects",
    "settings-audio", "settings-persistence-write", "settings-persistence-read"
)
$shellRunnerText = Get-Content -LiteralPath (Join-Path $root "tests/run-headless-tests.sh") -Raw
$allShellMatches = [regex]::Matches($shellRunnerText, '(?m)^[\t ]*run_check(?:[\t ]|$)')
$shellMatches = [regex]::Matches($shellRunnerText, '(?m)^[\t ]*run_check[\t ]+"(?<name>[^"]+)"')
$shellChecks = @($shellMatches | ForEach-Object { $_.Groups['name'].Value })
if ($allShellMatches.Count -ne $shellMatches.Count -or [string]::Join('|', $shellChecks) -cne [string]::Join('|', $checks)) {
    Write-Warning "FAIL shell runner active check sequence/count must be exactly the canonical twelve"
    $fail = 1
} else {
    Write-Host "OK shell runner exact check sequence/count"
}

$runnerTokens = $null
$runnerParseErrors = $null
$runnerAst = [System.Management.Automation.Language.Parser]::ParseFile(
    (Join-Path $root "tests/run-headless-tests.ps1"),
    [ref]$runnerTokens,
    [ref]$runnerParseErrors
)
if ($runnerParseErrors.Count -gt 0) {
    Write-Warning "FAIL PowerShell runner does not parse"
    $fail = 1
} else {
    $runnerCommands = @($runnerAst.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.CommandAst] -and
            $node.GetCommandName() -eq "Invoke-GodotCheck"
    }, $true))
    $psChecks = @()
    $runnerShapeValid = $true
    foreach ($command in $runnerCommands) {
        if ($command.CommandElements.Count -lt 3 -or $command.CommandElements[2] -isnot [System.Management.Automation.Language.StringConstantExpressionAst]) {
            $runnerShapeValid = $false
            break
        }
        $psChecks += $command.CommandElements[2].Value
    }
    if (-not $runnerShapeValid -or [string]::Join('|', $psChecks) -cne [string]::Join('|', $checks)) {
        Write-Warning "FAIL PowerShell runner active check sequence/count must be exactly the canonical twelve"
        $fail = 1
    } else {
        Write-Host "OK PowerShell runner exact check sequence/count"
    }
}

if ($fail -ne 0) {
    Write-Error "DOCKER_PACKAGING_VERIFY_FAILED"
    exit 1
}
Write-Host "DOCKER_PACKAGING_VERIFY_OK"
