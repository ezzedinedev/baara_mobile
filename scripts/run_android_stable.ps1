$ErrorActionPreference = "Stop"

$sdkRoot = Join-Path $env:LOCALAPPDATA "Android\sdk"
$adb = Join-Path $sdkRoot "platform-tools\adb.exe"
$emulator = Join-Path $sdkRoot "emulator\emulator.exe"
$avdName = "Pixel_8a_API36"
$deviceId = "emulator-5556"

Write-Host "Restart ADB..."
& $adb kill-server | Out-Null
Start-Sleep -Seconds 1
& $adb start-server | Out-Null

Write-Host "Closing existing emulators..."
$runningEmulators = Get-CimInstance Win32_Process |
  Where-Object { $_.Name -eq "emulator.exe" }

if ($runningEmulators) {
  foreach ($emu in $runningEmulators) {
    try {
      Stop-Process -Id $emu.ProcessId -Force -ErrorAction Stop
    } catch {
      Write-Host "Unable to stop emulator process $($emu.ProcessId): $($_.Exception.Message)"
    }
  }
  Start-Sleep -Seconds 3
}

Write-Host "Launching stable AVD: $avdName..."
Start-Process `
  -FilePath $emulator `
  -ArgumentList "-avd $avdName -port 5556 -no-snapshot -no-boot-anim -gpu host -memory 4096"

Write-Host "Waiting for $deviceId..."
& $adb -s $deviceId wait-for-device

for ($i = 0; $i -lt 120; $i++) {
  $boot = (& $adb -s $deviceId shell getprop sys.boot_completed).Trim()
  if ($boot -eq "1") {
    break
  }
  Start-Sleep -Seconds 2
}

Write-Host "Connected devices:"
& $adb devices -l

Write-Host "Launching Flutter..."
flutter run -d $deviceId --no-dds --no-enable-impeller --device-timeout 180
