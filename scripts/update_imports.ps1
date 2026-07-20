$dst = "e:\laragon\www\appli_pour_lemploie\lib\app\fonctionnalites"
$pkg = "package:jobaway"

# Step 1: For ALL dart files in fonctionnalites/, convert external imports to package imports
Get-ChildItem -Path $dst -Recurse -Filter "*.dart" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if (-not $content) { return }

    # Convert core/ imports (any depth of ../)
    $content = $content -replace "import '(?:\.\./)*(?:app/)?core/", "import '$pkg/app/core/"
    # Convert routes/ imports
    $content = $content -replace "import '(?:\.\./)*routes/", "import '$pkg/routes/"
    # Convert bindings/initial_binding imports
    $content = $content -replace "import '(?:\.\./)*(?:app/)?bindings/", "import '$pkg/app/bindings/"

    Set-Content -Path $_.FullName -Value $content -NoNewline
}
Write-Host "Step 1: External imports (core, routes, bindings) converted to package imports."

# Step 2: Fix internal imports for FLAT features (binding/controller/view in same folder)
$flatFeatures = @(
    "$dst\ecran_demarrage",
    "$dst\bienvenue",
    "$dst\selection_profil"
)
foreach ($dir in $flatFeatures) {
    Get-ChildItem -Path $dir -Filter "*.dart" | ForEach-Object {
        $content = Get-Content $_.FullName -Raw
        if (-not $content) { return }
        # ../controllers/X.dart or ../views/X.dart or ../bindings/X.dart -> just X.dart
        $content = $content -replace "import '\.\./(?:controllers|views|bindings)/", "import '"
        Set-Content -Path $_.FullName -Value $content -NoNewline
    }
}
Write-Host "Step 2: Flat feature internal imports fixed."

# Step 3: Fix internal imports for AUTH sub-features (each sub-folder is flat)
Get-ChildItem -Path "$dst\authentification" -Directory | ForEach-Object {
    Get-ChildItem -Path $_.FullName -Filter "*.dart" | ForEach-Object {
        $content = Get-Content $_.FullName -Raw
        if (-not $content) { return }
        $content = $content -replace "import '\.\./(?:controllers|views|bindings)/", "import '"
        Set-Content -Path $_.FullName -Value $content -NoNewline
    }
}
Write-Host "Step 3: Auth sub-feature internal imports fixed."

# Step 4: Fix HOME (accueil) - has controleur/, vue/, binding/ subfolders
# binding -> controleur
$f = "$dst\accueil\binding\home_binding.dart"
(Get-Content $f -Raw) -replace "import '\.\./controllers/", "import '../controleur/" | Set-Content $f -NoNewline

# vue -> controleur
Get-ChildItem -Path "$dst\accueil\vue" -Filter "*.dart" -File | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if (-not $content) { return }
    $content = $content -replace "import '\.\./controllers/", "import '../controleur/"
    # Cross-module: offers controller
    $content = $content -replace "import '\.\./\.\./offers/controllers/", "import '$pkg/app/fonctionnalites/offres/liste_offres/"
    $content = $content -replace "import '\.\./\.\./modules/offers/controllers/", "import '$pkg/app/fonctionnalites/offres/liste_offres/"
    Set-Content -Path $_.FullName -Value $content -NoNewline
}

# controleur internal (home_controller imports home_profile_manager - same folder, no change needed)
# But part files reference via 'part of' which uses relative - check parts
Get-ChildItem -Path "$dst\accueil\controleur\home_controller_parts" -Filter "*.dart" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if (-not $content) { return }
    # part of should still point to ../home_controller.dart - no change needed
    Set-Content -Path $_.FullName -Value $content -NoNewline
}
Get-ChildItem -Path "$dst\accueil\controleur\home_profile_manager_parts" -Filter "*.dart" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if (-not $content) { return }
    Set-Content -Path $_.FullName -Value $content -NoNewline
}

