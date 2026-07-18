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
$tempRoot = Join-Path $root ".tmp"
$outputRoot = [System.IO.Path]::GetFullPath((Join-Path $root $OutputDirectory)).TrimEnd("\")
$expectedOutputPrefix = $artifactRoot.TrimEnd("\") + "\"
$bundlePayloadNames = @(
    "GODOT_COPYRIGHT.txt",
    "LICENSE",
    "ROOM_407_THE_LAST_SHIFT.exe",
    "THIRD_PARTY_NOTICES.md",
    "export-console.log",
    "export.log",
    "smoke-console.log",
    "smoke-engine.log"
)

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

if ($null -eq ("Room407ExportJobRun" -as [type])) {
    $jobRunnerSource = Join-Path $PSScriptRoot "windows-export-job-runner.cs"
    if (-not (Test-Path -LiteralPath $jobRunnerSource -PathType Leaf)) {
        throw "Windows export Job Object runner source is missing: $jobRunnerSource"
    }
    Add-Type -Path $jobRunnerSource
}

function Invoke-ProcessWithTimeout([string]$FilePath,[string[]]$Arguments,[string]$StandardOutputPath,[string]$StandardErrorPath,[int]$TimeoutSeconds,[string]$Context) {
    $nativeArguments=(($Arguments|ForEach-Object {ConvertTo-NativeArgument $_}) -join ' ')
    $commandLine=ConvertTo-NativeArgument $FilePath
    if(-not [string]::IsNullOrWhiteSpace($nativeArguments)){$commandLine+=' '+$nativeArguments}
    $run=$null
    $processError=$null
    $processResult=$null
    try{
        $run=[Room407ExportJobRun]::Launch($FilePath,$commandLine,$root,$StandardOutputPath,$StandardErrorPath)
        if(-not $run.WaitForExit($TimeoutSeconds*1000)){
            try{$run.TerminateTreeAndWait(10000)}catch{throw "$Context timed out after $TimeoutSeconds seconds and process-tree shutdown failed: $($_.Exception.Message)"}
            throw "$Context timed out after $TimeoutSeconds seconds"
        }
        $processResult=[int]$run.GetExitCode()
        $run.EnsureNoDescendants(10000)
    }catch{$processError=$_}
    finally{
        if($null -ne $run){
            try{$run.EnsureNoDescendants(10000)}catch{if($null -eq $processError){$processError=$_}else{$processError=[System.Exception]::new("$($processError.Exception.Message); process-tree cleanup also failed: $($_.Exception.Message)",$processError.Exception)}}
            $run.Dispose()
        }
    }
    if($null -ne $processError){throw $processError}
    return [int]$processResult
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

$transactionModule = Join-Path $PSScriptRoot "windows-export-transaction.ps1"
if (-not (Test-Path -LiteralPath $transactionModule -PathType Leaf)) {
    throw "Windows export transaction module is missing: $transactionModule"
}
. $transactionModule

if (-not $outputRoot.StartsWith($expectedOutputPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to export outside the repository .artifacts directory: $outputRoot"
}
if (-not (Test-Path -LiteralPath $Godot)) {
    throw "Godot executable not found: $Godot"
}
if (-not (Test-Path -LiteralPath $TemplateArchive)) {
    throw "Official Godot export-template archive not found: $TemplateArchive"
}

Assert-NoReparsePointPath $root $tempRoot "Temporary profile root"
New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null
Assert-NoReparsePointPath $root $tempRoot "Temporary profile root"
$versionRunId = [guid]::NewGuid().ToString("N")
$versionStdout = Join-Path $tempRoot ("godot-version-"+$versionRunId+"-stdout.log")
$versionStderr = Join-Path $tempRoot ("godot-version-"+$versionRunId+"-stderr.log")
$versionConsole = Join-Path $tempRoot ("godot-version-"+$versionRunId+"-console.log")
try {
    $versionExitCode = Invoke-ProcessWithTimeout -FilePath $Godot -Arguments @('--headless','--version') -StandardOutputPath $versionStdout -StandardErrorPath $versionStderr -TimeoutSeconds 30 -Context 'Godot version preflight'
    $versionText = Merge-ProcessOutput $versionStdout $versionStderr $versionConsole
    if ($versionExitCode -ne 0) { throw "Godot version preflight failed with exit code $versionExitCode" }
    $versionLine = @([regex]::Split($versionText,'\r?\n') | Where-Object {-not [string]::IsNullOrWhiteSpace($_)} | Select-Object -First 1)
    if ($versionLine.Count -ne 1) { throw "Godot version preflight returned no version line" }
    $version = $versionLine[0].Trim()
}
finally {
    foreach ($versionPath in @($versionStdout,$versionStderr,$versionConsole)) {
        if (Test-Path -LiteralPath $versionPath) {
            Assert-NoReparsePointPath $root $versionPath "Godot version preflight cleanup"
            Remove-Item -LiteralPath $versionPath -Force
        }
    }
}
if (-not $version.StartsWith("4.7.1.stable.official")) {
    throw "Expected Godot 4.7.1 standard, got: $version"
}

$presetPath = Join-Path $root "export_presets.cfg"
$presetText = Get-Content -LiteralPath $presetPath -Raw
$presetHash = (Get-FileHash -LiteralPath $presetPath -Algorithm SHA256).Hash.ToLowerInvariant()
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
$stagingRoot = Join-Path $stagingParent ("windows-export-stage-" + $runId)
$publishRoot = $outputRoot + ".publishing-" + $runId
$failedPublishRoot = $outputRoot + ".failed-" + $runId
$recoveryQuarantine = $outputRoot + ".recovery-" + $runId
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
$profile = Join-Path $tempRoot ("windows-export-profile-" + $runId)
$primaryError=$null
$cleanupErrors=[System.Collections.Generic.List[string]]::new()
$verificationResult=$null
$publishActivated=$false
$previousOutputMoved=$false
$previousBundleIdentity=$null
$newBundleIdentity=$null

try {
    $previousBundleIdentity = Recover-PreviousWindowsExport $outputRoot $rollbackRoot $recoveryQuarantine
    $outputLeaf = Split-Path -Leaf $outputRoot
    Remove-StaleVerifierDirectories $outputParent ($outputLeaf+".publishing-") "Windows export stale publish cleanup"
    Remove-StaleVerifierDirectories $outputParent ($outputLeaf+".failed-") "Windows export stale rollback cleanup"
    Remove-StaleVerifierDirectories $outputParent ($outputLeaf+".recovery-") "Windows export stale recovery cleanup"
    Remove-StaleVerifierDirectories $stagingParent "windows-export-stage-" "Windows export stale staging cleanup"
    Remove-StaleVerifierDirectories $tempRoot "windows-export-profile-" "Windows export stale profile cleanup"
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
    $machine = Get-PeMachine $stageExe
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
        $publishDestination = Join-Path $publishRoot $publishFile.Name
        Copy-Item -LiteralPath $publishFile.Source -Destination $publishDestination -Force
        $sourceItem = Get-Item -LiteralPath $publishFile.Source
        $destinationItem = Get-Item -LiteralPath $publishDestination
        if ($sourceItem.Length -ne $destinationItem.Length -or
            (Get-FileHash -LiteralPath $publishFile.Source -Algorithm SHA256).Hash -cne
            (Get-FileHash -LiteralPath $publishDestination -Algorithm SHA256).Hash) {
            throw "Prepared Windows export payload copy does not match its verified source: $($publishFile.Name)"
        }
    }

    $publishPayloadRecords = @(Get-BundlePayloadRecords $publishRoot)
    $publishExeRecord = $publishPayloadRecords | Where-Object Name -ceq "ROOM_407_THE_LAST_SHIFT.exe"
    if ($publishExeRecord.Hash -cne $hash -or $publishExeRecord.Size -ne $stageItem.Length -or (Get-PeMachine $publishExeRecord.Path) -ne 0x8664) {
        throw "Prepared Windows export executable does not match the verified staging artifact"
    }
    $manifestText = New-BundleManifestText $runId $presetHash $installedTemplateHash $publishPayloadRecords
    $manifestTemporaryPath = Join-Path $publishRoot "VERIFY_COMPLETE.txt.tmp"
    $manifestPath = Join-Path $publishRoot "VERIFY_COMPLETE.txt"
    [System.IO.File]::WriteAllText($manifestTemporaryPath,$manifestText,[System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::Move($manifestTemporaryPath,$manifestPath)
    $newBundleIdentity = Get-VerifiedBundleIdentity $publishRoot
    if ($newBundleIdentity.ExportHash -cne $hash -or $newBundleIdentity.SizeBytes -ne $stageItem.Length) {
        throw "Prepared Windows export bundle identity does not match the staged executable"
    }

    $env:APPDATA=$oldAppData;$env:LOCALAPPDATA=$oldLocalAppData
    if(Test-Path -LiteralPath $profile){Remove-TrustedDirectoryTree $profile 'Windows export profile cleanup'}
    if(Test-Path -LiteralPath $stagingRoot){Remove-TrustedDirectoryTree $stagingRoot 'Windows export staging cleanup'}
    Assert-NoReparsePointPath $root $outputRoot 'Windows export output activation'
    Assert-NoReparsePointPath $root $rollbackRoot 'Windows export rollback activation'
    Assert-NoReparsePointPath $root $publishRoot 'Windows export publish activation'
    $activationOutputState = Get-BundleState $outputRoot
    if ($null -eq $previousBundleIdentity) {
        if ($activationOutputState.Exists) { throw "Windows export output appeared unexpectedly before initial activation" }
    }
    elseif ($null -eq $activationOutputState.Identity -or $activationOutputState.Identity.Fingerprint -cne $previousBundleIdentity.Fingerprint) {
        throw "Windows export output changed after preflight recovery and before activation"
    }
    if(Test-Path -LiteralPath $rollbackRoot){
        if($null -eq $previousBundleIdentity){throw "Initial Windows export unexpectedly has a rollback slot"}
        Remove-TrustedDirectoryTree $rollbackRoot 'Windows export obsolete rollback cleanup'
    }
    if(Test-Path -LiteralPath $outputRoot){
        Move-TrustedDirectory $outputRoot $rollbackRoot 'Windows export previous bundle staging'
        $previousOutputMoved=$true
    }
    Move-TrustedDirectory $publishRoot $outputRoot 'Windows export activation'
    $publishActivated=$true

    $publishedIdentity = Get-VerifiedBundleIdentity $outputRoot
    if ($publishedIdentity.Fingerprint -cne $newBundleIdentity.Fingerprint) {
        throw "Published Windows bundle does not exactly match the prepared bundle identity"
    }

    $verificationResult=[pscustomobject]@{ArchiveHash=$archiveHash;TemplateHash=$installedTemplateHash;CopyrightHash=$godotCopyrightHash;SizeBytes=$publishedIdentity.SizeBytes;ExportHash=$publishedIdentity.ExportHash;BundleId=$publishedIdentity.BundleId}
}
catch{$primaryError=$_}
finally {
    try{$env:APPDATA=$oldAppData;$env:LOCALAPPDATA=$oldLocalAppData}catch{[void]$cleanupErrors.Add("environment restore: $($_.Exception.Message)")}
    foreach($cleanup in @(@{Path=$profile;Label='profile'},@{Path=$stagingRoot;Label='staging'},@{Path=$publishRoot;Label='publish'})){
        try{if(Test-Path -LiteralPath $cleanup.Path){Remove-TrustedDirectoryTree $cleanup.Path "Windows export $($cleanup.Label) cleanup"}}catch{[void]$cleanupErrors.Add("$($cleanup.Label) cleanup: $($_.Exception.Message)")}
    }
    $mustRollback=$null -ne $primaryError -or $cleanupErrors.Count -gt 0
    if($mustRollback -and ($publishActivated -or $previousOutputMoved)){
        try{
            Restore-PreviousWindowsExportBundle $outputRoot $rollbackRoot $failedPublishRoot $previousBundleIdentity $newBundleIdentity ([ref]$publishActivated) ([ref]$previousOutputMoved)
        }catch{[void]$cleanupErrors.Add("artifact rollback: $($_.Exception.Message)")}
    }
    try{if($null -ne $lockStream){$lockStream.Dispose()}}catch{[void]$cleanupErrors.Add("lock cleanup: $($_.Exception.Message)")}
}

if($null -ne $primaryError){if($cleanupErrors.Count -gt 0){throw "$($primaryError.Exception.Message); cleanup also failed: $([string]::Join('; ',$cleanupErrors))"};throw $primaryError}
if($cleanupErrors.Count -gt 0){throw "Windows export verification cleanup failed: $([string]::Join('; ',$cleanupErrors))"}
if($null -eq $verificationResult){throw 'Windows export verification ended without a result'}
Write-Host "WINDOWS_TEMPLATE_ARCHIVE_SHA256=$($verificationResult.ArchiveHash)"
Write-Host "WINDOWS_TEMPLATE_BINARY_SHA256=$($verificationResult.TemplateHash)"
Write-Host "GODOT_COPYRIGHT_SHA256=$($verificationResult.CopyrightHash)"
Write-Host "WINDOWS_EXPORT_SIZE_BYTES=$($verificationResult.SizeBytes)"
Write-Host "WINDOWS_EXPORT_SHA256=$($verificationResult.ExportHash)"
Write-Host "WINDOWS_EXPORT_BUNDLE_SHA256=$($verificationResult.BundleId)"
Write-Host 'WINDOWS_EXPORT_PE=x86_64'
Write-Host 'WINDOWS_EXPORTED_PROCESS_SMOKE_OK'
Write-Host 'WINDOWS_EXPORT_VERIFY_OK'
