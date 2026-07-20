param(
    [ValidatePattern('^v[0-9]+\.[0-9]+\.[0-9]+$')]
    [string]$Version = "v0.9.0",
    [string]$BundlePath = ".artifacts/builds/room407-windows-x86_64",
    [string]$OutputDirectory = ""
)

# Creates the public Windows ZIP only from the bundle produced by
# verify-windows-export.ps1. The release asset checksum is intentionally adjacent to the
# ZIP rather than inside it: an archive cannot contain a checksum of its own final bytes.
$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $root
$expectedGodotCopyrightHash = "cb1980c88089573bcacd7221d777c689bb8bbd778799f24c27fca0fe5f774d6d"
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
        if (-not (Test-Path -LiteralPath $current)) { continue }
        if (((Get-Item -LiteralPath $current -Force).Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "$Context contains a reparse-point ancestor: $current"
        }
    }
}
$transactionModule = Join-Path $PSScriptRoot "windows-export-transaction.ps1"
if (-not (Test-Path -LiteralPath $transactionModule -PathType Leaf)) {
    throw "Windows export transaction module is missing: $transactionModule"
}
. $transactionModule

if (-not $OutputDirectory) {
    $OutputDirectory = Join-Path $root (".artifacts/release-" + $Version)
}

$bundle = (Resolve-Path -LiteralPath $BundlePath -ErrorAction Stop).Path
$requiredNames = @(
    "ROOM_407_THE_LAST_SHIFT.exe",
    "LICENSE",
    "THIRD_PARTY_NOTICES.md",
    "GODOT_COPYRIGHT.txt"
)
$bundleIdentity = Get-VerifiedBundleIdentity $bundle

$requiredFiles = @{}
foreach ($name in $requiredNames) {
    $path = Join-Path $bundle $name
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Verified export bundle is missing required file: $path"
    }
    if ((Get-Item -LiteralPath $path).Length -le 0) {
        throw "Verified export bundle has an empty required file: $path"
    }
    $requiredFiles[$name] = $path
}

$archiveRoot = "ROOM-407-THE-LAST-SHIFT-" + $Version
$archiveName = "room-407-the-last-shift-windows-x86_64-" + $Version + ".zip"
$checksumName = "room-407-the-last-shift-windows-x86_64-" + $Version + "-SHA256SUMS.txt"
$output = [System.IO.Path]::GetFullPath($OutputDirectory)
if (Test-Path -LiteralPath $output) {
    $remaining = @(Get-ChildItem -LiteralPath $output -Force)
    if ($remaining.Count -ne 0) {
        throw "Release output directory must be empty to prevent stale assets: $output"
    }
} else {
    New-Item -ItemType Directory -Path $output | Out-Null
}

$archive = Join-Path $output $archiveName
$checksum = Join-Path $output $checksumName
$temporaryArchive = Join-Path $output ("." + $archiveName + ".tmp")
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
try {
    $zip = [System.IO.Compression.ZipFile]::Open(
        $temporaryArchive,
        [System.IO.Compression.ZipArchiveMode]::Create
    )
    try {
        foreach ($name in $requiredNames) {
            $entry = $zip.CreateEntry(
                "$archiveRoot/$name",
                [System.IO.Compression.CompressionLevel]::Optimal
            )
            # A fixed timestamp makes identical input files produce stable archive metadata.
            $entry.LastWriteTime = [DateTimeOffset]::new(2026, 7, 20, 0, 0, 0, [TimeSpan]::Zero)
            $input = [System.IO.File]::OpenRead($requiredFiles[$name])
            $destination = $entry.Open()
            try {
                $input.CopyTo($destination)
            } finally {
                $destination.Dispose()
                $input.Dispose()
            }
        }
    } finally {
        $zip.Dispose()
    }

    $expectedEntries = @($requiredNames | ForEach-Object { "$archiveRoot/$_" })
    $readZip = [System.IO.Compression.ZipFile]::OpenRead($temporaryArchive)
    try {
        $actualEntries = @($readZip.Entries | ForEach-Object { $_.FullName } | Sort-Object)
    } finally {
        $readZip.Dispose()
    }
    if (@(Compare-Object -ReferenceObject ($expectedEntries | Sort-Object) -DifferenceObject $actualEntries).Count -ne 0) {
        throw "Release archive inventory did not match the required files."
    }

    Move-Item -LiteralPath $temporaryArchive -Destination $archive
    $hash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
    $record = "$hash *$archiveName`n"
    [System.IO.File]::WriteAllText($checksum, $record, [System.Text.UTF8Encoding]::new($false))
    $records = @([System.IO.File]::ReadAllLines($checksum) | Where-Object { $_ -match '\S' })
    $recordPattern = '^(?<hash>[A-Fa-f0-9]{64}) \*' + [regex]::Escape($archiveName) + '$'
    if ($records.Count -ne 1 -or -not [regex]::IsMatch($records[0], $recordPattern)) {
        throw "Release checksum record is not an exact one-file SHA-256 record."
    }
    if ([regex]::Match($records[0], $recordPattern).Groups["hash"].Value.ToLowerInvariant() -ne $hash) {
        throw "Release checksum record does not match the final ZIP bytes."
    }
} finally {
    if (Test-Path -LiteralPath $temporaryArchive) {
        Remove-Item -LiteralPath $temporaryArchive -Force
    }
}

Write-Host "RELEASE_ARCHIVE_READY"
Write-Host "ARCHIVE=$archive"
Write-Host "CHECKSUM=$checksum"
Write-Host "SHA256=$hash"
Write-Host "SOURCE_BUNDLE_FINGERPRINT=$($bundleIdentity.Fingerprint)"
