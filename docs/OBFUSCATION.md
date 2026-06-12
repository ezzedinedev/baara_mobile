# Obfuscation & protection du code — OpporTune BF

Ce document couvre la protection du code des **deux** projets :

- **App Flutter** (`appli_pour_lemploie`) — livrée sur les téléphones → l'obfuscation
  apporte un vrai gain de sécurité.
- **Backend Laravel** (`projet_de_l-emploi`) — tourne sur le serveur, jamais livré
  au client → l'obfuscation PHP a un intérêt **très limité**. On privilégie le
  **durcissement**. (Voir aussi `projet_de_l-emploi/docs/OBFUSCATION.md`.)

---

## 1. Flutter — Obfuscation Dart (RECOMMANDÉ, mis en place)

### Pourquoi
Un APK/AAB est un fichier que n'importe qui peut télécharger et décompiler. Sans
obfuscation, les noms de classes, méthodes et variables Dart sont lisibles. Le flag
`--obfuscate` les remplace par des identifiants aléatoires, ce qui complique
fortement le reverse engineering. `--split-debug-info` sort les symboles de debug
de l'app (réduit aussi la taille).

> ⚠️ L'obfuscation ne remplace PAS le chiffrement des secrets. Ne mettez jamais de
> clé d'API / secret en dur dans le code Dart, même obfusqué (les chaînes restent
> extractibles). Les secrets doivent venir du backend ou d'un stockage sécurisé.

### Commande de référence
```bash
flutter build apk       --release --obfuscate --split-debug-info=build/symbols/<version>
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols/<version>
flutter build ipa       --release --obfuscate --split-debug-info=build/symbols/<version>   # iOS (macOS requis)
```
`--obfuscate` **doit toujours** être combiné à `--split-debug-info` (sinon Flutter
refuse). Le dossier de symboles contient le mapping permettant de désobfusquer.

### Script fourni
Utilisez le script reproductible plutôt que de taper les commandes à la main. Il
lit la version depuis `pubspec.yaml`, crée `build/symbols/<version>/`, lance les
builds et rappelle d'archiver les symboles.

```powershell
# Windows / PowerShell — apk + appbundle (défaut)
./scripts/build_release.ps1
# cibles explicites (+ iOS si sur macOS)
./scripts/build_release.ps1 -Targets apk,appbundle,ios
```
```bash
# macOS / Linux / Git Bash
./scripts/build_release.sh
./scripts/build_release.sh apk appbundle ios
```

### Symboles de debug — CRITIQUE
Le dossier `build/symbols/<version>/` contient les fichiers `app.*.symbols` /
`*.map.json`. **Ils sont sensibles** : ils permettent de désobfusquer les stack
traces. Règles :

1. **Ne JAMAIS les commiter dans un dépôt public.** Ils sont ignorés par
   `.gitignore` (`build/symbols/`, `*.symbols`, `*.map.json`, `/build/`).
2. **Mais il faut les ARCHIVER** : sans eux, impossible de lire un crash de prod.
   Où les archiver :
   - Stockage privé chiffré (Google Drive privé d'équipe, bucket S3 privé,
     coffre-fort de secrets, ou un dépôt Git **privé** dédié aux artefacts).
   - Organisés par version (`1.0.0+1/`, `1.0.1+2/`…) — chaque release publiée a
     son propre jeu de symboles ; un symbole ne désobfusque QUE le build qui l'a
     produit.

### Désobfuscation manuelle d'une stack trace
```bash
flutter symbolize -i <stacktrace_obfusquee.txt> -d build/symbols/<version>/app.android-arm64.symbols
```

### Crashlytics — désymbolisation (utilisé dans ce projet)
Le projet utilise `firebase_crashlytics` et a déjà le plugin Gradle Crashlytics
configuré dans `android/app/build.gradle.kts`
(`id("com.google.firebase.crashlytics")`).

- **Android** : pour des crashes **Dart obfusqués** lisibles dans la console
  Firebase, il faut **téléverser les symboles Dart** vers Crashlytics après chaque
  build release :
  ```bash
  firebase crashlytics:symbols:upload --app=<FIREBASE_APP_ID> build/symbols/<version>
  ```
  (nécessite la CLI Firebase : `npm i -g firebase-tools`, puis `firebase login`).
  Le `<FIREBASE_APP_ID>` se trouve dans `google-services.json` (`mobilesdk_app_id`)
  ou dans la console Firebase (Paramètres du projet → vos apps).
  > Le plugin Gradle Crashlytics gère le mapping **NDK/natif**, mais le mapping
  > **Dart** (`--obfuscate`) doit être poussé via `crashlytics:symbols:upload`.
- **iOS** : les dSYM sont téléversés par le plugin Firebase au build/à l'archivage ;
  les symboles **Dart** se téléversent de la même façon avec
  `firebase crashlytics:symbols:upload`.
- Conservez le dossier `build/symbols/<version>/` **même après upload** (backup).

### Bonnes pratiques Flutter
- Toujours builder les releases via le script (obfuscation systématique).
- Une version = un jeu de symboles archivé.
- Ne jamais dépendre, en code de prod, de `runtimeType`, `Type.toString()`,
  `Enum.toString()` ou des noms de symboles : l'obfuscation les rend aléatoires.
- (Optionnel, défense en profondeur Android) activer R8/ProGuard côté natif via
  `minifyEnabled`/`shrinkResources` dans `build.gradle.kts`. Non activé ici pour ne
  rien casser ; à tester séparément si souhaité.

---

## 2. Laravel — voir le document dédié
La stratégie backend (durcissement vs obfuscation PHP, recommandation chiffrée,
scripts de déploiement) est détaillée dans :

**`projet_de_l-emploi/docs/OBFUSCATION.md`**

TL;DR : **ne pas obfusquer le PHP** (gain sécurité quasi nul, casse Eloquent /
réflexion / facades / `config:cache`). Faire à la place : `APP_DEBUG=false`,
`APP_ENV=production`, `composer install --no-dev --optimize-autoloader`,
`php artisan config:cache route:cache view:cache event:cache`, et garder `.env` /
clés / `storage` hors du dépôt et hors du web. Scripts fournis : `scripts/deploy.*`.
