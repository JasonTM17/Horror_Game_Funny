param(
    [string]$Godot = "D:\Tools\Godot-4.7.1\Godot_v4.7.1-stable_win64_console.exe",
    [string]$Preset = "Windows Desktop x86_64",
    [string]$OutputDirectory = ".artifacts\builds\room407-windows-x86_64"
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path.TrimEnd("\")
$artifactRoot = Join-Path $root ".artifacts"
$outputRoot = [System.IO.Path]::GetFullPath((Join-Path $root $OutputDirectory)).TrimEnd("\")
$expectedOutputPrefix = $artifactRoot.TrimEnd("\") + "\"

if (-not $outputRoot.StartsWith($expectedOutputPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to export outside the repository .artifacts directory: $outputRoot"
}
if (-not (Test-Path -LiteralPath $Godot)) {
    throw "Godot executable not found: $Godot"
}

$version = (& $Godot --headless --version 2>&1 | Select-Object -First 1).ToString().Trim()
if (-not $version.StartsWith("4.7.1.stable.official")) {
    throw "Expected Godot 4.7.1 standard, got: $version"
}

$presetPath = Join-Path $root "export_presets.cfg"
$presetText = Get-Content -LiteralPath $presetPath -Raw
foreach ($required in @(
    'name="Windows Desktop x86_64"',
    'platform="Windows Desktop"',
    'binary_format/architecture="x86_64"',
    'binary_format/embed_pck=true',
    'codesign/enable=false'
)) {
    if (-not $presetText.Contains($required)) {
        throw "Export preset is missing required contract: $required"
    }
}
if ($presetText -match '(?i)(password|token|secret|private_key)\s*=\s*"[^\"]+"') {
    throw "Export preset contains a non-empty credential-like value"
}

$templateRoot = Join-Path (Split-Path -Parent $Godot) "editor_data\export_templates\4.7.1.stable"
$releaseTemplate = Join-Path $templateRoot "windows_release_x86_64.exe"
if (-not (Test-Path -LiteralPath $releaseTemplate)) {
    throw "Godot 4.7.1 Windows x86_64 release template is not installed: $releaseTemplate"
}

New-Item -ItemType Directory -Force -Path $artifactRoot, $outputRoot | Out-Null
$outputExe = Join-Path $outputRoot "ROOM_407_THE_LAST_SHIFT.exe"
$exportLog = Join-Path $outputRoot "export.log"
$exportConsole = Join-Path $outputRoot "export-console.log"

$oldAppData = $env:APPDATA
$oldLocalAppData = $env:LOCALAPPDATA
$profile = Join-Path (Join-Path $root ".tmp") ("windows-export-" + [guid]::NewGuid().ToString("N"))

try {
    $env:APPDATA = Join-Path $profile "AppData\Roaming"
    $env:LOCALAPPDATA = Join-Path $profile "AppData\Local"
    New-Item -ItemType Directory -Force -Path $env:APPDATA, $env:LOCALAPPDATA | Out-Null

    & $Godot --headless --path $root --export-release $Preset $outputExe --log-file $exportLog 2>&1 |
        Tee-Object -FilePath $exportConsole
    if ($LASTEXITCODE -ne 0) {
        throw "Windows export failed with exit code $LASTEXITCODE"
    }
    if (-not (Test-Path -LiteralPath $outputExe)) {
        throw "Windows export did not create: $outputExe"
    }

    $exportText = @(
        (Get-Content -LiteralPath $exportLog -Raw),
        (Get-Content -LiteralPath $exportConsole -Raw)
    ) -join "`n"
    if ($exportText -match 'ERROR:|SCRIPT ERROR|Parse Error|Crash') {
        throw "Windows export log contains a failure marker"
    }

    Copy-Item -LiteralPath (Join-Path $root "LICENSE") -Destination (Join-Path $outputRoot "LICENSE") -Force
    Copy-Item -LiteralPath (Join-Path $root "THIRD_PARTY_NOTICES.md") -Destination (Join-Path $outputRoot "THIRD_PARTY_NOTICES.md") -Force

    $smokeLog = Join-Path $outputRoot "smoke-engine.log"
    $smokeConsole = Join-Path $outputRoot "smoke-console.log"
    & $outputExe --headless --quit-after 180 --log-file $smokeLog 2>&1 |
        Tee-Object -FilePath $smokeConsole
    if ($LASTEXITCODE -ne 0) {
        throw "Exported executable smoke failed with exit code $LASTEXITCODE"
    }
    $smokeText = @(
        (Get-Content -LiteralPath $smokeLog -Raw),
        (Get-Content -LiteralPath $smokeConsole -Raw)
    ) -join "`n"
    if ($smokeText -match 'ERROR:|SCRIPT ERROR|Parse Error|Crash') {
        throw "Exported executable smoke log contains a failure marker"
    }

    $item = Get-Item -LiteralPath $outputExe
    $hash = (Get-FileHash -LiteralPath $outputExe -Algorithm SHA256).Hash.ToLowerInvariant()
    $bytes = [System.IO.File]::ReadAllBytes($outputExe)
    $peOffset = [BitConverter]::ToInt32($bytes, 0x3c)
    $machine = [BitConverter]::ToUInt16($bytes, $peOffset + 4)
    if ($machine -ne 0x8664) {
        throw ("Expected PE x86_64 machine 0x8664, got 0x{0:x}" -f $machine)
    }

    Write-Host "WINDOWS_EXPORT_SIZE_BYTES=$($item.Length)"
    Write-Host "WINDOWS_EXPORT_SHA256=$hash"
    Write-Host "WINDOWS_EXPORT_PE=x86_64"
    Write-Host "WINDOWS_EXPORTED_MENU_SMOKE_OK"
    Write-Host "WINDOWS_EXPORT_VERIFY_OK"
}
finally {
    $env:APPDATA = $oldAppData
    $env:LOCALAPPDATA = $oldLocalAppData
    if (Test-Path -LiteralPath $profile) {
        $tempRoot = (Resolve-Path (Join-Path $root ".tmp")).Path.TrimEnd("\")
        $resolvedProfile = (Resolve-Path -LiteralPath $profile).Path.TrimEnd("\")
        $expectedProfilePrefix = $tempRoot + "\windows-export-"
        if (-not $resolvedProfile.StartsWith($expectedProfilePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove export profile outside repository temp root: $resolvedProfile"
        }
        Remove-Item -LiteralPath $resolvedProfile -Recurse -Force
    }
}
