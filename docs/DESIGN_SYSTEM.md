# Design System — Baara (langage visuel 2026)

Référence unique du système de design Flutter de l'application. Le but est de
**verrouiller la cohérence** : tout écran doit puiser dans ces tokens et
composants, jamais dans des valeurs en dur. Le langage visuel « 2026 » (verre,
squircle, motion ressort, dark-aware) est la signature de l'app et **ne doit pas
être remplacé** par des composants Material/Cupertino stock ; on renforce
seulement les **fondamentaux objectifs** de Material Design 3 (Android) et Apple
HIG (iOS) à l'intérieur de ce langage.

Emplacements clés :

- Tokens : `lib/app/core/theme/`
- Composants communs : `lib/app/core/widgets/` (barrel : `widgets.dart`)

---

## 1. Tokens

### 1.1 Couleurs — `app_colors.dart`

Toutes les couleurs sont des **getters** (pas des `const`) dès qu'elles doivent
être **dark-aware** : elles lisent `AppThemeController.isDarkMode` et renvoient la
teinte adaptée. Les valeurs purement fixes (marque, catégories) restent `const`.

> Règle d'or : **jamais de `Color(0x…)` ni de `Colors.red/green/…` dans un
> écran.** Toujours `AppColors.*`. (Une seule exception héritée tolérée :
> dégradé de remplacement du lecteur vidéo.)

#### Rôles principaux

| Token | Rôle |
|---|---|
| `primary`, `primaryMedium`, `primaryDark`, `primaryLight` | Vert de marque (fonds de boutons, dégradés). |
| `primaryAccent` | Vert de marque **en premier-plan** (texte/icône/bordure). Éclairci en dark pour rester lisible. À NE PAS utiliser comme fond plein portant du texte blanc. |
| `secondary`, `secondaryDeep`, `secondaryMid`, `secondarySoft` | Accent olive/secondaire. |
| `background` | Fond d'écran. |
| `surfaceLow` → `surfaceHighest` | Rampe de surfaces par élévation (du plus bas au plus haut). |
| `surfaceCard` | Fond des cartes. |
| `surfaceContainer`, `surfaceSelected`, `surfaceIconSoft` | Conteneurs, sélection, pastilles d'icône. |
| `inputFill` | Fond des champs de saisie. |
| `outlineVariant` | Bordures / diviseurs (theme-aware). |

#### Texte

| Token | Rôle |
|---|---|
| `titleColor` | Titres (blanc adouci en dark, pas de blanc pur). |
| `bodyColor` | Corps de texte. |
| `hintColor` | Texte secondaire / placeholder. |
| `onPrimary` | Texte/icône sur fond de marque (blanc). |
| `onDark` | Texte sur surface sombre immersive. |

#### États (sémantiques)

| Plein (fond) | Accent (premier-plan) | Soft (fond pastel) |
|---|---|---|
| `error` | `errorAccent` | `errorSoft` |
| `success` | `successAccent` | `successSoft` |
| `warning` | `warningAccent` | `warningSoft` |

Même principe que `primary`/`primaryAccent` : les variantes **`*Accent`** sont
éclaircies en dark pour le texte/icône ; les versions pleines servent de fond.

#### Catégories, boost, paiements, social

- `categoryBlue/Pink/Purple/Orange/Cyan/Yellow/Gray` (+ `*Soft`, `*Deep`) :
  codage couleur des catégories.
- `boostGold/Amber/Soft` + `onBoost*` : paliers de mise en avant d'offre
  (aligné sur le web).
- `paymentOrangeMoney`, `paymentWave` : marques de paiement.
- `socialGoogle*`, `socialLinkedIn` : marques de connexion sociale.
- `celebrationGreen/Gold` : confetti / match.

#### Dégradés & ombres

- Dégradés de marque : `primaryGradient`, `headerBrandGradient`,
  `recruiterGradient`, et la famille `hero*Gradient` (un par section : accueil,
  offres, formations, messages, notifications, profil).
- Mesh doux : `meshBrand`, `meshBrandGlow` (halos de hero).
- Ombres : `ambientShadow` (ombre portée douce de carte), `lightShadow` (ombre
  légère), `glowShadow` (halo de marque). **Toujours** passer par ces listes,
  jamais de `BoxShadow` en dur.
- Avatars : `avatarPalette` + `avatarGradientForSeed(seed)` (couleur stable par
  utilisateur).

### 1.2 Typographie — `app_text_styles.dart`

Échelle unique en getters (Manrope pour titres/labels, Inter pour le corps),
couleur déjà câblée sur les tokens dark-aware.

