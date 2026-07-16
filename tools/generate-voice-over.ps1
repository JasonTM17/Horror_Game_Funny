param(
    [string]$PiperPython = "",
    [string]$PiperModel = "",
    [string]$Ffmpeg = "",
    [string]$Ffprobe = "",
    [string]$Manifest = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not $PiperPython) {
    $PiperPython = Join-Path $repoRoot ".tmp\voice-tools\Scripts\python.exe"
}
if (-not $PiperModel) {
    $PiperModel = Join-Path $repoRoot ".tmp\voice-models\en_US-kristin-medium.onnx"
}
if (-not $Manifest) {
    $Manifest = Join-Path $repoRoot "assets\audio\voice-over\voice-over-manifest.json"
}
if (-not $Ffmpeg) {
    $ffmpegCommand = Get-Command ffmpeg -ErrorAction SilentlyContinue
    if ($ffmpegCommand) {
        $Ffmpeg = $ffmpegCommand.Source
    }
}
if (-not $Ffprobe) {
    $ffprobeCommand = Get-Command ffprobe -ErrorAction SilentlyContinue
    if ($ffprobeCommand) {
        $Ffprobe = $ffprobeCommand.Source
    }
}

$modelConfig = $PiperModel + ".json"
foreach ($requiredPath in @($PiperPython, $PiperModel, $modelConfig, $Ffmpeg, $Ffprobe, $Manifest)) {
    if (-not $requiredPath -or -not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Required voice generation dependency not found: $requiredPath"
    }
}

