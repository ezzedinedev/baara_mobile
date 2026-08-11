# Firebase — Baara.bf (prod)

État actuel : projet **playground** `flutter-ai-playground-e84b5` (FCM / Crashlytics OK en dev).

## Identifiants à aligner avant store

| Plateforme | Bundle / package actuel | Firebase client |
|------------|-------------------------|-----------------|
| Android    | `com.Baara.bf`          | OK dans `google-services.json` |
| iOS        | `com.opportune.bf`      | OK dans `GoogleService-Info.plist` |

Décision produit : garder `com.opportune.bf` sur iOS **ou** migrer vers `com.Baara.bf` (nécessite nouvelle app Firebase + certificats).

## Passage prod (FlutterFire CLI)

1. Créer le projet Firebase **Baara** (console Firebase).
2. Enregistrer Android `com.Baara.bf` et iOS (bundle choisi).
3. Télécharger et remplacer :
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
4. Régénérer les options Dart :

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=<PROJECT_ID_BAARA>
```

5. Vérifier `lib/firebase_options.dart` et `main.dart` (`Firebase.initializeApp(options: …)`).
6. Tester FCM : login → onboarding terminé → permission push → notification test depuis la console.

## Fichiers concernés

- `lib/firebase_options.dart`
- `lib/main.dart`
- `lib/app/core/services/fcm_service.dart` (canal `baara_default`)
- `android/app/build.gradle.kts` (plugin Google Services)
- `ios/Runner/AppDelegate.swift` (remote notifications)

## Notes

- Ne pas committer de clés de service account (Admin SDK) — seulement les fichiers client mobile ci-dessus.
- Le playground peut rester pour CI / builds internes ; utiliser des flavors si besoin (dev / prod).
