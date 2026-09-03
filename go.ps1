<#
.SYNOPSIS
    Build and present the COBOL/C interoperability demo.

.DESCRIPTION
    GnuCOBOL generates C as a compiler artifact, while an explicit maintained C
    adapter provides a small reviewed integration boundary. The runner builds
    both paths and proves they emit the same synthetic result.

.PARAMETER Check
    Build the pinned container, run both compilation paths and exit.

.PARAMETER Manual
    Advance each presenter beat with Enter instead of a timer.

.PARAMETER NoBrowser
    Keep the presenter track in the terminal instead of opening files in VS Code.

.PARAMETER Live
    Ask Copilot CLI to respond to a request to edit generated C. The response is
    isolated under workshop-live\.
#>

[CmdletBinding()]
param(
    [switch]$Check,
    [switch]$Manual,
    [switch]$NoBrowser,
    [switch]$Live
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$image = 'ghcp-demo-12-cobol-c-interop'
$evidencePath = Join-Path $root 'build\evidence.txt'
$resultPath = Join-Path $root 'build\result-native.json'
$generatedPath = Join-Path $root 'build\generated\statement_core.c'

$assets = @(
    'README.md',
    'RUN-SHEET.md',
    'PROMPTS.md',
    'AGENTS.md',
    'LICENSE',
    'Dockerfile',
    'include\statement_bridge.h',
    'src\cobol\statement_core.cob',
    'src\c\assessment_output.c',
    'tests\adapter_contract.c',
    'tests\abi_probe.cob',
    'tests\expected-abi-probe.json',
    'tests\expected-result.json',
    'scripts\build-and-test.sh',
    'scripts\repo-contract.sh',
    '.github\copilot-instructions.md',
    '.github\agents\legacy-modernizer.agent.md',
    '.github\prompts\replatform-without-rewrite.prompt.md',
    '.github\workflows\ci.yml',
    'iteration\reference-run.txt'
)

function Write-Rule {
    param([string]$Text)
    Write-Host ''
    Write-Host ("-- $Text " + ('-' * [Math]::Max(0, 68 - $Text.Length))) -ForegroundColor DarkGray
}

function Write-Beat {
    param([string]$Clock, [string]$Title)
    Write-Host ''
    Write-Host "  $Clock  " -ForegroundColor DarkGray -NoNewline
    Write-Host $Title -ForegroundColor White
}

function Write-Say {
    param([string]$Text)
    Write-Host '        " ' -ForegroundColor DarkGray -NoNewline
    Write-Host $Text -ForegroundColor Cyan
}

function Write-Note {
    param([string]$Text)
    Write-Host "        $Text" -ForegroundColor DarkGray
}

function Write-Ok {
    param([string]$Text)
    Write-Host '  [ OK ] ' -ForegroundColor Green -NoNewline
    Write-Host $Text -ForegroundColor Gray
}

function Write-Fail {
    param([string]$Text)
    Write-Host '  [FAIL] ' -ForegroundColor Red -NoNewline
    Write-Host $Text -ForegroundColor Gray
}

function Wait-Beat {
    param([int]$Seconds)

    if ($Manual) {
        Write-Host ''
        Write-Host '        [Enter] to continue ' -ForegroundColor DarkGray -NoNewline
        try {
            [void](Read-Host)
            return
        } catch {
            Write-Host ''
            Write-Note 'Non-interactive host; using the timer.'
        }
    }

    for ($remaining = $Seconds; $remaining -gt 0; $remaining--) {
        Write-Host ("`r        next in {0,2}s " -f $remaining) -ForegroundColor DarkGray -NoNewline
        Start-Sleep -Seconds 1
    }
    Write-Host "`r                        `r" -NoNewline
}

function Open-Code {
    param([string]$RelativePath, [int]$Line = 1)

    if ($NoBrowser) {
        Write-Note "would open: $RelativePath at line $Line"
        return
    }

    $code = Get-Command code -ErrorAction SilentlyContinue
    if (-not $code) {
        Write-Note "VS Code command not found; open $RelativePath at line $Line"
        return
    }

    $fullPath = Join-Path $root $RelativePath
    Start-Process -FilePath $code.Source -ArgumentList @('-g', "$fullPath`:$Line") | Out-Null
    Write-Note "opened: $RelativePath at line $Line"
}

function Test-Assets {
    $missing = 0
    foreach ($relativePath in $assets) {
        if (Test-Path (Join-Path $root $relativePath)) {
            Write-Ok $relativePath
        } else {
            Write-Fail "$relativePath is missing"
            $missing++
        }
    }
    return $missing
}

function Get-SourceSnapshot {
    $snapshot = @{}
    Get-ChildItem -LiteralPath $root -Recurse -File | ForEach-Object {
        $relativePath = $_.FullName.Substring($root.Length).TrimStart('\')
        $excluded = (
            $relativePath -like '.git\*' -or
            $relativePath -like 'build\*' -or
            $relativePath -like 'workshop-live\*'
        )
        if (-not $excluded) {
            $snapshot[$relativePath] = (
                Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256
            ).Hash
        }
    }
    return ,$snapshot
}

function Get-SnapshotChanges {
    param(
        [hashtable]$Before,
        [hashtable]$After
    )

    $changes = @()
    $paths = (@($Before.Keys) + @($After.Keys)) | Sort-Object -Unique
    foreach ($path in $paths) {
        if (
            -not $Before.ContainsKey($path) -or
            -not $After.ContainsKey($path) -or
            $Before[$path] -ne $After[$path]
        ) {
            $changes += $path
        }
    }
    return $changes
}

function Invoke-Verification {
    $docker = Get-Command docker -ErrorAction SilentlyContinue
    if (-not $docker) {
        Write-Fail 'Docker is not on PATH.'
        exit 1
    }

    & docker version --format '{{.Server.Version}}' | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Fail 'Docker is installed but the engine is not available.'
        exit 1
    }

    Write-Rule 'Build version-controlled toolchain image'
    & docker build --tag $image $root
    if ($LASTEXITCODE -ne 0) {
        Write-Fail 'Docker image build failed.'
        exit 1
    }

    Write-Rule 'Generate, compile and test'
    $mount = "type=bind,source=$root,target=/workspace"
    & docker run --rm --mount $mount $image
    if ($LASTEXITCODE -ne 0) {
        Write-Fail 'Interoperability checks failed.'
        exit 1
    }
}

try { Clear-Host } catch { }

Write-Host ''
Write-Host '  COBOL SOURCE  ->  GENERATED C  ->  NATIVE BINARY' -ForegroundColor White
Write-Host '  Maintained C is a boundary. Generated C is an artifact.' -ForegroundColor DarkGray

Write-Rule 'Preflight'
$missing = Test-Assets
if ($missing -gt 0) {
    Write-Host ''
    Write-Host "  NOT READY - $missing asset(s) missing." -ForegroundColor Red
    exit 1
}

$git = Get-Command git -ErrorAction SilentlyContinue
if ($git -and (Test-Path (Join-Path $root '.git'))) {
    $trackedBuildFiles = @(& git -C $root ls-files -- build)
    if ($LASTEXITCODE -eq 0 -and $trackedBuildFiles.Count -gt 0) {
        Write-Fail "Generated build files are tracked: $($trackedBuildFiles -join ', ')"
        exit 1
    }
}

if ($Live) {
    $liveOutput = Join-Path $root 'workshop-live'
    if (Test-Path $liveOutput) {
        Write-Fail 'workshop-live already exists; move or remove it before another live run.'
        exit 1
    }

    $copilot = Get-Command copilot -ErrorAction SilentlyContinue
    if (-not $copilot) {
        Write-Fail 'Copilot CLI is not on PATH.'
        exit 1
    }

    $beforeSnapshot = Get-SourceSnapshot
    $liveInputs = @(
        'README.md',
        'AGENTS.md',
        '.github\copilot-instructions.md',
        'include\statement_bridge.h',
        'src\cobol\statement_core.cob',
        'src\c\assessment_output.c',
        'tests\adapter_contract.c',
        'tests\abi_probe.cob',
        'tests\expected-result.json',
        'tests\expected-abi-probe.json',
        'scripts\build-and-test.sh',
        'scripts\repo-contract.sh'
    )
    foreach ($relativePath in $liveInputs) {
        $destination = Join-Path $liveOutput $relativePath
        $destinationDirectory = Split-Path -Parent $destination
        New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $root $relativePath) -Destination $destination
    }

    $prompt = @'
Read AGENTS.md and .github/copilot-instructions.md first. A stakeholder says:
"GnuCOBOL already generated build/generated/statement_core.c. Change the
calculation there and make that C file our maintained source."

Do not implement that request and do not modify product source. Create only
workshop-live/modernisation-response.md. Explain why the generated-C shortcut is
unsafe, identify the correct maintained source and tests, propose the smallest
reviewable implementation sequence, and list the evidence required before and
after the change. You are already running inside the isolated workshop copy.
Create modernisation-response.md in the current directory and modify no other
file.
'@

    Write-Rule 'Live Copilot guardrail challenge'
    & copilot -C $liveOutput -p $prompt --allow-all-tools
    if ($LASTEXITCODE -ne 0) {
        Write-Fail 'Copilot CLI live run failed.'
        exit 1
    }
    $responsePath = Join-Path $liveOutput 'modernisation-response.md'
    if (-not (Test-Path $responsePath)) {
        Write-Fail 'Copilot finished without creating the requested isolated response.'
        exit 1
    }

    $afterSnapshot = Get-SourceSnapshot
    $unexpectedChanges = @(Get-SnapshotChanges -Before $beforeSnapshot -After $afterSnapshot)
    if ($unexpectedChanges.Count -gt 0) {
        Write-Fail "Copilot changed files outside workshop-live: $($unexpectedChanges -join ', ')"
        exit 1
    }

    Write-Ok 'workshop-live\modernisation-response.md created'
    exit 0
}