# vue parts (home_screen_parts etc.) - part of should still work
# But home_profile_parts may import from controleur
Get-ChildItem -Path "$dst\accueil\vue" -Recurse -Filter "*.dart" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if (-not $content) { return }
    $content = $content -replace "import '(?:\.\./)*controllers/", "import '$pkg/app/fonctionnalites/accueil/controleur/"
    $content = $content -replace "import '(?:\.\./)*(?:app/)?modules/offers/controllers/", "import '$pkg/app/fonctionnalites/offres/liste_offres/"
    Set-Content -Path $_.FullName -Value $content -NoNewline
}

# donnees
Get-ChildItem -Path "$dst\accueil\donnees" -Recurse -Filter "*.dart" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if (-not $content) { return }
    Set-Content -Path $_.FullName -Value $content -NoNewline
}
Write-Host "Step 4: Home (accueil) imports fixed."

# Step 5: Fix OFFERS (offres) - liste_offres/, detail_offre/, mes_candidatures/
# liste_offres: binding imports controller (same folder)
$f = "$dst\offres\liste_offres\offers_binding.dart"
(Get-Content $f -Raw) -replace "import '\.\./controllers/", "import '" | Set-Content $f -NoNewline

# liste_offres: controller & screen
Get-ChildItem -Path "$dst\offres\liste_offres" -Filter "*.dart" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if (-not $content) { return }
    $content = $content -replace "import '\.\./(?:controllers|views|bindings)/", "import '"
    # data references
    $content = $content -replace "import '\.\./data/models/", "import '../donnees/models/"
    $content = $content -replace "import '\.\./data/repositories/", "import '../donnees/repositories/"
    $content = $content -replace "import '\.\./utils/", "import '../utilitaires/"
    Set-Content -Path $_.FullName -Value $content -NoNewline
}

# detail_offre
Get-ChildItem -Path "$dst\offres\detail_offre" -Filter "*.dart" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if (-not $content) { return }
    $content = $content -replace "import '\.\./(?:controllers|views|bindings)/", "import '"
    $content = $content -replace "import '\.\./data/models/", "import '../donnees/models/"
    $content = $content -replace "import '\.\./data/repositories/", "import '../donnees/repositories/"
    $content = $content -replace "import '\.\./utils/", "import '../utilitaires/"
    Set-Content -Path $_.FullName -Value $content -NoNewline
}

# mes_candidatures
Get-ChildItem -Path "$dst\offres\mes_candidatures" -Filter "*.dart" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if (-not $content) { return }
    $content = $content -replace "import '\.\./(?:controllers|views|bindings)/", "import '../liste_offres/"
    $content = $content -replace "import '\.\./data/models/", "import '../donnees/models/"
    $content = $content -replace "import '\.\./data/repositories/", "import '../donnees/repositories/"
    $content = $content -replace "import '\.\./utils/", "import '../utilitaires/"
    Set-Content -Path $_.FullName -Value $content -NoNewline
}

# offres/donnees
Get-ChildItem -Path "$dst\offres\donnees" -Recurse -Filter "*.dart" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if (-not $content) { return }
    $content = $content -replace "import '\.\./models/", "import '../models/"
    Set-Content -Path $_.FullName -Value $content -NoNewline
}
Write-Host "Step 5: Offers (offres) imports fixed."

# Step 6: Fix TRAININGS (formations)
Get-ChildItem -Path "$dst\formations\liste_formations" -Filter "*.dart" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if (-not $content) { return }
    $content = $content -replace "import '\.\./(?:controllers|views|bindings)/", "import '"
    $content = $content -replace "import '\.\./data/models/", "import '../donnees/models/"
    $content = $content -replace "import '\.\./data/repositories/", "import '../donnees/repositories/"
    Set-Content -Path $_.FullName -Value $content -NoNewline
}
Get-ChildItem -Path "$dst\formations\detail_formation" -Filter "*.dart" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if (-not $content) { return }
    $content = $content -replace "import '\.\./(?:controllers|views|bindings)/", "import '"
    $content = $content -replace "import '\.\./data/models/", "import '../donnees/models/"
    $content = $content -replace "import '\.\./data/repositories/", "import '../donnees/repositories/"
    Set-Content -Path $_.FullName -Value $content -NoNewline
}
Write-Host "Step 6: Trainings (formations) imports fixed."

