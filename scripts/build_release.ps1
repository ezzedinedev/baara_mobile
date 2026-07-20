<#
.SYNOPSIS
    Builds obfuscated release artifacts for JobAway (Flutter).

.DESCRIPTION
    Runs `flutter build` for APK and App Bundle (and optionally iOS) with Dart
    obfuscation enabled. Debug symbols are written to build/symbols/<version> so
    crash reports can later be de-symbolicated.

    IMPORTANT: the generated symbols (build/symbols/**) MUST be archived in a
    SAFE, PRIVATE location. They are required to de-obfuscate crash stack traces.
    They must NEVER be committed to a public repository. See docs/OBFUSCATION.md.

.PARAMETER Targets
    Which artifacts to build. One or more of: apk, appbundle, ios.
    Default: apk, appbundle.

.PARAMETER Flavor
    Optional Flutter flavor (passed as --flavor). Omit if you don't use flavors.

.EXAMPLE
    ./scripts/build_release.ps1
    Builds apk + appbundle (obfuscated).

.EXAMPLE
    ./scripts/build_release.ps1 -Targets apk,appbundle,ios
#>
[CmdletBinding()]
param(
    [ValidateSet('apk', 'appbundle', 'ios')]
    [string[]]$Targets = @('apk', 'appbundle'),
    [string]$Flavor
)

$ErrorActionPreference = 'Stop'

# Resolve project root (parent of this scripts/ folder) and move there.
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

function Get-AppVersion {
    # Reads `version: x.y.z+n` from pubspec.yaml.
    $line = Select-String -Path (Join-Path $ProjectRoot 'pubspec.yaml') `
        -Pattern '^\s*version:\s*(.+)$' | Select-Object -First 1
    if (-not $line) { return 'unknown' }
    return ($line.Matches[0].Groups[1].Value).Trim()
}

$version = Get-AppVersion
$symbolsDir = Join-Path $ProjectRoot "build/symbols/$version"
New-Item -ItemType Directory -Force -Path $symbolsDir | Out-Null

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host " JobAway - Obfuscated release build" -ForegroundColor Cyan
Write-Host " Version  : $version" -ForegroundColor Cyan
Write-Host " Targets  : $($Targets -join ', ')" -ForegroundColor Cyan
Write-Host " Symbols  : $symbolsDir" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

$flavorArgs = @()
if ($Flavor) { $flavorArgs = @('--flavor', $Flavor) }

$common = @('--release', '--obfuscate', "--split-debug-info=$symbolsDir") + $flavorArgs

# Secrets prod : définir REVERB_APP_KEY (et optionnellement API_BASE_URL) via
# dart_defines.json à la racine du projet, ou variables d'environnement.
$dartDefineArgs = @()
$definesFile = Join-Path $ProjectRoot 'dart_defines.json'
if (Test-Path $definesFile) {
    Write-Host "Using dart_defines.json for --dart-define-from-file" -ForegroundColor Cyan
    $dartDefineArgs = @('--dart-define-from-file', $definesFile)
} elseif ($env:REVERB_APP_KEY) {
    $dartDefineArgs = @("--dart-define=REVERB_APP_KEY=$($env:REVERB_APP_KEY)")
}

$common = $common + $dartDefineArgs

foreach ($target in $Targets) {
    Write-Host "`n--> flutter build $target $($common -join ' ')" -ForegroundColor Yellow
    & flutter build $target @common
    if ($LASTEXITCODE -ne 0) {
        throw "flutter build $target failed (exit $LASTEXITCODE)."
    }
}

Write-Host "`n=========================================================" -ForegroundColor Green
Write-Host " BUILD OK" -ForegroundColor Green
Write-Host " Symbols written to: $symbolsDir" -ForegroundColor Green
Write-Host ""
Write-Host " >>> ARCHIVE THESE SYMBOLS SAFELY (private storage). <<<" -ForegroundColor Magenta
Write-Host "     They are needed to de-symbolicate crash reports." -ForegroundColor Magenta
Write-Host "     Do NOT commit them to a public repo. See docs/OBFUSCATION.md" -ForegroundColor Magenta
Write-Host "=========================================================" -ForegroundColor Green
