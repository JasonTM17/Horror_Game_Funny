param(
    [string]$Godot = "D:\Tools\Godot-4.7.1\Godot_v4.7.1-stable_win64_console.exe",
    [string]$TemplateArchive = "D:\Tools\Godot-4.7.1\Godot_v4.7.1-stable_export_templates.tpz"
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path.TrimEnd('\')
$bundlePayloadNames = @(
    'GODOT_COPYRIGHT.txt', 'LICENSE', 'ROOM_407_THE_LAST_SHIFT.exe',
    'THIRD_PARTY_NOTICES.md', 'export-console.log', 'export.log',
    'smoke-console.log', 'smoke-engine.log'
)
$expectedGodotCopyrightHash = (Get-FileHash (Join-Path $root 'GODOT_COPYRIGHT.txt') -Algorithm SHA256).Hash.ToLowerInvariant()
$runId = [guid]::NewGuid().ToString('N')
$harnessRoot = Join-Path $root ('.tmp\\windows-export-adversarial-' + $runId)

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

function Assert-Throws([scriptblock]$Action, [string]$ExpectedText, [string]$Context) {
    try { & $Action }
    catch {
        if ($_.Exception.Message.IndexOf($ExpectedText, [StringComparison]::Ordinal) -lt 0) {
            throw "$Context failed with unexpected error: $($_.Exception.Message)"
        }
        return
    }
    throw "$Context did not fail"
}

function Assert-NoReparsePointPath([string]$TrustedRoot, [string]$Candidate, [string]$Context) {
    $trustedFull = [IO.Path]::GetFullPath($TrustedRoot).TrimEnd('\')
    $candidateFull = [IO.Path]::GetFullPath($Candidate).TrimEnd('\')
    $prefix = $trustedFull + '\'
    if ($candidateFull -ne $trustedFull -and -not $candidateFull.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "$Context outside trusted root: $candidateFull"
    }
    $relative = if ($candidateFull -eq $trustedFull) { '' } else { $candidateFull.Substring($prefix.Length) }
    $current = $trustedFull
    foreach ($part in $relative.Split(@('\'), [StringSplitOptions]::RemoveEmptyEntries)) {
        $current = Join-Path $current $part
        if (Test-Path -LiteralPath $current) {
            if (((Get-Item -LiteralPath $current -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "$Context has reparse point: $current"
            }
        }
    }
}

. (Join-Path $PSScriptRoot 'windows-export-transaction.ps1')

function New-TestExecutable([string]$Path) {
    $bytes = [byte[]]::new(128)
    $bytes[0] = 0x4d; $bytes[1] = 0x5a
    [BitConverter]::GetBytes([int]64).CopyTo($bytes, 0x3c)
    $bytes[64] = 0x50; $bytes[65] = 0x45
    $bytes[68] = 0x64; $bytes[69] = 0x86
    [IO.File]::WriteAllBytes($Path, $bytes)
}

function New-ValidBundle([string]$Path, [string]$Marker) {
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    foreach ($name in $bundlePayloadNames) {
        $target = Join-Path $Path $name
        if ($name -ceq 'ROOM_407_THE_LAST_SHIFT.exe') { New-TestExecutable $target }
        elseif ($name -ceq 'GODOT_COPYRIGHT.txt') { Copy-Item -LiteralPath (Join-Path $root $name) -Destination $target }
        else { [IO.File]::WriteAllText($target, "$name-$Marker", [Text.UTF8Encoding]::new($false)) }
    }
    $records = @(Get-BundlePayloadRecords $Path)
    $manifest = New-BundleManifestText ([guid]::NewGuid().ToString('N')) ('a' * 64) ('b' * 64) $records
    [IO.File]::WriteAllText((Join-Path $Path 'VERIFY_COMPLETE.txt'), $manifest, [Text.UTF8Encoding]::new($false))
    return Get-VerifiedBundleIdentity $Path
}

function Copy-Directory([string]$Source, [string]$Destination) {
    Copy-Item -LiteralPath $Source -Destination $Destination -Recurse -Force
}

function Invoke-VerifierExpectFailure(
    [string]$VerifierPath,
    [string[]]$Arguments,
    [string]$ExpectedText,
    [string]$Context
) {
    $powershell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $previousPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = & $powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $VerifierPath @Arguments 2>&1 | Out-String
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
    if ($exitCode -eq 0) {
        throw "$Context unexpectedly succeeded"
    }
    if ($output.IndexOf($ExpectedText, [StringComparison]::Ordinal) -lt 0) {
        throw "$Context failed without the expected marker '$ExpectedText': $output"
    }
    return $output
}

function Invoke-JobObjectDescendantProbe {
    if ($null -eq ('Room407ExportJobRun' -as [type])) { Add-Type -Path (Join-Path $PSScriptRoot 'windows-export-job-runner.cs') }
    $started = Join-Path $harnessRoot 'child-started.txt'
    $survived = Join-Path $harnessRoot 'child-survived.txt'
    $script = Join-Path $harnessRoot 'spawn-child.cmd'
    $childPowerShell = "$env:SystemRoot\\System32\\WindowsPowerShell\\v1.0\\powershell.exe"
    $command = "Start-Sleep -Seconds 8; Set-Content -LiteralPath '$survived' -Value survived"
    $scriptText = @"
@echo off
start "" /b "$childPowerShell" -NoProfile -NonInteractive -Command "Set-Content -LiteralPath '$started' -Value started; $command"
exit /b 0
"@
    [IO.File]::WriteAllText($script, $scriptText, [Text.ASCIIEncoding]::new())
    $stdout = Join-Path $harnessRoot 'job-stdout.log'
    $stderr = Join-Path $harnessRoot 'job-stderr.log'
    $commandLine = '"' + $env:ComSpec + '" /d /c "' + $script + '"'
    $run = [Room407ExportJobRun]::Launch($env:ComSpec, $commandLine, $harnessRoot, $stdout, $stderr)
    try {
        Assert-True $run.WaitForExit(5000) 'Job probe root process did not exit'
        # A freshly started PowerShell child can take several seconds to load on
        # a busy Windows host. Give the probe a bounded startup window before
        # treating it as a Job Object failure; the later assertion still proves
        # that the descendant is terminated rather than merely delayed.
        $deadline = [DateTime]::UtcNow.AddSeconds(8)
        while (-not (Test-Path -LiteralPath $started) -and [DateTime]::UtcNow -lt $deadline) { Start-Sleep -Milliseconds 50 }
        Assert-True (Test-Path -LiteralPath $started) 'Job probe did not prove that the child process started'
        $run.EnsureNoDescendants(10000)
    }
    finally {
        # On an assertion failure the child can still hold the harness as its
        # working directory. Terminate and drain the Job before disposing its
        # kill-on-close handle so the outer cleanup can remove the fixture.
        try { $run.TerminateTreeAndWait(10000) }
        finally { $run.Dispose() }
    }
    Start-Sleep -Seconds 9
    Assert-True (-not (Test-Path -LiteralPath $survived)) 'Job Object allowed a root-exit descendant to survive'
    Write-Host 'WINDOWS_JOB_ROOT_EXIT_GRANDCHILD_OK'
}

function Invoke-ManifestAndRecoveryProbe {
    $valid = Join-Path $harnessRoot 'valid'
    $validIdentity = New-ValidBundle $valid 'valid'
    Assert-True ((Get-VerifiedBundleIdentity $valid).Fingerprint -ceq $validIdentity.Fingerprint) 'Valid V1 bundle did not verify'

    $bom = Join-Path $harnessRoot 'manifest-bom'; Copy-Directory $valid $bom
    $bomBytes = [byte[]](0xef,0xbb,0xbf) + [IO.File]::ReadAllBytes((Join-Path $bom 'VERIFY_COMPLETE.txt'))
    [IO.File]::WriteAllBytes((Join-Path $bom 'VERIFY_COMPLETE.txt'), $bomBytes)
    Assert-Throws { Get-VerifiedBundleIdentity $bom } 'neither canonical V1' 'BOM manifest rejection'

    $extra = Join-Path $harnessRoot 'manifest-extra'; Copy-Directory $valid $extra
    Add-Content -LiteralPath (Join-Path $extra 'VERIFY_COMPLETE.txt') -Value 'EXTRA=1' -NoNewline
    Assert-Throws { Get-VerifiedBundleIdentity $extra } 'non-canonical line count' 'Extra manifest line rejection'

    $hash = Join-Path $harnessRoot 'manifest-hash'; Copy-Directory $valid $hash
    $text = [IO.File]::ReadAllText((Join-Path $hash 'VERIFY_COMPLETE.txt'))
    [IO.File]::WriteAllText((Join-Path $hash 'VERIFY_COMPLETE.txt'), $text.Replace('a' * 64, 'c' * 64), [Text.UTF8Encoding]::new($false))
    Assert-Throws { Get-VerifiedBundleIdentity $hash } 'does not exactly bind' 'Dependency hash tamper rejection'

    $output = Join-Path $harnessRoot 'output'
    $previous = $output + '.previous'
    $quarantine = $output + '.recovery'
    Copy-Directory $valid $previous
    $recovered = Recover-PreviousWindowsExport $output $previous $quarantine
    Assert-True ((Get-VerifiedBundleIdentity $output).Fingerprint -ceq $validIdentity.Fingerprint) 'Missing-output recovery did not restore verified rollback'
    Assert-True (-not (Test-Path -LiteralPath $previous)) 'Missing-output recovery retained stale rollback slot'

    Remove-TrustedDirectoryTree $output 'Recovery fixture reset'
    New-Item -ItemType Directory -Path $output | Out-Null
    [IO.File]::WriteAllText((Join-Path $output 'corrupt.txt'), 'bad')
    Copy-Directory $valid $previous
    [void](Recover-PreviousWindowsExport $output $previous $quarantine)
    Assert-True ((Get-VerifiedBundleIdentity $output).Fingerprint -ceq $validIdentity.Fingerprint) 'Invalid-output recovery did not restore verified rollback'
    Assert-True (-not (Test-Path -LiteralPath $quarantine)) 'Invalid-output recovery retained quarantine'

    Remove-TrustedDirectoryTree $output 'Recovery fixture reset'
    New-Item -ItemType Directory -Path $previous -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $previous 'corrupt.txt'), 'bad')
    Assert-Throws { Recover-PreviousWindowsExport $output $previous $quarantine } 'rollback is invalid' 'Invalid rollback fail-closed'
    Write-Host 'WINDOWS_EXPORT_MANIFEST_AND_RECOVERY_ADVERSARIAL_OK'
}

function Invoke-SourceParserProbe {
    $text = Get-Content -LiteralPath (Join-Path $root 'export_presets.cfg') -Raw
    Assert-True ($text -match '(?ms)^\[preset\.0\.options\].*?^custom_template/release=""\s*$') 'Verifier fixture lacks an empty release custom-template contract'
    Assert-True ($text -match '(?ms)^\[preset\.0\.options\].*?^custom_template/debug=""\s*$') 'Verifier fixture lacks an empty debug custom-template contract'
    $sections = [regex]::Matches($text, '(?m)^\[(?<name>[^\]\r\n]+)\]')
    $names = @($sections | ForEach-Object { $_.Groups['name'].Value })
    Assert-True (($names | Select-Object -Unique).Count -eq $names.Count) 'Export preset fixture contains duplicate sections before adversarial mutation'

    $fixtureRoot = Join-Path $harnessRoot 'source-parser-fixture'
    $fixtureTests = Join-Path $fixtureRoot 'tests'
    New-Item -ItemType Directory -Path $fixtureTests -Force | Out-Null
    foreach ($name in @('verify-windows-export.ps1', 'windows-export-transaction.ps1', 'windows-export-job-runner.cs')) {
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination (Join-Path $fixtureTests $name)
    }
    foreach ($name in @('LICENSE', 'THIRD_PARTY_NOTICES.md', 'GODOT_COPYRIGHT.txt')) {
        Copy-Item -LiteralPath (Join-Path $root $name) -Destination (Join-Path $fixtureRoot $name)
    }

    function Invoke-InvalidPreset([string]$Name, [string]$PresetText, [string]$ExpectedError) {
        [IO.File]::WriteAllText((Join-Path $fixtureRoot 'export_presets.cfg'), $PresetText, [Text.UTF8Encoding]::new($false))
        [void](Invoke-VerifierExpectFailure (Join-Path $fixtureTests 'verify-windows-export.ps1') @(
            '-Godot', $Godot,
            '-TemplateArchive', $TemplateArchive
        ) $ExpectedError "$Name mutation")
    }

    Invoke-InvalidPreset 'Duplicate section' ($text + "`r`n[preset.0]`r`n") 'duplicate section [preset.0]'
    $duplicateKey = [regex]::Replace($text, '(?m)^runnable=true$', "runnable=true`r`nrunnable=true", 1)
    Assert-True ($duplicateKey -cne $text) 'Could not construct duplicate-key export preset fixture'
    Invoke-InvalidPreset 'Duplicate key' $duplicateKey "contains duplicate key 'runnable'"
    $customTemplate = $text.Replace('custom_template/release=""', 'custom_template/release="C:\\evil.exe"')
    Assert-True ($customTemplate -cne $text) 'Could not construct custom-template export preset fixture'
    Invoke-InvalidPreset 'Custom template' $customTemplate 'requires custom_template/release=""'

    [void](Invoke-VerifierExpectFailure (Join-Path $PSScriptRoot 'verify-windows-export.ps1') @(
        '-Godot', $Godot,
        '-TemplateArchive', $TemplateArchive,
        '-OutputDirectory', '..\windows-export-outside-probe'
    ) 'Refusing to export outside the repository .artifacts directory' 'Outside-output mutation')
    Write-Host 'WINDOWS_EXPORT_PARSER_ADVERSARIAL_OK'
}

function Invoke-TransactionPreservationProbe {
    $verifier = Join-Path $PSScriptRoot 'verify-windows-export.ps1'
    $output = Join-Path $root '.artifacts\builds\room407-windows-x86_64'
    $previous = $output + '.previous'
    $outputBefore = Get-VerifiedBundleIdentity $output
    $previousBefore = Get-VerifiedBundleIdentity $previous

    [void](Invoke-VerifierExpectFailure $verifier @(
        '-Godot', $Godot,
        '-TemplateArchive', $TemplateArchive,
        '-ExportTimeoutSeconds', '1',
        '-SmokeTimeoutSeconds', '1'
    ) 'timed out after 1 seconds' 'Timeout rollback preservation')

    $outputAfterTimeout = Get-VerifiedBundleIdentity $output
    $previousAfterTimeout = Get-VerifiedBundleIdentity $previous
    Assert-True ($outputAfterTimeout.Fingerprint -ceq $outputBefore.Fingerprint) 'Timeout changed the active verified bundle'
    Assert-True ($previousAfterTimeout.Fingerprint -ceq $previousBefore.Fingerprint) 'Timeout changed the verified rollback bundle'
    Assert-True (Test-Path -LiteralPath $harnessRoot -PathType Container) 'Verifier stale cleanup deleted the adversarial harness namespace'

    $lockPath = Join-Path $root '.artifacts\windows-export.lock'
    $lockStream = $null
    try {
        $lockStream = [IO.FileStream]::new(
            $lockPath,
            [IO.FileMode]::OpenOrCreate,
            [IO.FileAccess]::ReadWrite,
            [IO.FileShare]::None
        )
        [void](Invoke-VerifierExpectFailure $verifier @(
            '-Godot', $Godot,
            '-TemplateArchive', $TemplateArchive
        ) 'Another Windows export verification is already running' 'Exclusive-lock rejection')
    }
    finally {
        if ($null -ne $lockStream) { $lockStream.Dispose() }
        if (Test-Path -LiteralPath $lockPath) { Remove-Item -LiteralPath $lockPath -Force }
    }

    $outputAfterLock = Get-VerifiedBundleIdentity $output
    $previousAfterLock = Get-VerifiedBundleIdentity $previous
    Assert-True ($outputAfterLock.Fingerprint -ceq $outputBefore.Fingerprint) 'Lock rejection changed the active verified bundle'
    Assert-True ($previousAfterLock.Fingerprint -ceq $previousBefore.Fingerprint) 'Lock rejection changed the verified rollback bundle'

    $stagingLeaks = @(Get-ChildItem -LiteralPath (Join-Path $root '.artifacts\staging') -Directory -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like 'windows-export-stage-*' })
    $profileLeaks = @(Get-ChildItem -LiteralPath (Join-Path $root '.tmp') -Directory -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like 'windows-export-profile-*' })
    Assert-True ($stagingLeaks.Count -eq 0) 'Timeout/lock probe left a verifier staging directory'
    Assert-True ($profileLeaks.Count -eq 0) 'Timeout/lock probe left a verifier profile directory'
    Write-Host 'WINDOWS_EXPORT_TIMEOUT_LOCK_PRESERVATION_OK'
}

try {
    New-Item -ItemType Directory -Path $harnessRoot -Force | Out-Null
    Invoke-JobObjectDescendantProbe
    Invoke-ManifestAndRecoveryProbe
    Invoke-SourceParserProbe
    Invoke-TransactionPreservationProbe
    Write-Host 'WINDOWS_EXPORT_ADVERSARIAL_OK'
}
finally {
    if (Test-Path -LiteralPath $harnessRoot) { Remove-TrustedDirectoryTree $harnessRoot 'Adversarial harness cleanup' }
}
