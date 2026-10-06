# Prépare l'émulateur + tunnel ADB puis lance Flutter (API + Reverb).
# Backend Docker : nginx :8000, Reverb :8080 sur la machine hôte.
$ErrorActionPreference = "Stop"

function Get-ReverbAppKey {
  if ($env:REVERB_APP_KEY) {
    return $env:REVERB_APP_KEY.Trim()
  }

  $backendEnv = Join-Path (Split-Path $PSScriptRoot -Parent) "..\projet_de_l-emploi\.env"
  if (-not (Test-Path $backendEnv)) {
    return $null
  }

  foreach ($line in Get-Content $backendEnv) {
    if ($line -match '^\s*REVERB_APP_KEY\s*=\s*(.+)\s*$') {
      return $Matches[1].Trim().Trim('"').Trim("'")
    }
  }

  return $null
}

$sdkRoot = Join-Path $env:LOCALAPPDATA "Android\sdk"
$adb = Join-Path $sdkRoot "platform-tools\adb.exe"

if (Test-Path $adb) {
  Write-Host "ADB reverse tcp:8000 → PC localhost:8000"
  Write-Host "ADB reverse tcp:8080 → PC localhost:8080 (Reverb WebSocket)"
  & $adb reverse tcp:8000 tcp:8000
  & $adb reverse tcp:8080 tcp:8080
  & $adb reverse --list
} else {
  Write-Host "ADB introuvable — l'émulateur utilisera 10.0.2.2:8000 et :8080"
}

$reverbKey = Get-ReverbAppKey
if (-not $reverbKey) {
  Write-Warning "REVERB_APP_KEY introuvable (.env backend ou variable d'environnement). Le temps réel sera désactivé."
}

Set-Location (Split-Path $PSScriptRoot -Parent)
Write-Host "Flutter (API : 127.0.0.1:8000 via reverse, sinon 10.0.2.2:8000)"

$dartDefines = @('--dart-define=API_BASE_URL=http://127.0.0.1:8000')
if ($reverbKey) {
  $dartDefines += "--dart-define=REVERB_APP_KEY=$reverbKey"
}

flutter run @dartDefines @args