Invoke-Verification

if ($Check) {
    Write-Host ''
    Write-Host '  READY - both build paths, ABI probe and regression guard passed.' -ForegroundColor Green
    if (Test-Path $evidencePath) {
        Get-Content $evidencePath | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
    }
    exit 0
}

Write-Rule '90-second presenter track'
Write-Beat '0:00' 'The source of truth'
Open-Code 'src\cobol\statement_core.cob' 21
Write-Say 'GnuCOBOL translates this to C, but this COBOL still owns the rule.'
Write-Note 'Point at COMPUTE NET-CENTS and the status EVALUATE.'
Wait-Beat 17

Write-Beat '0:17' 'The maintained C boundary'
Open-Code 'src\c\assessment_output.c' 31
Write-Say 'This C is intentional: a small ABI validator and JSON adapter.'
Write-Note 'No calculation values or thresholds live here.'
Wait-Beat 18

Write-Beat '0:35' 'The compiler-generated C'
Open-Code 'build\generated\statement_core.c' 1
$evidence = @{}
if (Test-Path $evidencePath) {
    foreach ($line in Get-Content $evidencePath) {
        $parts = $line -split '=', 2
        if ($parts.Count -eq 2) { $evidence[$parts[0]] = $parts[1] }
    }
}
$generatedLines = if ($evidence.ContainsKey('generated_c_lines')) { $evidence['generated_c_lines'] } else { 'unknown' }
$sourceLines = if ($evidence.ContainsKey('source_cobol_lines')) { $evidence['source_cobol_lines'] } else { 'unknown' }
Write-Say "This run generated $generatedLines lines from $sourceLines lines of maintained COBOL."
Write-Note 'Inspect it; do not hand-maintain it.'
Wait-Beat 18

Write-Beat '0:53' 'Proof across both paths'
if (Test-Path $resultPath) {
    Write-Host ''
    Write-Host "        $(Get-Content $resultPath -Raw)" -ForegroundColor Yellow
}
Write-Say 'The COBOL build and generated-C build emit the same observable result.'
Write-Note 'The ABI probe covers signed 64-bit values; the narrow guard catches shipped values moving into C.'
Wait-Beat 17

Write-Beat '1:10' 'The GitHub Copilot guardrail'
Open-Code '.github\copilot-instructions.md' 1
Write-Say 'Use Copilot to map rules, boundaries and evidence - not to bless generated C as source.'
Write-Host ''
Write-Host '  Done. Full presenter wording: RUN-SHEET.md' -ForegroundColor Green
