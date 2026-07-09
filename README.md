# OpporTune BF — Application mobile

Client Flutter **candidat** pour la plateforme [OpporTune BF](https://opportunebf.com) : offres d'emploi, candidatures, formations, messagerie temps réel, communauté et assistants IA.

Le backend Laravel (`projet_de_l-emploi`) et la base MySQL ne sont **pas** dans ce dépôt — voir `database_tables.md` pour le schéma documenté.

## Prérequis

- Flutter SDK `>=3.3.0` (voir `pubspec.yaml`)
- Backend Laravel accessible (local ou `https://api.opportunebf.com`)
- Pour le temps réel : daemon Laravel Reverb

## Démarrage rapide

```bash
flutter pub get
flutter run
```

### Backend local + émulateur Android

```powershell
./scripts/start_laravel_for_emulator.ps1
flutter run
```

L'API est résolue automatiquement vers `10.0.2.2:8000` sur l'émulateur Android en mode debug.

## Variables de build (`--dart-define`)

| Variable | Description |
|----------|-------------|
| `API_BASE_URL` | URL API complète (ex. `http://10.0.2.2:8000/api/v1`) |
| `PRODUCTION_API_BASE_URL` | URL prod par défaut si non debug |
| `REVERB_APP_KEY` | Clé Reverb (**obligatoire en release**) |
| `REVERB_HOST` | Hôte Reverb (optionnel, dérivé de l'API sinon) |

Exemple release :

```bash
flutter build apk --release \
  --dart-define=REVERB_APP_KEY=votre_cle \
  --obfuscate --split-debug-info=build/symbols
```

Ou via le script PowerShell : `./scripts/build_release.ps1`

## Architecture

```
lib/
├── main.dart
├── routes/                 # Routes GetX
└── app/
    ├── bindings/           # InitialBinding (API, auth, realtime, offline queue)
    ├── core/               # Theme, réseau, services, widgets partagés
    └── features/           # Modules feature-first (auth, offers, messaging…)
        └── <feature>/
            ├── domain/     # Entités + interfaces repository
            ├── data/       # Implémentations API
            └── presentation/
```

**Stack** : GetX (état, routing, DI), `http`, Firebase (FCM, Crashlytics), Reverb/WebSocket, `flutter_secure_storage`.

## Tests

```bash
flutter analyze
flutter test
```

## Documentation

- `docs/DESIGN_SYSTEM.md` — tokens, composants UI
- `docs/OBFUSCATION.md` — builds release obfusqués
- `lib/app/core/constants/api_constants.dart` — contrat API vivant

## CI

GitHub Actions : analyse stricte + tests + build APK release obfusqué (`.github/workflows/ci.yml`).