$expectedPiperVersion = "1.4.2"
$piperVersionOutput = (& $PiperPython -c `
    "from importlib.metadata import version; print(version('piper-tts'))" 2>&1 | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $piperVersionOutput -ne $expectedPiperVersion) {
    throw "Expected piper-tts $expectedPiperVersion, found: $piperVersionOutput"
}

$expectedModelHash = "5849957F929CBF720C258F8458692D6103FFF2F0E3D3B19C8259474BB06A18D4"
$expectedConfigHash = "5681426D4AEAD22195DE70531EEEEDDB46493CFAFFC5764B2EA3DB73428B651C"
$actualModelHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $PiperModel).Hash
$actualConfigHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $modelConfig).Hash
if ($actualModelHash -ne $expectedModelHash -or $actualConfigHash -ne $expectedConfigHash) {
    throw "Piper voice files do not match the reviewed en_US-kristin-medium model."
}

$manifestData = Get-Content -Raw -LiteralPath $Manifest | ConvertFrom-Json
if ($manifestData.schema_version -ne 1 -or @($manifestData.cues).Count -eq 0) {
    throw "Unsupported or empty voice-over manifest."
}

$outputRoot = [IO.Path]::GetFullPath((Join-Path $repoRoot "assets\audio\voice-over"))
$workRoot = [IO.Path]::GetFullPath((Join-Path $repoRoot ".tmp\voice-over-build"))
New-Item -ItemType Directory -Force -Path $outputRoot, $workRoot | Out-Null
$lockPath = Join-Path $workRoot "generation.lock"
try {
    $generationLock = [IO.File]::Open(
        $lockPath,
        [IO.FileMode]::OpenOrCreate,
        [IO.FileAccess]::ReadWrite,
        [IO.FileShare]::None
    )
}
catch {
    throw "Another voice-over generation process holds the exclusive build lock: $lockPath"
}

try {
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$seenIds = @{}
$expectedOutputPaths = @{}
$publicationPlan = New-Object Collections.Generic.List[object]
$cueJobs = New-Object Collections.Generic.List[object]
$generated = 0

function Get-RoleSettings([string]$Role) {
    switch ($Role) {
        "manager" {
            return @{
                LengthScale = "0.88"
                Filter = "asetrate=18081,aresample=22050,atempo=1.12,highpass=f=250,lowpass=f=3200,acompressor=threshold=0.125:ratio=3:attack=20:release=200"
            }
        }
        "radio" {
            return @{
                LengthScale = "0.94"
                Filter = "asetrate=19845,aresample=22050,atempo=1.08,highpass=f=300,lowpass=f=3000,tremolo=f=8:d=0.06,acompressor=threshold=0.125:ratio=3:attack=15:release=150"
            }
        }
        "recording" {
            return @{
                LengthScale = "1.02"
                Filter = "highpass=f=140,lowpass=f=5000,aecho=0.8:0.25:40|75:0.09|0.04,acompressor=threshold=0.16:ratio=2.5:attack=20:release=180"
            }
        }
        "child" {
            return @{
                LengthScale = "0.90"
                Filter = "asetrate=25578,aresample=22050,atempo=0.94,highpass=f=180,lowpass=f=9000,acompressor=threshold=0.18:ratio=2:attack=15:release=140"
            }
        }
        "whisper" {
            return @{
                LengthScale = "1.08"
                Filter = "highpass=f=320,lowpass=f=6000,volume=-3dB,aecho=0.8:0.18:55:0.07,acompressor=threshold=0.16:ratio=2:attack=25:release=220"
            }
        }
        "narrator" {
            return @{
                LengthScale = "1.02"
                Filter = "highpass=f=85,lowpass=f=9000,acompressor=threshold=0.18:ratio=2:attack=20:release=180"
            }
        }
        default {
            throw "Unknown voice role: $Role"
        }
    }
}

function Repair-PiperWaveAlignment([string]$WavePath) {
    $bytes = [IO.File]::ReadAllBytes($WavePath)
    if ($bytes.Length -lt 44 -or
        [Text.Encoding]::ASCII.GetString($bytes, 0, 4) -ne "RIFF" -or
        [Text.Encoding]::ASCII.GetString($bytes, 8, 4) -ne "WAVE") {
        throw "Piper produced an invalid RIFF/WAVE file: $WavePath"
    }
    $chunkOffset = 12
    while ($chunkOffset + 8 -le $bytes.Length) {
        $chunkId = [Text.Encoding]::ASCII.GetString($bytes, $chunkOffset, 4)
        $chunkSize = [BitConverter]::ToUInt32($bytes, $chunkOffset + 4)
        $chunkDataOffset = $chunkOffset + 8
        if ($chunkId -eq "data") {
            if ($chunkDataOffset + $chunkSize -ne $bytes.Length) {
                throw "Unexpected chunks follow Piper PCM data: $WavePath"
            }
            if (($chunkSize % 2) -eq 0) {
                return
            }
            # Piper can emit one trailing half-sample. Drop only that byte and
            # repair both RIFF sizes before FFmpeg decodes the PCM stream.
            $fixedLength = $bytes.Length - 1
            $fixedBytes = New-Object byte[] $fixedLength
            [Array]::Copy($bytes, $fixedBytes, $fixedLength)
            [Array]::Copy([BitConverter]::GetBytes([uint32]($chunkSize - 1)), 0, $fixedBytes, $chunkOffset + 4, 4)
            [Array]::Copy([BitConverter]::GetBytes([uint32]($fixedLength - 8)), 0, $fixedBytes, 4, 4)
            [IO.File]::WriteAllBytes($WavePath, $fixedBytes)
            return
        }
        $chunkOffset += 8 + $chunkSize + ($chunkSize % 2)
    }
    throw "Piper WAV has no PCM data chunk: $WavePath"
}

foreach ($cue in $manifestData.cues) {
    $cueId = [string]$cue.id
    if ($cueId -notmatch "^[a-z0-9_]+-[0-9]{2}$") {
        throw "Unsafe or malformed cue id: $cueId"
    }
    if ($seenIds.ContainsKey($cueId)) {
        throw "Duplicate cue id: $cueId"
    }
    $seenIds[$cueId] = $true
    if (-not [string]$cue.subtitle -or -not [string]$cue.spoken_text) {
        throw "Cue $cueId is missing subtitle or spoken text."
    }

    $resourcePath = [string]$cue.file
    $expectedResourcePath = "res://assets/audio/voice-over/$cueId.ogg"
    if (-not [string]::Equals($resourcePath, $expectedResourcePath, [StringComparison]::Ordinal)) {
        throw "Cue $cueId must use its exact root-level resource path: $expectedResourcePath"
    }
    $relativePath = $resourcePath.Substring(6).Replace("/", [IO.Path]::DirectorySeparatorChar)
    $outputPath = [IO.Path]::GetFullPath((Join-Path $repoRoot $relativePath))
    $expectedPrefix = $outputRoot.TrimEnd("\") + "\"
    if (-not $outputPath.StartsWith($expectedPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to write cue outside the reviewed output root: $outputPath"
    }
    if ([IO.Path]::GetExtension($outputPath) -ne ".ogg" -or
        [IO.Path]::GetFileNameWithoutExtension($outputPath) -ne $cueId) {
        throw "Cue $cueId must map to its matching .ogg filename."
    }
    $outputKey = $outputPath.ToLowerInvariant()
    if ($expectedOutputPaths.ContainsKey($outputKey)) {
        throw "Multiple cues map to the same output file: $outputPath"
    }
    $expectedOutputPaths[$outputKey] = $cueId

    $settings = Get-RoleSettings ([string]$cue.role)
    $textPath = Join-Path $workRoot ($cueId + ".txt")
    $wavPath = Join-Path $workRoot ($cueId + ".wav")
    $processedPath = Join-Path $workRoot ($cueId + ".processed.ogg")
    $backupPath = Join-Path $workRoot ($cueId + ".backup.ogg")
    if (Test-Path -LiteralPath $backupPath -PathType Leaf) {
        throw "Stale publication backup requires manual recovery before generation: $backupPath"
    }
    $cueJobs.Add([pscustomobject]@{
        Cue = $cue
        CueId = $cueId
        Settings = $settings
        OutputPath = $outputPath
        TextPath = $textPath
        WavePath = $wavPath
        StagedPath = $processedPath
        BackupPath = $backupPath
    })
}

foreach ($job in $cueJobs) {
    $cue = $job.Cue
    $cueId = $job.CueId
    $settings = $job.Settings
    $outputPath = $job.OutputPath
    $textPath = $job.TextPath
    $wavPath = $job.WavePath
    $processedPath = $job.StagedPath
    $backupPath = $job.BackupPath
    foreach ($temporaryPath in @($textPath, $wavPath, $processedPath)) {
        if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }
    [IO.File]::WriteAllText($textPath, [string]$cue.spoken_text, $utf8NoBom)

    & $PiperPython -m piper -m $PiperModel -c $modelConfig -i $textPath -f $wavPath `
        --length-scale $settings.LengthScale --sentence-silence 0.05
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $wavPath -PathType Leaf)) {
        throw "Piper failed while generating cue $cueId."
    }
    Repair-PiperWaveAlignment $wavPath

    $finishFilter = "silenceremove=start_periods=1:start_silence=0.04:start_threshold=-55dB,areverse,silenceremove=start_periods=1:start_silence=0.16:start_threshold=-55dB,areverse,loudnorm=I=-20:LRA=7:TP=-2.5,alimiter=limit=0.80:attack=5:release=50:level=false,apad=pad_dur=0.12"
    $filter = $settings.Filter + "," + $finishFilter
    & $Ffmpeg -nostdin -hide_banner -loglevel error -y -i $wavPath -af $filter `
        -ac 1 -ar 22050 -c:a libvorbis -q:a 4 $processedPath
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $processedPath -PathType Leaf)) {
        throw "FFmpeg failed while processing cue $cueId."
    }
    if ((Get-Item -LiteralPath $processedPath).Length -le 256) {
        throw "Generated cue is unexpectedly small: $cueId"
    }

    $probeOutput = (& $Ffprobe -v error -select_streams a:0 `
        -show_entries "stream=codec_name,sample_rate,channels:format=duration,size" `
        -of json $processedPath 2>&1 | Out-String)
    if ($LASTEXITCODE -ne 0) {
        throw "ffprobe could not decode cue $cueId`: $probeOutput"
    }
    try {
        $probeData = $probeOutput | ConvertFrom-Json
    }
    catch {
        throw "ffprobe returned invalid JSON for cue $cueId`: $probeOutput"
    }
    if (@($probeData.streams).Count -ne 1) {
        throw "Generated cue must contain exactly one audio stream: $cueId"
    }
    $audioStream = @($probeData.streams)[0]
    $duration = [double]::Parse(
        [string]$probeData.format.duration,
        [Globalization.CultureInfo]::InvariantCulture
    )
    if ([string]$audioStream.codec_name -ne "vorbis" -or
        [int]$audioStream.sample_rate -ne 22050 -or
        [int]$audioStream.channels -ne 1 -or
        $duration -lt 0.5 -or $duration -gt 10.0) {
        throw "Generated cue failed the reviewed Vorbis/mono/22.05kHz/duration contract: $cueId"
    }

    $publicationPlan.Add([pscustomobject]@{
        CueId = $cueId
        OutputPath = $outputPath
        StagedPath = $processedPath
        BackupPath = $backupPath
        HadExisting = $false
        Published = $false
    })
    Remove-Item -LiteralPath $textPath, $wavPath -Force
    $generated += 1
    Write-Host ("[{0}/{1}] {2}" -f $generated, @($manifestData.cues).Count, $cueId)
}

