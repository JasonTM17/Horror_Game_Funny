param(
    [string]$Godot = "D:\Tools\Godot-4.7.1\Godot_v4.7.1-stable_win64_console.exe",
    [string]$Preset = "Windows Desktop x86_64",
    [string]$OutputDirectory = ".artifacts\builds\room407-windows-x86_64",
    [string]$TemplateArchive = "D:\Tools\Godot-4.7.1\Godot_v4.7.1-stable_export_templates.tpz",
    [ValidateRange(1, 3600)] [int]$ExportTimeoutSeconds = 300,
    [ValidateRange(1, 3600)] [int]$SmokeTimeoutSeconds = 240
)

$ErrorActionPreference = "Stop"
$expectedArchiveHash = "86409db6200b6f8fd3230989c2d2002851f3dd18acf11d7bdbafddf5a0dd0f72"
$expectedGodotCopyrightHash = "cb1980c88089573bcacd7221d777c689bb8bbd778799f24c27fca0fe5f774d6d"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path.TrimEnd("\")
$artifactRoot = Join-Path $root ".artifacts"
$outputRoot = [System.IO.Path]::GetFullPath((Join-Path $root $OutputDirectory)).TrimEnd("\")
$expectedOutputPrefix = $artifactRoot.TrimEnd("\") + "\"

function Get-UniqueIniKeyMap([string]$SectionText, [string]$Context) {
    $result = [System.Collections.Generic.Dictionary[string,string]]::new([System.StringComparer]::Ordinal)
    $lineNumber = 0
    foreach ($rawLine in [regex]::Split($SectionText, '\r?\n')) {
        $lineNumber += 1
        $line = $rawLine.Trim()
        if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith("#") -or $line.StartsWith(";")) { continue }
        $separator = $line.IndexOf("=")
        if ($separator -le 0) { throw "$Context contains an invalid key/value line at body line $lineNumber" }
        $key = $line.Substring(0,$separator).Trim()
        $value = $line.Substring($separator+1).Trim()
        if ($result.ContainsKey($key)) { throw "$Context contains duplicate key '$key'" }
        $result.Add($key,$value)
    }
    return ,$result
}

function Require-IniValue([System.Collections.Generic.Dictionary[string,string]]$KeyMap,[string]$Key,[string]$ExpectedValue,[string]$Context) {
    if (-not $KeyMap.ContainsKey($Key)) { throw "$Context is missing required key '$Key'" }
    if ($KeyMap[$Key] -cne $ExpectedValue) { throw "$Context requires $Key=$ExpectedValue, got $($KeyMap[$Key])" }
}

function ConvertTo-NativeArgument([string]$Value) {
    if ($Value.Length -gt 0 -and $Value -notmatch '[\s"]') { return $Value }
    $escaped = [regex]::Replace($Value,'(\\*)"','$1$1\"')
    $escaped = [regex]::Replace($escaped,'(\\+)$','$1$1')
    return '"'+$escaped+'"'
}

function Merge-ProcessOutput([string]$StandardOutputPath,[string]$StandardErrorPath,[string]$DestinationPath) {
    $parts = [System.Collections.Generic.List[string]]::new()
    foreach($path in @($StandardOutputPath,$StandardErrorPath)) {
        if(Test-Path $path) { $value=[System.IO.File]::ReadAllText($path); if(-not [string]::IsNullOrWhiteSpace($value)){[void]$parts.Add($value.TrimEnd())} }
    }
    $combined=[string]::Join([Environment]::NewLine,$parts)
    [System.IO.File]::WriteAllText($DestinationPath,$combined,[System.Text.UTF8Encoding]::new($false))
    return $combined
}

function Get-ProcessTreeIds([int]$RootProcessId) {
    $processes=@(Get-CimInstance Win32_Process | Select-Object ProcessId,ParentProcessId)
    $ids=[System.Collections.Generic.List[int]]::new(); $queue=[System.Collections.Generic.Queue[int]]::new(); $queue.Enqueue($RootProcessId)
    while($queue.Count -gt 0){$parentId=$queue.Dequeue();foreach($child in $processes|Where-Object ParentProcessId -eq $parentId){$childId=[int]$child.ProcessId;if(-not $ids.Contains($childId)){[void]$ids.Add($childId);$queue.Enqueue($childId)}}}
    [void]$ids.Add($RootProcessId); return ,$ids.ToArray()
}

function Stop-ProcessTree([System.Diagnostics.Process]$Process) {
    if($Process.HasExited){return}; $treeIds=@(Get-ProcessTreeIds $Process.Id); $taskkill=Join-Path $env:SystemRoot 'System32\taskkill.exe'; $killed=$false
    try{$killer=Start-Process $taskkill -ArgumentList @('/PID',$Process.Id,'/T','/F') -WindowStyle Hidden -PassThru;if($killer.WaitForExit(10000)){$killed=$killer.ExitCode -eq 0}else{$killer.Kill();[void]$killer.WaitForExit(5000)};$killer.Dispose()}catch{$killed=$false}
    if(-not $killed){foreach($processId in ($treeIds|Sort-Object -Descending)){Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue}}
    $deadline=[DateTime]::UtcNow.AddSeconds(10)
    do{$remaining=@($treeIds|Where-Object {Get-Process -Id $_ -ErrorAction SilentlyContinue});if($remaining.Count -eq 0){return};Start-Sleep -Milliseconds 100}while([DateTime]::UtcNow -lt $deadline)
    throw "Failed to terminate process tree; remaining PIDs: $($remaining -join ', ')"
}

function Invoke-ProcessWithTimeout([string]$FilePath,[string[]]$Arguments,[string]$StandardOutputPath,[string]$StandardErrorPath,[int]$TimeoutSeconds,[string]$Context) {
    $nativeArguments=(($Arguments|ForEach-Object {ConvertTo-NativeArgument $_}) -join ' '); $process=$null
    try{
        $process=Start-Process $FilePath -ArgumentList $nativeArguments -WorkingDirectory $root -RedirectStandardOutput $StandardOutputPath -RedirectStandardError $StandardErrorPath -WindowStyle Hidden -PassThru
        if(-not $process.WaitForExit($TimeoutSeconds*1000)){try{Stop-ProcessTree $process}catch{throw "$Context timed out after $TimeoutSeconds seconds; $($_.Exception.Message)"};throw "$Context timed out after $TimeoutSeconds seconds"}
        $process.WaitForExit();$process.Refresh();[int]$exitCode=$process.ExitCode;return $exitCode
    }finally{if($null -ne $process){$process.Dispose()}}
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
$sectionByName=[System.Collections.Hashtable]::new([System.StringComparer]::Ordinal)
foreach($section in $sectionMatches){$sectionName=$section.Groups['name'].Value;if($sectionByName.ContainsKey($sectionName)){throw "Export preset file contains duplicate section [$sectionName]"};$sectionByName.Add($sectionName,$section)}
$presetSections = @()
foreach ($section in $sectionMatches) {
    $sectionName=$section.Groups['name'].Value
    if($sectionName -notmatch '^preset\.\d+$'){continue}
    $sectionKeys=Get-UniqueIniKeyMap $section.Groups['body'].Value "Export preset [$sectionName]"
    if($sectionKeys.ContainsKey('name') -and $sectionKeys['name'] -ceq ('"'+$Preset+'"')){$presetSections += [pscustomobject]@{Match=$section;Keys=$sectionKeys}}
}
if ($presetSections.Count -ne 1) {
    throw "Expected exactly one export preset named '$Preset', got $($presetSections.Count)"
}
$presetSection=$presetSections[0].Match
$presetKeys=$presetSections[0].Keys
$presetSectionName = $presetSection.Groups["name"].Value
$optionsSectionName="$presetSectionName.options"
if(-not $sectionByName.ContainsKey($optionsSectionName)){
    throw "Export preset '$Preset' has no matching options section"
}
$optionsKeys=Get-UniqueIniKeyMap $sectionByName[$optionsSectionName].Groups['body'].Value "Export preset [$optionsSectionName]"
$requiredPresetValues=[ordered]@{'name'=('"'+$Preset+'"');'platform'='"Windows Desktop"';'runnable'='true';'dedicated_server'='false';'custom_features'='""';'export_filter'='"all_resources"';'include_filter'='""';'exclude_filter'='"tests/*,docs/*,plans/*,.artifacts/*,.tmp/*,exports/*,builds/*"';'patches'='PackedStringArray()';'encryption_include_filters'='""';'encryption_exclude_filters'='""';'encrypt_pck'='false';'encrypt_directory'='false';'script_export_mode'='2';'export_path'='".artifacts/builds/room407-windows-x86_64/ROOM_407_THE_LAST_SHIFT.exe"'}
foreach($entry in $requiredPresetValues.GetEnumerator()){Require-IniValue $presetKeys $entry.Key $entry.Value "Export preset '$Preset'"}
$requiredOptionValues=[ordered]@{'custom_template/debug'='""';'custom_template/release'='""';'binary_format/architecture'='"x86_64"';'binary_format/embed_pck'='true';'codesign/enable'='false';'codesign/timestamp'='false';'codesign/timestamp_server_url'='""';'codesign/description'='""';'codesign/custom_options'='PackedStringArray()';'ssh_remote_deploy/enabled'='false';'ssh_remote_deploy/host'='""';'ssh_remote_deploy/extra_args_ssh'='""';'ssh_remote_deploy/extra_args_scp'='""';'ssh_remote_deploy/run_script'='""';'ssh_remote_deploy/cleanup_script'='""'}
foreach($entry in $requiredOptionValues.GetEnumerator()){Require-IniValue $optionsKeys $entry.Key $entry.Value "Export preset '$Preset' options"}
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
$outputParent = Split-Path -Parent $outputRoot
$rollbackRoot = $outputRoot + ".previous"
Assert-NoReparsePointPath $root $artifactRoot "Artifact root"
Assert-NoReparsePointPath $root $outputParent "Windows export parent"
Assert-NoReparsePointPath $root $outputRoot "Windows export output"
Assert-NoReparsePointPath $root $rollbackRoot "Windows export rollback slot"
Assert-NoReparsePointPath $root $tempRoot "Temporary profile root"
New-Item -ItemType Directory -Force -Path $artifactRoot, $outputParent | Out-Null
Assert-NoReparsePointPath $root $artifactRoot "Artifact root"
Assert-NoReparsePointPath $root $outputParent "Windows export parent"
$lockPath = Join-Path $artifactRoot "windows-export.lock"
$lockStream = $null
try {
    $lockStream = [System.IO.FileStream]::new(
        $lockPath,
        [System.IO.FileMode]::OpenOrCreate,
        [System.IO.FileAccess]::ReadWrite,
        [System.IO.FileShare]::None,
        1,
        [System.IO.FileOptions]::DeleteOnClose
    )
}
catch {
    throw "Another Windows export verification is already running for this repository"
}

$runId = [guid]::NewGuid().ToString("N")
$stagingParent = Join-Path $artifactRoot "staging"
$stagingRoot = Join-Path $stagingParent ("windows-export-" + $runId)
$publishRoot = $outputRoot + ".publishing-" + $runId
$failedPublishRoot = $outputRoot + ".failed-" + $runId
$stageExe = Join-Path $stagingRoot "ROOM_407_THE_LAST_SHIFT.exe"
$exportLog = Join-Path $stagingRoot "export.log"
$exportConsole = Join-Path $stagingRoot "export-console.log"
$exportStdout = Join-Path $stagingRoot "export-stdout.log"
$exportStderr = Join-Path $stagingRoot "export-stderr.log"
$smokeLog = Join-Path $stagingRoot "smoke-engine.log"
$smokeConsole = Join-Path $stagingRoot "smoke-console.log"
$smokeStdout = Join-Path $stagingRoot "smoke-stdout.log"
$smokeStderr = Join-Path $stagingRoot "smoke-stderr.log"
$oldAppData = $env:APPDATA
$oldLocalAppData = $env:LOCALAPPDATA
$profile = Join-Path $tempRoot ("windows-export-" + $runId)
$primaryError=$null
$cleanupErrors=[System.Collections.Generic.List[string]]::new()
$verificationResult=$null
$publishActivated=$false
$previousOutputMoved=$false

try {
    Assert-NoReparsePointPath $root $stagingRoot "Windows export staging"
    Assert-NoReparsePointPath $root $publishRoot "Windows export publish staging"
    Assert-NoReparsePointPath $root $profile "Windows export profile"
    $env:APPDATA = Join-Path $profile "AppData\Roaming"
    $env:LOCALAPPDATA = Join-Path $profile "AppData\Local"
    New-Item -ItemType Directory -Force -Path $env:APPDATA, $env:LOCALAPPDATA, $stagingRoot | Out-Null
    Assert-NoReparsePointPath $root $stagingRoot "Windows export staging"
    Assert-NoReparsePointPath $root $profile "Windows export profile"

    $exportStartedUtc = [DateTime]::UtcNow
    $exportExitCode=Invoke-ProcessWithTimeout -FilePath $Godot -Arguments @('--headless','--path',$root,'--export-release',$Preset,$stageExe,'--log-file',$exportLog) -StandardOutputPath $exportStdout -StandardErrorPath $exportStderr -TimeoutSeconds $ExportTimeoutSeconds -Context 'Windows export'
    [void](Merge-ProcessOutput $exportStdout $exportStderr $exportConsole)
    if($exportExitCode -ne 0){throw "Windows export failed with exit code $exportExitCode"}
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

    $smokeExitCode=Invoke-ProcessWithTimeout -FilePath $stageExe -Arguments @('--headless','--quit-after','180','--log-file',$smokeLog) -StandardOutputPath $smokeStdout -StandardErrorPath $smokeStderr -TimeoutSeconds $SmokeTimeoutSeconds -Context 'Exported executable process smoke'
    [void](Merge-ProcessOutput $smokeStdout $smokeStderr $smokeConsole)
    if($smokeExitCode -ne 0){throw "Exported executable process smoke failed with exit code $smokeExitCode"}
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

    New-Item -ItemType Directory -Path $publishRoot | Out-Null
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
    foreach ($publishFile in $publishFiles) {
        Copy-Item -LiteralPath $publishFile.Source -Destination (Join-Path $publishRoot $publishFile.Name) -Force
    }
    $manifest=@("WINDOWS_EXPORT_SHA256=$hash","WINDOWS_EXPORT_SIZE_BYTES=$($stageItem.Length)",'WINDOWS_EXPORT_PE=x86_64','WINDOWS_EXPORTED_PROCESS_SMOKE_OK') -join "`r`n"
    [System.IO.File]::WriteAllText((Join-Path $publishRoot 'VERIFY_COMPLETE.txt'),$manifest+"`r`n",[System.Text.UTF8Encoding]::new($false))
    $publishExe=Join-Path $publishRoot 'ROOM_407_THE_LAST_SHIFT.exe'
    if((Get-FileHash $publishExe -Algorithm SHA256).Hash.ToLowerInvariant() -ne $hash){throw 'Prepared Windows export bundle does not match the verified staging artifact'}
    $env:APPDATA=$oldAppData;$env:LOCALAPPDATA=$oldLocalAppData
    if(Test-Path $profile){Assert-NoReparsePointPath $root $profile 'Windows export profile cleanup';Remove-Item $profile -Recurse -Force}
    if(Test-Path $stagingRoot){Assert-NoReparsePointPath $root $stagingRoot 'Windows export staging cleanup';Remove-Item $stagingRoot -Recurse -Force}
    Assert-NoReparsePointPath $root $outputRoot 'Windows export output activation'
    Assert-NoReparsePointPath $root $rollbackRoot 'Windows export rollback activation'
    Assert-NoReparsePointPath $root $publishRoot 'Windows export publish activation'
    if(Test-Path $rollbackRoot){Remove-Item $rollbackRoot -Recurse -Force}
    if(Test-Path $outputRoot){Move-Item $outputRoot $rollbackRoot;$previousOutputMoved=$true}
    Move-Item $publishRoot $outputRoot;$publishActivated=$true

    $outputExe = Join-Path $outputRoot "ROOM_407_THE_LAST_SHIFT.exe"
    $item = Get-Item -LiteralPath $outputExe
    $publishedHash = (Get-FileHash -LiteralPath $outputExe -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($publishedHash -ne $hash -or $item.Length -ne $stageItem.Length) {
        throw "Published Windows executable does not match the verified staging artifact"
    }
    if(-not (Test-Path (Join-Path $outputRoot 'VERIFY_COMPLETE.txt'))){throw 'Published Windows bundle is missing its completion manifest'}

    $verificationResult=[pscustomobject]@{ArchiveHash=$archiveHash;TemplateHash=$installedTemplateHash;CopyrightHash=$godotCopyrightHash;SizeBytes=$item.Length;ExportHash=$publishedHash}
}
catch{$primaryError=$_}
finally {
    try{$env:APPDATA=$oldAppData;$env:LOCALAPPDATA=$oldLocalAppData}catch{[void]$cleanupErrors.Add("environment restore: $($_.Exception.Message)")}
    foreach($cleanup in @(@{Path=$profile;Label='profile'},@{Path=$stagingRoot;Label='staging'},@{Path=$publishRoot;Label='publish'})){
        try{if(Test-Path $cleanup.Path){Assert-NoReparsePointPath $root $cleanup.Path "Windows export $($cleanup.Label) cleanup";Remove-Item $cleanup.Path -Recurse -Force}}catch{[void]$cleanupErrors.Add("$($cleanup.Label) cleanup: $($_.Exception.Message)")}
    }
    $mustRollback=$null -ne $primaryError -or $cleanupErrors.Count -gt 0
    if($mustRollback -and ($publishActivated -or $previousOutputMoved)){
        try{
            Assert-NoReparsePointPath $root $outputRoot 'Windows export rollback current output';Assert-NoReparsePointPath $root $rollbackRoot 'Windows export rollback previous output';Assert-NoReparsePointPath $root $failedPublishRoot 'Windows export rollback failed output'
            if(Test-Path $failedPublishRoot){Remove-Item $failedPublishRoot -Recurse -Force};if(Test-Path $outputRoot){Move-Item $outputRoot $failedPublishRoot};if($previousOutputMoved -and (Test-Path $rollbackRoot)){Move-Item $rollbackRoot $outputRoot};if(Test-Path $failedPublishRoot){Remove-Item $failedPublishRoot -Recurse -Force};$publishActivated=$false;$previousOutputMoved=$false
        }catch{[void]$cleanupErrors.Add("artifact rollback: $($_.Exception.Message)")}
    }
    try{if($null -ne $lockStream){$lockStream.Dispose()}}catch{[void]$cleanupErrors.Add("lock cleanup: $($_.Exception.Message)")}
    if($cleanupErrors.Count -gt 0 -and $publishActivated){
        try{if(Test-Path $failedPublishRoot){Remove-Item $failedPublishRoot -Recurse -Force};Move-Item $outputRoot $failedPublishRoot;if($previousOutputMoved -and (Test-Path $rollbackRoot)){Move-Item $rollbackRoot $outputRoot};Remove-Item $failedPublishRoot -Recurse -Force;$publishActivated=$false}catch{[void]$cleanupErrors.Add("post-lock artifact rollback: $($_.Exception.Message)")}
    }
}

if($null -ne $primaryError){if($cleanupErrors.Count -gt 0){throw "$($primaryError.Exception.Message); cleanup also failed: $([string]::Join('; ',$cleanupErrors))"};throw $primaryError}
if($cleanupErrors.Count -gt 0){throw "Windows export verification cleanup failed: $([string]::Join('; ',$cleanupErrors))"}
if($null -eq $verificationResult){throw 'Windows export verification ended without a result'}
Write-Host "WINDOWS_TEMPLATE_ARCHIVE_SHA256=$($verificationResult.ArchiveHash)"
Write-Host "WINDOWS_TEMPLATE_BINARY_SHA256=$($verificationResult.TemplateHash)"
Write-Host "GODOT_COPYRIGHT_SHA256=$($verificationResult.CopyrightHash)"
Write-Host "WINDOWS_EXPORT_SIZE_BYTES=$($verificationResult.SizeBytes)"
Write-Host "WINDOWS_EXPORT_SHA256=$($verificationResult.ExportHash)"
Write-Host 'WINDOWS_EXPORT_PE=x86_64'
Write-Host 'WINDOWS_EXPORTED_PROCESS_SMOKE_OK'
Write-Host 'WINDOWS_EXPORT_VERIFY_OK'