| Style | Usage |
|---|---|
| `displayXl` / `displayLg` / `displayMd` | Très grands titres. |
| `displayHero` / `displayXxl` | Hero éditorial 2026 (poids 800/900, tracking serré). |
| `heroNumber` | Chiffre clé en avant (scores, compteurs). |
| `headlineLg` / `headlineMd` / `headlineSm` | Titres de section. |
| `titleLg` / `titleMd` | Titres de carte / sous-titres. |
| `bodyLg` / `bodyMd` / `bodySm` | Corps de texte. |
| `labelLg` / `labelMd` / `labelSm` | Labels, surtitres, métadonnées. |
| `buttonLg` / `buttonMd` | Libellés de boutons. |

> Règle : pour styliser du texte, partir d'un style `AppTextStyles` et ajuster
> via `.copyWith(...)` ponctuel. Éviter de reconstruire un `TextStyle(fontSize:
> …)` à la main : cela **fige la taille** et casse le *dynamic type*
> (accessibilité). Ces styles n'imposent pas de `textScaleFactor`, ils suivent
> donc le réglage système.

### 1.3 Espacements — `app_dimens.dart` (`AppSpacing`)

`xs 4` · `sm 8` · `md 12` · `lg 16` · `xl 20` · `xxl 24` · `pageH 16`
(padding horizontal de page).

### 1.4 Rayons & formes — `AppRadius` + `app_shapes.dart`

Rayons : `xs 8` · `sm 12` · `md 16` · `lg 20` · `xl 24` · `xxl 32` ·
`sheetTop 36` · `pill 999`.

Formes **squircle** (coins continus, look Apple) via `AppShapes` :

- `AppShapes.squircle(radius)` → `ShapeBorder` continu.
- `AppShapes.squircleRadius(radius)` → `BorderRadius` continu (pour
  `Container`/`ClipRRect`).
- Raccourcis : `AppShapes.card`, `cardBordered(color)`, `sheet`, `cardRadius`,
  `bentoRadius`, `pill`.

Le facteur `1.7` (rayon perçu → rayon continu) est interne ; ne jamais le
réécrire à la main.

### 1.5 Motion — `app_motion.dart`

- Durées : `fast 180` · `base 260` · `slow 360` · `short 200` · `medium 350` ·
  `long 500` · `stagger 40`.
- Courbes Material 3 Expressive : `emphasized`, `emphasizedDecelerate`,
  `emphasizedAccelerate`.
- Ressorts : `spring` (release de press, sélection nav), `springEmphasized`
  (hero, count-up, badges).

> Le motion doit rester **vivant mais calme** : ressort doux, pas de rebond
> excessif. Respecter `disableAnimations` / `accessibleNavigation` (déjà géré
> par `PressScale`).

---

## 2. Composants communs

Tous exportés via `lib/app/core/widgets/widgets.dart`. Importer le barrel.

### Structure & surfaces

- **`AppCard`** — carte standard (surface, squircle, ombre ambient). Conteneur
  par défaut d'un bloc de contenu.
- **`GlassSurface`** — surface « verre » (blur + voile). **À réserver à la
  chrome** (top bars, sheets, overlays) : le blur sur de grandes listes coûte
  cher et brouille la lisibilité.
- **`BrandCard`**, **`GlassChip`** — variantes de marque / puces en verre.
- **`SankSheetScaffold` / `SankTabShell`** — échafaudage de bottom-sheets et de
  shells à onglets de l'app.
- **`SheetHandle`** — poignée de bottom-sheet.

### Interaction

- **`PressScale`** — enveloppe tappable standard (scale + haptique + ressort au
  release). Respecte le *reduce motion*. À utiliser pour rendre n'importe quel
  visuel pressable.
- **`AppIconButton`** — bouton-icône discret. Zone tactile garantie **≥ 44×44**
  (hit-area), `tooltip` ⇒ libellé d'accessibilité, rôle bouton exposé.
- **`AppBackButton`** — bouton retour circulaire 44×44, libellé « Retour », bâti
  sur `Material`/`InkWell`.
- **`GradientButton`**, **`AuthCtaButton`** — boutons d'action primaires
  (dégradé de marque, état loading branded).
- **`SoftCircleIcon`** — icône dans une pastille pastel (listes Paramètres).

### Saisie

- **`InputField`**, **`LabeledInput`**, **`AuthTextField`**, **`AppSearchBar`** —
  champs câblés sur `inputFill` / `outlineVariant`. Toujours sous un ancêtre
  `Material` (garde-fou Flutter).

### Indicateurs & affichage

- **`AppLoader`** — **loader générique adaptatif** (spinner Cupertino sur iOS,
  Material sur Android). À utiliser pour **tout chargement indéterminé** de page,
  section ou liste. Mappe la couleur de marque à la fois sur `valueColor`
  (Material) et `backgroundColor` (teinte Cupertino).
- **`StatusPill`** — pastille d'état (couleur sémantique + label).
- **`ScoreRing`** — anneau de score / progression **déterminée**.
- **`BrandAvatar`** — avatar avec dégradé stable par seed + fallback.
- **`SectionLabel`**, **`SectionHeader`**, **`AppSubHeader`** — surtitres et
  en-têtes de section.