$existingVoiceFiles = Get-ChildItem -LiteralPath $outputRoot -Filter "*.ogg" -File
$unexpectedExisting = @($existingVoiceFiles | Where-Object {
    -not $expectedOutputPaths.ContainsKey($_.FullName.ToLowerInvariant())
})
$missingStaged = @($publicationPlan | Where-Object {
    -not (Test-Path -LiteralPath $_.StagedPath -PathType Leaf)
})
if ($generated -ne @($manifestData.cues).Count -or
    $publicationPlan.Count -ne @($manifestData.cues).Count -or
    $missingStaged.Count -gt 0 -or $unexpectedExisting.Count -gt 0) {
    throw ("Voice-over staging set is incomplete or the output root is stale. generated={0} staged={1} missing={2} unexpected={3}" -f `
        $generated, $publicationPlan.Count, $missingStaged.Count, $unexpectedExisting.Count)
}

# Do not publish any cue until the complete staged set has passed validation.
# Backups make a mid-publication filesystem failure recover the previous set.
try {
    foreach ($item in $publicationPlan) {
        if (Test-Path -LiteralPath $item.OutputPath -PathType Leaf) {
            Copy-Item -LiteralPath $item.OutputPath -Destination $item.BackupPath
            $item.HadExisting = $true
        }
    }
    foreach ($item in $publicationPlan) {
        Move-Item -LiteralPath $item.StagedPath -Destination $item.OutputPath -Force
        $item.Published = $true
    }
}
catch {
    $publishError = $_.Exception.Message
    $rollbackFailures = New-Object Collections.Generic.List[string]
    foreach ($item in $publicationPlan) {
        try {
            if ($item.HadExisting -and (Test-Path -LiteralPath $item.BackupPath -PathType Leaf)) {
                Move-Item -LiteralPath $item.BackupPath -Destination $item.OutputPath -Force
            }
            elseif ($item.Published -and (Test-Path -LiteralPath $item.OutputPath -PathType Leaf)) {
                Remove-Item -LiteralPath $item.OutputPath -Force
            }
        }
        catch {
            $rollbackFailures.Add($item.CueId)
        }
    }
    throw ("Voice-over publication failed: {0}. Rollback failures: {1}" -f `
        $publishError, ($rollbackFailures -join ","))
}

