param(
    [string]$Source = "scripts/autoload/pronunciation_manager.gd",
    [string]$OutDir = "assets/Audio/PronunciationTests",
    [string]$PreferredVoice = "Microsoft Zira Desktop",
    [int]$Rate = -2
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Speech

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $repoRoot $Source
$outputPath = Join-Path $repoRoot $OutDir

if (-not (Test-Path $sourcePath)) {
    throw "Source file not found: $sourcePath"
}

$pattern = '\{"word":\s*"([^"]+)",\s*"correct":\s*"([^"]+)"'
$entries = @()

foreach ($line in Get-Content $sourcePath) {
    if ($line -match $pattern) {
        $entries += [pscustomobject]@{
            Word = $matches[1]
            Hint = $matches[2]
        }
    }
}

if ($entries.Count -eq 0) {
    throw "No pronunciation word-bank entries found in $sourcePath"
}

New-Item -ItemType Directory -Force -Path $outputPath | Out-Null

$voices = [System.Speech.Synthesis.SpeechSynthesizer]::new().GetInstalledVoices() |
    ForEach-Object { $_.VoiceInfo.Name }

$voiceToUse = if ($voices -contains $PreferredVoice) {
    $PreferredVoice
} elseif ($voices.Count -gt 0) {
    $voices[0]
} else {
    throw "No installed System.Speech voices found."
}

$format = New-Object System.Speech.AudioFormat.SpeechAudioFormatInfo(
    16000,
    [System.Speech.AudioFormat.AudioBitsPerSample]::Sixteen,
    [System.Speech.AudioFormat.AudioChannel]::Mono
)

function New-Synth {
    param(
        [string]$VoiceName,
        [int]$SpeechRate,
        [System.Speech.AudioFormat.SpeechAudioFormatInfo]$AudioFormat
    )

    $synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
    $synth.SelectVoice($VoiceName)
    $synth.Rate = $SpeechRate
    $synth.Volume = 100
    return $synth
}

function Get-SafeFileStem {
    param([string]$Word)

    $safe = $Word.ToLowerInvariant() -replace '[^a-z0-9]+', '_'
    $safe = $safe.Trim('_')
    if ([string]::IsNullOrWhiteSpace($safe)) {
        return "word"
    }
    return $safe
}

$manifestLines = New-Object System.Collections.Generic.List[string]
$manifestLines.Add("Voice: $voiceToUse")
$manifestLines.Add("Rate: $Rate")
$manifestLines.Add("Format: 16kHz mono 16-bit PCM")
$manifestLines.Add("")

$combinedPath = Join-Path $outputPath "pronunciation_test_pack.wav"
$combinedSynth = New-Synth -VoiceName $voiceToUse -SpeechRate $Rate -AudioFormat $format
$combinedSynth.SetOutputToWaveFile($combinedPath, $format)

try {
    for ($i = 0; $i -lt $entries.Count; $i++) {
        $entry = $entries[$i]
        $index = $i + 1
        $stem = Get-SafeFileStem -Word $entry.Word
        $fileName = "{0:D2}_{1}.wav" -f $index, $stem
        $filePath = Join-Path $outputPath $fileName

        $wordSynth = New-Synth -VoiceName $voiceToUse -SpeechRate $Rate -AudioFormat $format
        try {
            $wordSynth.SetOutputToWaveFile($filePath, $format)
            $wordSynth.Speak($entry.Word)
        } finally {
            $wordSynth.Dispose()
        }

        $combinedSynth.Speak($entry.Word)
        $combinedSynth.SpeakSsml('<speak version="1.0" xml:lang="en-US"><break time="900ms"/></speak>')

        $manifestLines.Add(("{0:D2}. {1} | hint={2} | file={3}" -f $index, $entry.Word, $entry.Hint, $fileName))
    }
} finally {
    $combinedSynth.Dispose()
}

$manifestPath = Join-Path $outputPath "pronunciation_test_manifest.txt"
Set-Content -Path $manifestPath -Value $manifestLines -Encoding UTF8

Write-Host "Generated $($entries.Count) pronunciation clips in $outputPath"
Write-Host "Combined file: $combinedPath"
Write-Host "Manifest: $manifestPath"
