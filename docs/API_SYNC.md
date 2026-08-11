# Sync API Flutter ↔ Laravel

Source de vérité backend : `projet_de_l-emploi/routes/api.php` (préfixe `/api/v1`).

Dernière revue : **2026-08-11**.

## Résumé

| Catégorie | État |
|-----------|------|
| Auth, profil, candidatures, entretiens | OK |
| Offres, formations, quiz | OK |
| Messagerie (sans notes vocales) | OK |
| Communauté, stories, IA | OK |
| Notifications + FCM token | OK |
| Dashboard candidat, alertes | OK |

## Écarts connus (non bloquants)

| Endpoint backend | Flutter | Note |
|------------------|---------|------|
| `POST/DELETE /contests/{id}/save` | `contestSave` / `contestUnsave` | Module concours non implémenté — volontaire |
| `GET /contests`, `GET /contests/{id}` | constantes présentes | Idem |

## Corrigé récemment

- **Inscription** : champ `candidate_kind` (plus `registration_profile`)
- **Notes vocales** : retirées côté app (route backend absente)

## Process de resync (à chaque sprint backend)

1. Diff `routes/api.php` ↔ `lib/app/core/constants/api_constants.dart`
2. Vérifier payloads des POST critiques : register, apply, FCM, profil
3. `flutter analyze lib/` + `flutter test`
4. Mettre à jour ce fichier

## Vérification rapide

```powershell
cd E:\laragon\www\appli_pour_lemploie
flutter analyze lib/
flutter test
```
