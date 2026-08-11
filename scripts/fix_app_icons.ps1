# Fix remaining Iconly references after migration
$root = Join-Path $PSScriptRoot "..\lib"
$files = Get-ChildItem -Path $root -Recurse -Filter "*.dart"

$replacements = [ordered]@{
    "AppIcons.network_1" = "AppIcons.network"
    "AppIcons.paper_plus" = "AppIcons.paperPlus"
    "IconlyBold.heart" = "AppIcons.heartFilled"
    "IconlyLight.heart" = "AppIcons.heart"
    "IconlyBold.image" = "AppIcons.image"
    "IconlyBold.lock" = "AppIcons.lockFilled"
    "IconlyBold.edit" = "AppIcons.edit"
    "IconlyBold.upload" = "AppIcons.upload"
    "IconlyBold.danger" = "AppIcons.danger"
    "IconlyBold.discovery" = "AppIcons.discovery"
    "IconlyBold.notification" = "AppIcons.notificationFilled"
    "IconlyBold.add_user" = "AppIcons.addUser"
    "IconlyBold.calendar" = "AppIcons.calendar"
    "IconlyBold.shield_done" = "AppIcons.shieldDone"
    "IconlyBold.message" = "AppIcons.messageFilled"
    "IconlyLight.discovery" = "AppIcons.discovery"
    "IconlyLight.logout" = "AppIcons.logout"
    "IconlyLight.shield_fail" = "AppIcons.shieldFail"
    "IconlyLight.more_circle" = "AppIcons.moreCircle"
    "IconlyLight.arrow_right_circle" = "AppIcons.arrowRightCircle"
    "IconlyLight.swap" = "AppIcons.swap"
    "IconlyLight.download" = "AppIcons.download"
}

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    $original = $content
    foreach ($key in $replacements.Keys) {
        $content = $content.Replace($key, $replacements[$key])
    }
    if ($content -ne $original) {
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
    }
}
Write-Host "Fix pass complete."
