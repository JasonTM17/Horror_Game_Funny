param(
    [string]$BundlePath = ".artifacts/builds/room407-windows-x86_64"
)

# Regression coverage for the release preparer. It does not launch the game: it validates
# archive layout/checksum and proves a payload change is rejected by the export manifest.
$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $root
$preparer = Join-Path $PSScriptRoot "prepare-windows-release.ps1"
if (-not (Test-Path -LiteralPath $preparer -PathType Leaf)) {
    throw "Release preparer is missing: $preparer"
}
$bundle = (Resolve-Path -LiteralPath $BundlePath -ErrorAction Stop).Path
$testRoot = Join-Path $root (".artifacts/verify-windows-release-packaging-" + [guid]::NewGuid().ToString("N"))
$artifactRoot = [System.IO.Path]::GetFullPath((Join-Path $root ".artifacts")).TrimEnd("\") + "\"

function Assert-TestRoot([string]$Path) {
    $full = [System.IO.Path]::GetFullPath($Path).TrimEnd("\")
    if (-not $full.StartsWith($artifactRoot + "verify-windows-release-packaging-", [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove a path outside this test's artifact root: $full"
    }
}

try {
    New-Item -ItemType Directory -Path $testRoot | Out-Null
    $output = Join-Path $testRoot "prepared"
    & $preparer -Version v0.9.0 -BundlePath $bundle -OutputDirectory $output

    $archiveName = "room-407-the-last-shift-windows-x86_64-v0.9.0.zip"
    $checksumName = "room-407-the-last-shift-windows-x86_64-v0.9.0-SHA256SUMS.txt"
    $archive = Join-Path $output $archiveName
    $checksum = Join-Path $output $checksumName
    foreach ($path in @($archive, $checksum)) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Preparer did not create required release asset: $path"
        }
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $expectedEntries = @(
        "ROOM-407-THE-LAST-SHIFT-v0.9.0/ROOM_407_THE_LAST_SHIFT.exe",
        "ROOM-407-THE-LAST-SHIFT-v0.9.0/LICENSE",
        "ROOM-407-THE-LAST-SHIFT-v0.9.0/THIRD_PARTY_NOTICES.md",
        "ROOM-407-THE-LAST-SHIFT-v0.9.0/GODOT_COPYRIGHT.txt"
    ) | Sort-Object
    $zip = [System.IO.Compression.ZipFile]::OpenRead($archive)
    try {
        $actualEntries = @($zip.Entries | ForEach-Object { $_.FullName } | Sort-Object)
    } finally {
        $zip.Dispose()
    }
    if (@(Compare-Object -ReferenceObject $expectedEntries -DifferenceObject $actualEntries).Count -ne 0) {
        throw "Prepared release archive has an unexpected inventory."
    }

    $record = @([System.IO.File]::ReadAllLines($checksum) | Where-Object { $_ -match '\S' })
    $pattern = '^(?<hash>[A-Fa-f0-9]{64}) \*' + [regex]::Escape($archiveName) + '$'
    if ($record.Count -ne 1 -or -not [regex]::IsMatch($record[0], $pattern)) {
        throw "Prepared release checksum is not an exact one-file record."
    }
    $actualHash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
    if ([regex]::Match($record[0], $pattern).Groups["hash"].Value.ToLowerInvariant() -ne $actualHash) {
        throw "Prepared release checksum does not match final ZIP bytes."
    }

    $staleOutputWasAccepted = $false
    try {
        & $preparer -Version v0.9.0 -BundlePath $bundle -OutputDirectory $output
        $staleOutputWasAccepted = $true
    } catch {
        # A populated output directory is intentionally a hard stop.
    }
    if ($staleOutputWasAccepted) {
        throw "Release preparer accepted an existing output directory."
    }

    $tamperedBundle = Join-Path $testRoot "tampered-bundle"
    Copy-Item -LiteralPath $bundle -Destination $tamperedBundle -Recurse
    $tamperedExe = Join-Path $tamperedBundle "ROOM_407_THE_LAST_SHIFT.exe"
    $stream = [System.IO.File]::Open($tamperedExe, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
    try {
        if ($stream.Length -le 1024) { throw "Verified export executable is too short for tamper regression." }
        $stream.Position = 1024
        $original = $stream.ReadByte()
        $stream.Position = 1024
        $stream.WriteByte([byte]($original -bxor 0x01))
    } finally {
        $stream.Dispose()
    }
    $tamperedBundleWasAccepted = $false
    try {
        & $preparer -Version v0.9.0 -BundlePath $tamperedBundle -OutputDirectory (Join-Path $testRoot "tampered-output")
        $tamperedBundleWasAccepted = $true
    } catch {
        # The V1 completion manifest must bind every payload hash.
    }
    if ($tamperedBundleWasAccepted) {
        throw "Release preparer accepted a payload that no longer matches VERIFY_COMPLETE.txt."
    }
    Write-Host "WINDOWS_RELEASE_PACKAGING_VERIFY_OK"
}
finally {
    if (Test-Path -LiteralPath $testRoot) {
        Assert-TestRoot $testRoot
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}