foreach ($item in $publicationPlan) {
    if (Test-Path -LiteralPath $item.BackupPath -PathType Leaf) {
        Remove-Item -LiteralPath $item.BackupPath -Force
    }
}

$voiceFiles = Get-ChildItem -LiteralPath $outputRoot -Filter "*.ogg" -File
$actualOutputPaths = @{}
foreach ($voiceFile in $voiceFiles) {
    $actualOutputPaths[$voiceFile.FullName.ToLowerInvariant()] = $true
}
$missingOutputs = @($expectedOutputPaths.Keys | Where-Object { -not $actualOutputPaths.ContainsKey($_) })
$unexpectedOutputs = @($actualOutputPaths.Keys | Where-Object { -not $expectedOutputPaths.ContainsKey($_) })
if ($missingOutputs.Count -gt 0 -or $unexpectedOutputs.Count -gt 0) {
    throw ("Published voice-over set is incomplete. missing={0} unexpected={1}" -f `
        $missingOutputs.Count, $unexpectedOutputs.Count)
}
$totalBytes = ($voiceFiles | Measure-Object -Property Length -Sum).Sum
Write-Host ("VOICE_GENERATION_OK generated={0} files={1} bytes={2}" -f $generated, $voiceFiles.Count, $totalBytes)
}
finally {
    $generationLock.Dispose()
}