### États

- **`EmptyState`** — état vide (icône pastel + titre + sous-titre, action
  optionnelle).
- **`ErrorState`** — état d'erreur avec **retry**.
- **Skeletons** (`skeletons/…`) — placeholders de chargement par type d'écran
  (offres, formations, messages, chat, notifications, posts, page générique).
  Préférer un **skeleton** au spinner sur le **premier** chargement d'une liste ;
  réserver `AppLoader` au chargement de **page suivante** / actions ponctuelles.

### Toasts & confirmation

- **`AppToast`** — notifications opaques de la charte.
- **`ConfirmSheet`** — feuille de confirmation (préférée aux dialogs pour les
  actions destructrices riches).

---

## 3. Alignement Material Design 3 (Android) & Apple HIG (iOS)

### 3.1 Cibles tactiles (MD3 ≥ 48dp, HIG ≥ 44pt)

- Toute zone tappable garantit **≥ 44×44** *sans* forcément agrandir le visuel
  (hit-area ≥ visuel).
- `AppIconButton` et `AppBackButton` appliquent ce minimum via
  `BoxConstraints(minWidth: 44, minHeight: 44)` / `SizedBox(44)`.
- Pour un bouton-icône custom : envelopper dans `PressScale` + `ConstrainedBox`
  (min 44) ; ne **pas** grossir l'icône elle-même.

### 3.2 Accessibilité

- **Boutons icône-only** : exposer un `Semantics(button: true, label: …)` (FR
  clair) — fait par défaut dans `AppIconButton` (via `tooltip`),
  `AppBackButton` (« Retour »), boutons d'envoi de message/commentaire.
- **Images** : libellé pour les images significatives ; `excludeSemantics` /
  label vide pour les décoratives.
- **Dynamic type** : utiliser `AppTextStyles` (pas de `fontSize` figé hors
  `copyWith` justifié) pour suivre la mise à l'échelle système.
- **Contraste** : rester dans les tokens ; `titleColor`/`bodyColor`/`hintColor`
  sont calibrés clair **et** sombre.

### 3.3 Composants adaptatifs par plateforme

Appliquer l'adaptatif **uniquement** aux composants génériques, pas aux écrans
custom :

- **Loaders génériques** → `AppLoader` (ou `CircularProgressIndicator.adaptive`).
  ⚠️ `.adaptive` n'a **pas** de paramètre `color` : passer la teinte via
  `valueColor` **et** `backgroundColor` — c'est exactement ce que centralise
  `AppLoader`.
- **Switches** → `Switch.adaptive` / `SwitchListTile.adaptive`.
- **Dialogs de confirmation simples** → `showAdaptiveDialog` +
  `AlertDialog.adaptive`.
- **Anneaux de progression déterminés** (`value != null`) : garder un
  `CircularProgressIndicator` classique (le spinner iOS n'a pas de mode
  déterminé visuel équivalent).
- **Scroll physics** : laisser Flutter adapter par défaut.
- **`SafeArea`** : présent sur les écrans plein écran.

### 3.4 Dark mode

Piloté par `AppThemeController`. Les tokens dark-aware (getters) renvoient
automatiquement la bonne teinte ; **ne jamais** coder une couleur en dur qui
casserait le dark. Le dark relève légèrement les surfaces (élévation lisible) et
adoucit le texte (pas de blanc pur).

### 3.5 Principes visuels

- **Hiérarchie** : profondeur par la rampe de surfaces + ombres tokenisées, pas
  par des couleurs arbitraires.
- **Profondeur verre** : blur réservé à la chrome.
- **Mouvement** : ressort doux (`AppMotion.spring`) au relâchement, transitions
  emphasized pour les composants.

---

## 4. Règles do / don't

**À faire**

- Couleurs, textes, espacements, rayons, motion, ombres : **toujours** via
  `AppColors` / `AppTextStyles` / `AppSpacing` / `AppRadius` / `AppShapes` /
  `AppMotion`.
- Zone tactile **≥ 44×44** sur tout élément pressable.
- Libellé d'accessibilité sur les boutons icône-only.
- Squircle (`AppShapes`) pour les cartes/feuilles ; `pill` pour les capsules.
- `AppLoader` pour les loaders génériques.
- Champs de saisie / `InkWell` sous un ancêtre `Material`.

**À éviter**

- `Color(0x…)`, `Colors.red/green/…`, `BoxShadow` ou `fontSize` en dur dans un
  écran.
- Remplacer un composant custom 2026 par du stock Material/Cupertino.
- `GlassSurface` (blur) sur de grandes listes / au-delà de la chrome.
- `CircularProgressIndicator.adaptive(color: …)` (paramètre inexistant) —
  utiliser `AppLoader`.
- Grossir une icône pour atteindre 44 : agrandir la **hit-area**, pas le visuel.
- Figer des hauteurs incompatibles avec le *dynamic type*.
