$root = "e:\laragon\www\appli_pour_lemploie\lib\app"
$src = "$root\modules"
$dst = "$root\fonctionnalites"

# Phase 1: Create all destination directories
$dirs = @(
    "$dst\ecran_demarrage",
    "$dst\bienvenue",
    "$dst\selection_profil",
    "$dst\authentification\connexion_candidat",
    "$dst\authentification\connexion_recruteur",
    "$dst\authentification\inscription",
    "$dst\authentification\inscription_profil",
    "$dst\authentification\verification_otp",
    "$dst\authentification\mot_de_passe_oublie",
    "$dst\accueil\controleur\home_controller_parts",
    "$dst\accueil\controleur\home_profile_manager_parts",
    "$dst\accueil\vue\home_screen_parts",
    "$dst\accueil\vue\home_profile_parts",
    "$dst\accueil\vue\home_training_parts",
    "$dst\accueil\vue\home_formation_detail_parts",
    "$dst\accueil\binding",
    "$dst\accueil\donnees\models",
    "$dst\offres\liste_offres",
    "$dst\offres\detail_offre",
    "$dst\offres\mes_candidatures",
    "$dst\offres\donnees\models",
    "$dst\offres\donnees\repositories",
    "$dst\offres\utilitaires",
    "$dst\offres\composants",
    "$dst\formations\liste_formations",
    "$dst\formations\detail_formation",
    "$dst\formations\donnees\models",
    "$dst\formations\donnees\repositories",
    "$dst\formations\composants",
    "$dst\messagerie\controleur",
    "$dst\messagerie\vue",
    "$dst\messagerie\donnees\models",
    "$dst\messagerie\donnees\repositories",
    "$dst\messagerie\binding",
    "$dst\messagerie\composants",
    "$dst\notifications\vue",
    "$dst\profil\profil_principal",
    "$dst\profil\cv\vue\cv_assistant_chat_parts",
    "$dst\profil\cv\vue\cv_import_parts",
    "$dst\profil\cv\vue\cv_manual_editor_parts",
    "$dst\profil\portfolio",
    "$dst\profil\donnees\models",
    "$dst\profil\donnees\repositories",
    "$dst\profil\composants",
    "$dst\profil\binding",
    "$dst\erreurs\vue"
)

foreach ($d in $dirs) {
    New-Item -ItemType Directory -Path $d -Force | Out-Null
}
Write-Host "Phase 1: Directories created."

# Phase 2: Copy files to new locations
# splash -> ecran_demarrage (flat)
Copy-Item "$src\splash\bindings\splash_binding.dart" "$dst\ecran_demarrage\"
Copy-Item "$src\splash\controllers\splash_controller.dart" "$dst\ecran_demarrage\"
Copy-Item "$src\splash\views\splash_screen.dart" "$dst\ecran_demarrage\"

# landing -> bienvenue (flat)
Copy-Item "$src\landing\bindings\landing_binding.dart" "$dst\bienvenue\"
Copy-Item "$src\landing\controllers\landing_controller.dart" "$dst\bienvenue\"
Copy-Item "$src\landing\views\landing_screen.dart" "$dst\bienvenue\"

# profile_selection -> selection_profil (flat)
Copy-Item "$src\profile_selection\bindings\profile_selection_binding.dart" "$dst\selection_profil\"
Copy-Item "$src\profile_selection\controllers\profile_selection_controller.dart" "$dst\selection_profil\"
Copy-Item "$src\profile_selection\views\profile_selection_screen.dart" "$dst\selection_profil\"

# auth -> authentification (sub-features)
Copy-Item "$src\auth\bindings\candidate_login_binding.dart" "$dst\authentification\connexion_candidat\"
Copy-Item "$src\auth\controllers\candidate_login_controller.dart" "$dst\authentification\connexion_candidat\"
Copy-Item "$src\auth\views\candidate_login_screen.dart" "$dst\authentification\connexion_candidat\"

