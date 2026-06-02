# Lance l'API Laravel pour qu'elle soit joignable depuis l'émulateur Android.
# Par défaut `php artisan serve` n'écoute que 127.0.0.1 → l'émulateur (10.0.2.2) ne peut pas se connecter.
#
# Usage : dans un terminal séparé, laisser ce script tourner pendant `flutter run`.
$ErrorActionPreference = "Stop"

$backendRoot = "e:\laragon\www\projet_de_l-emploi"
if (-not (Test-Path $backendRoot)) {
  Write-Error "Backend introuvable : $backendRoot"
}

Set-Location $backendRoot
Write-Host "API Laravel sur http://0.0.0.0:8000 (émulateur : http://10.0.2.2:8000/api/v1)"
Write-Host "Arrêt : Ctrl+C"
php artisan serve --host=0.0.0.0 --port=8000
