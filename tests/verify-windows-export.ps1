param(
    [string]$Godot = "D:\Tools\Godot-4.7.1\Godot_v4.7.1-stable_win64_console.exe",
    [string]$Preset = "Windows Desktop x86_64",
    [string]$OutputDirectory = ".artifacts\builds\room407-windows-x86_64",
    [string]$TemplateArchive = "D:\Tools\Godot-4.7.1\Godot_v4.7.1-stable_export_templates.tpz"
)

$ErrorActionPreference = "Stop"
$expectedArchiveHash = "86409db6200b6f8fd3230989c2d2002851f3dd18acf11d7bdbafddf5a0dd0f72"
$expectedGodotCopyrightHash = "cb1980c88089573bcacd7221d777c689bb8bbd778799f24c27fca0fe5f774d6d"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path.TrimEnd("\")
$artifactRoot = Join-Path $root ".artifacts"
$outputRoot = [System.IO.Path]::GetFullPath((Join-Path $root $OutputDirectory)).TrimEnd("\")
$expectedOutputPrefix = $artifactRoot.TrimEnd("\") + "\"

function Require-ExactLine(
    [string]$SectionText,
    [string]$Expected,
    [string]$Context
) {
    $pattern = "(?m)^" + [regex]::Escape($Expected) + "\r?$"
    if (-not [regex]::IsMatch($SectionText, $pattern)) {
        throw "$Context is missing required contract: $Expected"
    }
}

function Assert-NoReparsePointPath(
    [string]$TrustedRoot,
    [string]$Candidate,
    [string]$Context
) {
    $trustedFull = [System.IO.Path]::GetFullPath($TrustedRoot).TrimEnd("\")
    $candidateFull = [System.IO.Path]::GetFullPath($Candidate).TrimEnd("\")
    $trustedPrefix = $trustedFull + "\"
    if (
        $candidateFull -ne $trustedFull -and
        -not $candidateFull.StartsWith($trustedPrefix, [System.StringComparison]::OrdinalIgnoreCase)
    ) {
        throw "$Context is outside the trusted repository root: $candidateFull"
    }

    $relative = if ($candidateFull -eq $trustedFull) { "" } else { $candidateFull.Substring($trustedPrefix.Length) }
    $current = $trustedFull
    foreach ($segment in $relative.Split(@("\"), [System.StringSplitOptions]::RemoveEmptyEntries)) {
        $current = Join-Path $current $segment
        if (-not (Test-Path -LiteralPath $current)) {
            continue
        }
        $item = Get-Item -LiteralPath $current -Force
        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "$Context contains a reparse-point ancestor: $current"
        }
    }
}

if (-not $outputRoot.StartsWith($expectedOutputPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to export outside the repository .artifacts directory: $outputRoot"
}
if (-not (Test-Path -LiteralPath $Godot)) {
    throw "Godot executable not found: $Godot"
}
if (-not (Test-Path -LiteralPath $TemplateArchive)) {
    throw "Official Godot export-template archive not found: $TemplateArchive"
}

$version = (& $Godot --headless --version 2>&1 | Select-Object -First 1).ToString().Trim()
if (-not $version.StartsWith("4.7.1.stable.official")) {
    throw "Expected Godot 4.7.1 standard, got: $version"
}

$presetPath = Join-Path $root "export_presets.cfg"
$presetText = Get-Content -LiteralPath $presetPath -Raw
$sectionMatches = [regex]::Matches(
    $presetText,
    '(?ms)^\[(?<name>[^\]\r\n]+)\]\r?\n(?<body>.*?)(?=^\[|\z)'
)
$presetNameLine = 'name="' + $Preset + '"'
$presetNamePattern = "(?m)^" + [regex]::Escape($presetNameLine) + "\r?$"
$presetSections = @()
foreach ($section in $sectionMatches) {
    if (
        $section.Groups["name"].Value -match '^preset\.\d+$' -and
        [regex]::IsMatch($section.Groups["body"].Value, $presetNamePattern)
    ) {
        $presetSections += $section
    }
}
if ($presetSections.Count -ne 1) {
    throw "Expected exactly one export preset named '$Preset', got $($presetSections.Count)"
}
$presetSection = $presetSections[0]
$presetSectionName = $presetSection.Groups["name"].Value
$presetBody = $presetSection.Groups["body"].Value
$optionsSection = $null
foreach ($section in $sectionMatches) {
    if ($section.Groups["name"].Value -eq "$presetSectionName.options") {
        $optionsSection = $section
        break
    }
}
if ($null -eq $optionsSection) {
    throw "Export preset '$Preset' has no matching options section"
}
$optionsBody = $optionsSection.Groups["body"].Value
foreach ($required in @(
    'platform="Windows Desktop"',
    'runnable=true',
    'dedicated_server=false',
    'custom_features=""',
    'export_filter="all_resources"',
    'include_filter=""',
    'exclude_filter="tests/*,docs/*,plans/*,.artifacts/*,.tmp/*,exports/*,builds/*"',
    'patches=PackedStringArray()',
    'encryption_include_filters=""',
    'encryption_exclude_filters=""',
    'encrypt_pck=false',
    'encrypt_directory=false',
    'script_export_mode=2',
    'export_path=".artifacts/builds/room407-windows-x86_64/ROOM_407_THE_LAST_SHIFT.exe"'
)) {
    Require-ExactLine $presetBody $required "Export preset '$Preset'"
}
foreach ($required in @(
    'custom_template/debug=""',
    'custom_template/release=""',
    'binary_format/architecture="x86_64"',
    'binary_format/embed_pck=true',
    'codesign/enable=false',
    'codesign/timestamp=false',
    'codesign/timestamp_server_url=""',
    'codesign/description=""',
    'codesign/custom_options=PackedStringArray()',
    'ssh_remote_deploy/enabled=false',
    'ssh_remote_deploy/host=""',
    'ssh_remote_deploy/extra_args_ssh=""',
    'ssh_remote_deploy/extra_args_scp=""',
    'ssh_remote_deploy/run_script=""',
    'ssh_remote_deploy/cleanup_script=""'
)) {
    Require-ExactLine $optionsBody $required "Export preset '$Preset' options"
}
if ($presetText -match '(?im)^\s*[^#\r\n]*(password|token|secret|private_key|identity)[^=]*=\s*"[^"]+"\s*$') {
    throw "Export preset contains a non-empty credential-like value"
}

$archiveHash = (Get-FileHash -LiteralPath $TemplateArchive -Algorithm SHA256).Hash.ToLowerInvariant()
if ($archiveHash -ne $expectedArchiveHash) {
    throw "Godot template archive hash mismatch: $archiveHash"
}
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead($TemplateArchive)
try {
    $versionEntry = $archive.GetEntry("templates/version.txt")
    $templateEntry = $archive.GetEntry("templates/windows_release_x86_64.exe")
    if ($null -eq $versionEntry -or $null -eq $templateEntry) {
        throw "Official template archive is missing version.txt or windows_release_x86_64.exe"
    }
    $versionReader = [System.IO.StreamReader]::new($versionEntry.Open())
    try {
        $templateVersion = $versionReader.ReadToEnd().Trim()
    }
    finally {
        $versionReader.Dispose()
    }
    if ($templateVersion -ne "4.7.1.stable") {
        throw "Expected template version 4.7.1.stable, got: $templateVersion"
    }
    $templateEntryStream = $templateEntry.Open()
    $templateSha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $archiveTemplateHash = ([BitConverter]::ToString($templateSha.ComputeHash($templateEntryStream))).Replace("-", "").ToLowerInvariant()
    }
    finally {
        $templateSha.Dispose()
        $templateEntryStream.Dispose()
    }
}
finally {
    $archive.Dispose()
}

$templateRoot = Join-Path (Split-Path -Parent $Godot) "editor_data\export_templates\4.7.1.stable"
$releaseTemplate = Join-Path $templateRoot "windows_release_x86_64.exe"
if (-not (Test-Path -LiteralPath $releaseTemplate)) {
    throw "Godot 4.7.1 Windows x86_64 release template is not installed: $releaseTemplate"
}
$installedTemplateHash = (Get-FileHash -LiteralPath $releaseTemplate -Algorithm SHA256).Hash.ToLowerInvariant()
if ($installedTemplateHash -ne $archiveTemplateHash) {
    throw "Installed Windows release template does not match the verified official archive"
}

$godotCopyright = Join-Path $root "GODOT_COPYRIGHT.txt"
if (-not (Test-Path -LiteralPath $godotCopyright)) {
    throw "Pinned Godot third-party copyright inventory is missing: $godotCopyright"
}
$godotCopyrightHash = (Get-FileHash -LiteralPath $godotCopyright -Algorithm SHA256).Hash.ToLowerInvariant()
if ($godotCopyrightHash -ne $expectedGodotCopyrightHash) {
    throw "Pinned Godot 4.7.1 COPYRIGHT.txt hash mismatch: $godotCopyrightHash"
}

$tempRoot = Join-Path $root ".tmp"
Assert-NoReparsePointPath $root $artifactRoot "Artifact root"
Assert-NoReparsePointPath $root $outputRoot "Windows export output"
Assert-NoReparsePointPath $root $tempRoot "Temporary profile root"
New-Item -ItemType Directory -Force -Path $artifactRoot, $outputRoot | Out-Null
Assert-NoReparsePointPath $root $artifactRoot "Artifact root"
Assert-NoReparsePointPath $root $outputRoot "Windows export output"
$lockPath = Join-Path $artifactRoot "windows-export.lock"
try {
    $lockStream = [System.IO.File]::Open(
        $lockPath,
        [System.IO.FileMode]::OpenOrCreate,
        [System.IO.FileAccess]::ReadWrite,
        [System.IO.FileShare]::None
    )
}
catch {
    throw "Another Windows export verification is already running for this repository"
}

$runId = [guid]::NewGuid().ToString("N")
$stagingParent = Join-Path $artifactRoot "staging"
$stagingRoot = Join-Path $stagingParent ("windows-export-" + $runId)
$stageExe = Join-Path $stagingRoot "ROOM_407_THE_LAST_SHIFT.exe"
$exportLog = Join-Path $stagingRoot "export.log"
$exportConsole = Join-Path $stagingRoot "export-console.log"
$smokeLog = Join-Path $stagingRoot "smoke-engine.log"
$smokeConsole = Join-Path $stagingRoot "smoke-console.log"
$oldAppData = $env:APPDATA
$oldLocalAppData = $env:LOCALAPPDATA
$profile = Join-Path $tempRoot ("windows-export-" + $runId)
$publishTemps = @()

try {
    Assert-NoReparsePointPath $root $stagingRoot "Windows export staging"
    Assert-NoReparsePointPath $root $profile "Windows export profile"
    $env:APPDATA = Join-Path $profile "AppData\Roaming"
    $env:LOCALAPPDATA = Join-Path $profile "AppData\Local"
    New-Item -ItemType Directory -Force -Path $env:APPDATA, $env:LOCALAPPDATA, $stagingRoot | Out-Null
    Assert-NoReparsePointPath $root $stagingRoot "Windows export staging"
    Assert-NoReparsePointPath $root $profile "Windows export profile"

    $exportStartedUtc = [DateTime]::UtcNow
    & $Godot --headless --path $root --export-release $Preset $stageExe --log-file $exportLog 2>&1 |
        Tee-Object -FilePath $exportConsole
    if ($LASTEXITCODE -ne 0) {
        throw "Windows export failed with exit code $LASTEXITCODE"
    }
    foreach ($requiredOutput in @($stageExe, $exportLog, $exportConsole)) {
        if (-not (Test-Path -LiteralPath $requiredOutput)) {
            throw "Windows export did not create current-run output: $requiredOutput"
        }
    }
    $stageItem = Get-Item -LiteralPath $stageExe
    if ($stageItem.LastWriteTimeUtc -lt $exportStartedUtc.AddSeconds(-2)) {
        throw "Windows export executable is not fresh for the current verifier run"
    }

    $exportText = @(
        (Get-Content -LiteralPath $exportLog -Raw),
        (Get-Content -LiteralPath $exportConsole -Raw)
    ) -join "`n"
    if ($exportText -match 'ERROR:|SCRIPT ERROR|Parse Error|Crash') {
        throw "Windows export log contains a failure marker"
    }

    Copy-Item -LiteralPath (Join-Path $root "LICENSE") -Destination (Join-Path $stagingRoot "LICENSE") -Force
    Copy-Item -LiteralPath (Join-Path $root "THIRD_PARTY_NOTICES.md") -Destination (Join-Path $stagingRoot "THIRD_PARTY_NOTICES.md") -Force
    Copy-Item -LiteralPath $godotCopyright -Destination (Join-Path $stagingRoot "GODOT_COPYRIGHT.txt") -Force

    & $stageExe --headless --quit-after 180 --log-file $smokeLog 2>&1 |
        Tee-Object -FilePath $smokeConsole
    if ($LASTEXITCODE -ne 0) {
        throw "Exported executable process smoke failed with exit code $LASTEXITCODE"
    }
    foreach ($requiredOutput in @($smokeLog, $smokeConsole)) {
        if (-not (Test-Path -LiteralPath $requiredOutput)) {
            throw "Exported executable smoke did not create current-run log: $requiredOutput"
        }
    }
    $smokeText = @(
        (Get-Content -LiteralPath $smokeLog -Raw),
        (Get-Content -LiteralPath $smokeConsole -Raw)
    ) -join "`n"
    if ($smokeText -match 'ERROR:|SCRIPT ERROR|Parse Error|Crash') {
        throw "Exported executable process-smoke log contains a failure marker"
    }

    $hash = (Get-FileHash -LiteralPath $stageExe -Algorithm SHA256).Hash.ToLowerInvariant()
    $stream = [System.IO.File]::OpenRead($stageExe)
    $reader = [System.IO.BinaryReader]::new($stream)
    try {
        if ($stream.Length -lt 64) {
            throw "Exported executable is too small to contain a PE header"
        }
        $stream.Position = 0x3c
        $peOffset = $reader.ReadInt32()
        if ($peOffset -lt 0 -or ($peOffset + 6) -gt $stream.Length) {
            throw "Exported executable contains an invalid PE header offset"
        }
        $stream.Position = $peOffset
        $signature = $reader.ReadUInt32()
        if ($signature -ne 0x00004550) {
            throw ("Expected PE signature 0x00004550, got 0x{0:x8}" -f $signature)
        }
        $machine = $reader.ReadUInt16()
    }
    finally {
        $reader.Dispose()
        $stream.Dispose()
    }
    if ($machine -ne 0x8664) {
        throw ("Expected PE x86_64 machine 0x8664, got 0x{0:x}" -f $machine)
    }

    $publishFiles = @(
        @{ Source = $exportLog; Name = "export.log" },
        @{ Source = $exportConsole; Name = "export-console.log" },
        @{ Source = $smokeLog; Name = "smoke-engine.log" },
        @{ Source = $smokeConsole; Name = "smoke-console.log" },
        @{ Source = (Join-Path $stagingRoot "LICENSE"); Name = "LICENSE" },
        @{ Source = (Join-Path $stagingRoot "THIRD_PARTY_NOTICES.md"); Name = "THIRD_PARTY_NOTICES.md" },
        @{ Source = (Join-Path $stagingRoot "GODOT_COPYRIGHT.txt"); Name = "GODOT_COPYRIGHT.txt" },
        @{ Source = $stageExe; Name = "ROOM_407_THE_LAST_SHIFT.exe" }
    )
    Assert-NoReparsePointPath $root $outputRoot "Windows export output"
    foreach ($publishFile in $publishFiles) {
        $destination = Join-Path $outputRoot $publishFile.Name
        $publishTemp = $destination + ".publishing-" + $runId
        $publishTemps += $publishTemp
        Copy-Item -LiteralPath $publishFile.Source -Destination $publishTemp -Force
        # Same-directory rename keeps the verified file staged until the final
        # replacement; the repository-scoped lock prevents verifier races.
        Move-Item -LiteralPath $publishTemp -Destination $destination -Force
    }

    $outputExe = Join-Path $outputRoot "ROOM_407_THE_LAST_SHIFT.exe"
    $item = Get-Item -LiteralPath $outputExe
    $publishedHash = (Get-FileHash -LiteralPath $outputExe -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($publishedHash -ne $hash -or $item.Length -ne $stageItem.Length) {
        throw "Published Windows executable does not match the verified staging artifact"
    }

    Write-Host "WINDOWS_TEMPLATE_ARCHIVE_SHA256=$archiveHash"
    Write-Host "WINDOWS_TEMPLATE_BINARY_SHA256=$installedTemplateHash"
    Write-Host "GODOT_COPYRIGHT_SHA256=$godotCopyrightHash"
    Write-Host "WINDOWS_EXPORT_SIZE_BYTES=$($item.Length)"
    Write-Host "WINDOWS_EXPORT_SHA256=$publishedHash"
    Write-Host "WINDOWS_EXPORT_PE=x86_64"
    Write-Host "WINDOWS_EXPORTED_PROCESS_SMOKE_OK"
    Write-Host "WINDOWS_EXPORT_VERIFY_OK"
}
finally {
    $env:APPDATA = $oldAppData
    $env:LOCALAPPDATA = $oldLocalAppData
    if (Test-Path -LiteralPath $profile) {
        Assert-NoReparsePointPath $root $profile "Windows export profile cleanup"
        $resolvedTempRoot = (Resolve-Path -LiteralPath $tempRoot).Path.TrimEnd("\")
        $resolvedProfile = (Resolve-Path -LiteralPath $profile).Path.TrimEnd("\")
        $expectedProfilePrefix = $resolvedTempRoot + "\windows-export-"
        if (-not $resolvedProfile.StartsWith($expectedProfilePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove export profile outside repository temp root: $resolvedProfile"
        }
        Remove-Item -LiteralPath $resolvedProfile -Recurse -Force
    }
    if (Test-Path -LiteralPath $stagingRoot) {
        Assert-NoReparsePointPath $root $stagingRoot "Windows export staging cleanup"
        $resolvedStagingParent = (Resolve-Path -LiteralPath $stagingParent).Path.TrimEnd("\")
        $resolvedStagingRoot = (Resolve-Path -LiteralPath $stagingRoot).Path.TrimEnd("\")
        $expectedStagingPrefix = $resolvedStagingParent + "\windows-export-"
        if (-not $resolvedStagingRoot.StartsWith($expectedStagingPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove export staging outside repository artifact root: $resolvedStagingRoot"
        }
        Remove-Item -LiteralPath $resolvedStagingRoot -Recurse -Force
    }
    foreach ($publishTemp in $publishTemps) {
        if (Test-Path -LiteralPath $publishTemp) {
            Remove-Item -LiteralPath $publishTemp -Force
        }
    }
    if ($null -ne $lockStream) {
        $lockStream.Dispose()
    }
    if (Test-Path -LiteralPath $lockPath) {
        Remove-Item -LiteralPath $lockPath -Force
    }
}