Copy-Item "$src\auth\bindings\recruiter_login_binding.dart" "$dst\authentification\connexion_recruteur\"
Copy-Item "$src\auth\controllers\recruiter_login_controller.dart" "$dst\authentification\connexion_recruteur\"
Copy-Item "$src\auth\views\recruiter_login_screen.dart" "$dst\authentification\connexion_recruteur\"

Copy-Item "$src\auth\bindings\register_binding.dart" "$dst\authentification\inscription\"
Copy-Item "$src\auth\controllers\register_controller.dart" "$dst\authentification\inscription\"
Copy-Item "$src\auth\views\register_screen.dart" "$dst\authentification\inscription\"

Copy-Item "$src\auth\bindings\register_profile_binding.dart" "$dst\authentification\inscription_profil\"
Copy-Item "$src\auth\controllers\register_profile_controller.dart" "$dst\authentification\inscription_profil\"
Copy-Item "$src\auth\views\register_profile_screen.dart" "$dst\authentification\inscription_profil\"

Copy-Item "$src\auth\controllers\otp_verification_controller.dart" "$dst\authentification\verification_otp\"
Copy-Item "$src\auth\views\otp_verification_screen.dart" "$dst\authentification\verification_otp\"

Copy-Item "$src\auth\controllers\forgot_password_controller.dart" "$dst\authentification\mot_de_passe_oublie\"
Copy-Item "$src\auth\views\forgot_password_screen.dart" "$dst\authentification\mot_de_passe_oublie\"
Copy-Item "$src\auth\views\forgot_password_reset_screen.dart" "$dst\authentification\mot_de_passe_oublie\"

# home -> accueil
Copy-Item "$src\home\bindings\home_binding.dart" "$dst\accueil\binding\"
Copy-Item "$src\home\controllers\home_controller.dart" "$dst\accueil\controleur\"
Copy-Item "$src\home\controllers\home_profile_manager.dart" "$dst\accueil\controleur\"
Copy-Item "$src\home\controllers\home_controller_parts\*" "$dst\accueil\controleur\home_controller_parts\" -Recurse
Copy-Item "$src\home\controllers\home_profile_manager_parts\*" "$dst\accueil\controleur\home_profile_manager_parts\" -Recurse
Copy-Item "$src\home\views\home_screen.dart" "$dst\accueil\vue\"
Copy-Item "$src\home\views\home_profile_tab.dart" "$dst\accueil\vue\"
Copy-Item "$src\home\views\home_training_flow.dart" "$dst\accueil\vue\"
Copy-Item "$src\home\views\home_formation_detail_page.dart" "$dst\accueil\vue\"
Copy-Item "$src\home\views\home_screen_parts\*" "$dst\accueil\vue\home_screen_parts\" -Recurse
Copy-Item "$src\home\views\home_profile_parts\*" "$dst\accueil\vue\home_profile_parts\" -Recurse
Copy-Item "$src\home\views\home_training_parts\*" "$dst\accueil\vue\home_training_parts\" -Recurse
Copy-Item "$src\home\views\home_formation_detail_parts\*" "$dst\accueil\vue\home_formation_detail_parts\" -Recurse
Copy-Item "$src\home\data\models\*" "$dst\accueil\donnees\models\" -Recurse

# offers -> offres
Copy-Item "$src\offers\bindings\offers_binding.dart" "$dst\offres\liste_offres\"
Copy-Item "$src\offers\controllers\offers_controller.dart" "$dst\offres\liste_offres\"
Copy-Item "$src\offers\views\offers_screen.dart" "$dst\offres\liste_offres\"
Copy-Item "$src\offers\bindings\offer_detail_binding.dart" "$dst\offres\detail_offre\"
Copy-Item "$src\offers\controllers\offer_detail_controller.dart" "$dst\offres\detail_offre\"
Copy-Item "$src\offers\views\offer_detail_screen.dart" "$dst\offres\detail_offre\"
Copy-Item "$src\offers\views\my_applications_screen.dart" "$dst\offres\mes_candidatures\"
Copy-Item "$src\offers\data\models\*" "$dst\offres\donnees\models\" -Recurse
Copy-Item "$src\offers\data\repositories\*" "$dst\offres\donnees\repositories\" -Recurse
Copy-Item "$src\offers\utils\*" "$dst\offres\utilitaires\" -Recurse

