# Prépare l'émulateur + tunnel ADB puis lance Flutter.
# Option A (recommandée) : lancer aussi scripts/start_laravel_for_emulator.ps1 dans un autre terminal.
$ErrorActionPreference = "Stop"

$sdkRoot = Join-Path $env:LOCALAPPDATA "Android\sdk"
$adb = Join-Path $sdkRoot "platform-tools\adb.exe"

if (Test-Path $adb) {
  Write-Host "ADB reverse tcp:8000 → PC localhost:8000"
  & $adb reverse tcp:8000 tcp:8000
  & $adb reverse --list
} else {
  Write-Host "ADB introuvable — sans reverse, utilisez start_laravel_for_emulator.ps1"
}

Set-Location (Split-Path $PSScriptRoot -Parent)
Write-Host "Flutter (API : 127.0.0.1:8000 via reverse, sinon 10.0.2.2:8000)"
flutter run `
  --dart-define=API_BASE_URL=http://127.0.0.1:8000 `
  @args
