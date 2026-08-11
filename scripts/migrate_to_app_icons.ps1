# Migre IconlyLight/IconlyBold vers AppIcons dans lib/
$root = Join-Path $PSScriptRoot "..\lib"
$files = Get-ChildItem -Path $root -Recurse -Filter "*.dart"

$replacements = [ordered]@{
    "IconlyBold.tick_square" = "AppIcons.tickSquare"
    "IconlyLight.tick_square" = "AppIcons.tickSquare"
    "IconlyBold.bookmark" = "AppIcons.bookmarkFilled"
    "IconlyLight.bookmark" = "AppIcons.bookmark"
    "IconlyBold.home" = "AppIcons.homeFilled"
    "IconlyLight.home" = "AppIcons.home"
    "IconlyBold.work" = "AppIcons.workFilled"
    "IconlyLight.work" = "AppIcons.work"
    "IconlyBold.profile" = "AppIcons.profileFilled"
    "IconlyLight.profile" = "AppIcons.profile"
    "IconlyBold.user_3" = "AppIcons.networkFilled"
    "IconlyLight.user" = "AppIcons.network"
    "IconlyBold.category" = "AppIcons.trackingFilled"
    "IconlyLight.category" = "AppIcons.tracking"
    "IconlyBold.star" = "AppIcons.starFilled"
    "IconlyLight.star" = "AppIcons.star"
    "IconlyBold.chat" = "AppIcons.chatFilled"
    "IconlyLight.chat" = "AppIcons.chat"
    "IconlyBold.send" = "AppIcons.send"
    "IconlyLight.send" = "AppIcons.send"
    "IconlyBold.document" = "AppIcons.document"
    "IconlyLight.document" = "AppIcons.document"
    "IconlyBold.folder" = "AppIcons.folder"
    "IconlyLight.folder" = "AppIcons.folder"
    "IconlyLight.arrow_right_2" = "AppIcons.arrowRight"
    "IconlyLight.arrow_left_2" = "AppIcons.back"
    "IconlyLight.arrow_down_2" = "AppIcons.chevronDown"
    "IconlyLight.message" = "AppIcons.message"
    "IconlyLight.lock" = "AppIcons.lock"
    "IconlyLight.unlock" = "AppIcons.unlock"
    "IconlyLight.password" = "AppIcons.password"
    "IconlyLight.call" = "AppIcons.phone"
    "IconlyLight.show" = "AppIcons.show"
    "IconlyLight.hide" = "AppIcons.hide"
    "IconlyLight.calendar" = "AppIcons.calendar"
    "IconlyLight.location" = "AppIcons.location"
    "IconlyLight.notification" = "AppIcons.bell"
    "IconlyLight.setting" = "AppIcons.settings"
    "IconlyLight.delete" = "AppIcons.delete"
    "IconlyLight.plus" = "AppIcons.add"
    "IconlyLight.edit" = "AppIcons.edit"
    "IconlyLight.search" = "AppIcons.search"
    "IconlyLight.filter" = "AppIcons.filter"
    "IconlyLight.info_circle" = "AppIcons.info"
    "IconlyLight.time_circle" = "AppIcons.time"
    "IconlyLight.time_square" = "AppIcons.timeSquare"
    "IconlyLight.camera" = "AppIcons.camera"
    "IconlyLight.image" = "AppIcons.image"
    "IconlyLight.paper" = "AppIcons.paper"
    "IconlyLight.paper_plus" = "AppIcons.paperPlus"
    "IconlyLight.play" = "AppIcons.play"
    "IconlyLight.video" = "AppIcons.video"
    "IconlyLight.voice" = "AppIcons.voice"
    "IconlyLight.upload" = "AppIcons.upload"
    "IconlyLight.wallet" = "AppIcons.wallet"
    "IconlyLight.shield_done" = "AppIcons.shieldDone"
    "IconlyLight.danger" = "AppIcons.danger"
    "IconlyLight.activity" = "AppIcons.activity"
    "IconlyLight.chart" = "AppIcons.chart"
    "IconlyLight.volume_up" = "AppIcons.volumeUp"
    "IconlyLight.volume_off" = "AppIcons.volumeOff"
    "IconlyLight.close_square" = "AppIcons.closeSquare"
    "IconlyLight.add_user" = "AppIcons.addUser"
    "IconlyBold.play" = "AppIcons.play"
    "IconlyBold.wallet" = "AppIcons.wallet"
}

$changed = 0
foreach ($file in $files) {
    if ($file.FullName -match "packages\\iconly") { continue }
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    $original = $content
    foreach ($key in $replacements.Keys) {
        $content = $content.Replace($key, $replacements[$key])
    }
    if ($content -match "AppIcons\." -and $content -notmatch "app_icons\.dart") {
        if ($content -match "import 'package:iconly/iconly.dart'") {
            $content = $content -replace "import 'package:iconly/iconly.dart';\r?\n", ""
            $content = $content -replace "import `"package:iconly/iconly.dart`";\r?\n", ""
        }
        if ($content -notmatch "app/core/theme/app_icons.dart") {
            $content = $content -replace "(import 'package:flutter/material.dart';\r?\n)", "`$1import 'package:baara/app/core/theme/app_icons.dart';`n"
        }
    }
    if ($content -ne $original) {
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
        $changed++
    }
}
Write-Host "Migrated $changed files."