# trainings -> formations
Copy-Item "$src\trainings\bindings\trainings_binding.dart" "$dst\formations\liste_formations\"
Copy-Item "$src\trainings\controllers\trainings_controller.dart" "$dst\formations\liste_formations\"
Copy-Item "$src\trainings\views\trainings_screen.dart" "$dst\formations\liste_formations\"
Copy-Item "$src\trainings\bindings\training_detail_binding.dart" "$dst\formations\detail_formation\"
Copy-Item "$src\trainings\controllers\training_detail_controller.dart" "$dst\formations\detail_formation\"
Copy-Item "$src\trainings\views\training_detail_screen.dart" "$dst\formations\detail_formation\"
Copy-Item "$src\trainings\views\training_payment_screen.dart" "$dst\formations\detail_formation\"
Copy-Item "$src\trainings\data\models\*" "$dst\formations\donnees\models\" -Recurse
Copy-Item "$src\trainings\data\repositories\*" "$dst\formations\donnees\repositories\" -Recurse

# messages -> messagerie
Copy-Item "$src\messages\bindings\messages_binding.dart" "$dst\messagerie\binding\"
Copy-Item "$src\messages\controllers\messages_controller.dart" "$dst\messagerie\controleur\"
Copy-Item "$src\messages\views\messages_screen.dart" "$dst\messagerie\vue\"
Copy-Item "$src\messages\data\models\*" "$dst\messagerie\donnees\models\" -Recurse
Copy-Item "$src\messages\data\repositories\*" "$dst\messagerie\donnees\repositories\" -Recurse

# notifications
Copy-Item "$src\notifications\views\notifications_screen.dart" "$dst\notifications\vue\"

# profile -> profil
Copy-Item "$src\profile\bindings\profile_binding.dart" "$dst\profil\binding\"
Copy-Item "$src\profile\controllers\profile_controller.dart" "$dst\profil\profil_principal\"
Copy-Item "$src\profile\views\profile_screen.dart" "$dst\profil\profil_principal\"
Copy-Item "$src\profile\views\profile_edit_screen.dart" "$dst\profil\profil_principal\"
Copy-Item "$src\profile\controllers\cv_builder_controller.dart" "$dst\profil\cv\"
Copy-Item "$src\profile\views\cv_screen.dart" "$dst\profil\cv\vue\"
Copy-Item "$src\profile\views\cv_builder_landing_screen.dart" "$dst\profil\cv\vue\"
Copy-Item "$src\profile\views\cv_assistant_chat_screen.dart" "$dst\profil\cv\vue\"
Copy-Item "$src\profile\views\cv_import_screen.dart" "$dst\profil\cv\vue\"
Copy-Item "$src\profile\views\cv_manual_editor_screen.dart" "$dst\profil\cv\vue\"
Copy-Item "$src\profile\views\cv_preview_screen.dart" "$dst\profil\cv\vue\"
Copy-Item "$src\profile\views\cv_assistant_chat_parts\*" "$dst\profil\cv\vue\cv_assistant_chat_parts\" -Recurse
Copy-Item "$src\profile\views\cv_import_parts\*" "$dst\profil\cv\vue\cv_import_parts\" -Recurse
Copy-Item "$src\profile\views\cv_manual_editor_parts\*" "$dst\profil\cv\vue\cv_manual_editor_parts\" -Recurse
Copy-Item "$src\profile\views\portfolio_screen.dart" "$dst\profil\portfolio\"
Copy-Item "$src\profile\views\portfolio_edit_screen.dart" "$dst\profil\portfolio\"
Copy-Item "$src\profile\data\models\*" "$dst\profil\donnees\models\" -Recurse
Copy-Item "$src\profile\data\repositories\*" "$dst\profil\donnees\repositories\" -Recurse

# errors -> erreurs
Copy-Item "$src\errors\views\error_404_screen.dart" "$dst\erreurs\vue\"

Write-Host "Phase 2: Files copied."
Write-Host "Migration complete! Now update imports in the copied files."