# Step 7: Fix MESSAGES (messagerie)
$f = "$dst\messagerie\binding\messages_binding.dart"
(Get-Content $f -Raw) -replace "import '\.\./controllers/", "import '../controleur/" | Set-Content $f -NoNewline

Get-ChildItem -Path "$dst\messagerie\controleur" -Filter "*.dart" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if (-not $content) { return }
    $content = $content -replace "import '\.\./data/models/", "import '../donnees/models/"
    $content = $content -replace "import '\.\./data/repositories/", "import '../donnees/repositories/"
    Set-Content -Path $_.FullName -Value $content -NoNewline
}
Get-ChildItem -Path "$dst\messagerie\vue" -Filter "*.dart" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if (-not $content) { return }
    $content = $content -replace "import '\.\./controllers/", "import '../controleur/"
    $content = $content -replace "import '\.\./data/models/", "import '../donnees/models/"
    $content = $content -replace "import '\.\./data/repositories/", "import '../donnees/repositories/"
    Set-Content -Path $_.FullName -Value $content -NoNewline
}
Write-Host "Step 7: Messages (messagerie) imports fixed."

# Step 8: Fix PROFILE (profil)
# binding
$f = "$dst\profil\binding\profile_binding.dart"
(Get-Content $f -Raw) -replace "import '\.\./controllers/", "import '../profil_principal/" | Set-Content $f -NoNewline

# profil_principal
Get-ChildItem -Path "$dst\profil\profil_principal" -Filter "*.dart" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if (-not $content) { return }
    $content = $content -replace "import '\.\./(?:controllers|views)/", "import '"
    $content = $content -replace "import '\.\./data/models/", "import '../donnees/models/"
    $content = $content -replace "import '\.\./data/repositories/", "import '../donnees/repositories/"
    Set-Content -Path $_.FullName -Value $content -NoNewline
}

# cv
Get-ChildItem -Path "$dst\profil\cv" -Filter "*.dart" -File | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if (-not $content) { return }
    $content = $content -replace "import '\.\./data/models/", "import '../donnees/models/"
    $content = $content -replace "import '\.\./data/repositories/", "import '../donnees/repositories/"
    Set-Content -Path $_.FullName -Value $content -NoNewline
}
Get-ChildItem -Path "$dst\profil\cv\vue" -Recurse -Filter "*.dart" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if (-not $content) { return }
    $content = $content -replace "import '\.\./controllers/cv_builder_controller", "import '$pkg/app/fonctionnalites/profil/cv/cv_builder_controller"
    $content = $content -replace "import '\.\./\.\./controllers/cv_builder_controller", "import '$pkg/app/fonctionnalites/profil/cv/cv_builder_controller"
    $content = $content -replace "import '(?:\.\./)*controllers/profile_controller", "import '$pkg/app/fonctionnalites/profil/profil_principal/profile_controller"
    $content = $content -replace "import '(?:\.\./)*data/models/", "import '$pkg/app/fonctionnalites/profil/donnees/models/"
    $content = $content -replace "import '(?:\.\./)*data/repositories/", "import '$pkg/app/fonctionnalites/profil/donnees/repositories/"
    Set-Content -Path $_.FullName -Value $content -NoNewline
}

# portfolio
Get-ChildItem -Path "$dst\profil\portfolio" -Filter "*.dart" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if (-not $content) { return }
    $content = $content -replace "import '\.\./controllers/", "import '../profil_principal/"
    $content = $content -replace "import '\.\./data/models/", "import '../donnees/models/"
    $content = $content -replace "import '\.\./data/repositories/", "import '../donnees/repositories/"
    Set-Content -Path $_.FullName -Value $content -NoNewline
}

# donnees
Get-ChildItem -Path "$dst\profil\donnees" -Recurse -Filter "*.dart" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if (-not $content) { return }
    $content = $content -replace "import '\.\./models/", "import '../models/"
    Set-Content -Path $_.FullName -Value $content -NoNewline
}
Write-Host "Step 8: Profile (profil) imports fixed."

# Step 9: Fix notifications & errors (simple views)
# These just need external imports (already done in step 1)
Write-Host "Step 9: Notifications & errors - no additional internal imports."

Write-Host "`nAll fonctionnalites/ internal imports updated!"
