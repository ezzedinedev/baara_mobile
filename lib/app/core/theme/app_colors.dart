import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_theme_controller.dart';

class AppColors {
  AppColors._();
  static const Color primary = Color(0xFF0E8A4D);
  static const Color primaryLight = Color(0xFFB7ECC9);
  static const Color primaryMedium = Color(0xFF2BA55B);
  static const Color primaryDark = Color(0xFF0A5E36);
  static const Color secondary = Color(0xFF2BA55B);
  static const Color secondaryDeep = Color(0xFF0A5E36);
  static const Color secondaryMid = Color(0xFF4FBE7C);
  static Color get secondarySoft =>
      _isDark ? const Color(0xFF183631) : const Color(0xFFE5F2EF);

  static bool get _isDark =>
      Get.isRegistered<AppThemeController>() &&
      Get.find<AppThemeController>().isDarkMode.value;

  /// Noir intense (AMOLED) : actif uniquement en dark. Lit le controller, false
  /// si non enregistré (sécurité splash / tests).
  static bool get _amoled =>
      _isDark &&
      Get.isRegistered<AppThemeController>() &&
      Get.find<AppThemeController>().amoled.value;

  /// Graine d'accent choisie par l'utilisateur (fallback [primary] si le
  /// controller n'est pas encore monté).
  static Color get _accentSeed => Get.isRegistered<AppThemeController>()
      ? Get.find<AppThemeController>().accentSeed.value
      : primary;

  /// Éclaircit une couleur en espace HSL (clamp 0..1). Sert à relever l'accent
  /// en dark pour garder lisibilité et vivacité sur surface sombre.
  static Color _lighten(Color base, double amount) {
    final hsl = HSLColor.fromColor(base);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// Presets d'accent proposés dans les Paramètres (Apparence). Constantes de
  /// couleur (tokens) : le vert de marque + 5 dérivés des tokens « category ».
  /// Pas de roue chromatique libre → on garde la cohérence de la charte.
  static const List<Color> accentPresets = [
    primary,
    categoryBlue,
    categoryPurple,
    categoryCyan,
    categoryOrange,
    categoryPink,
  ];

  /// Accent de PREMIER-PLAN (texte/icône/bordure/nav active) dérivé du choix
  /// utilisateur ([_accentSeed]). En dark on l'éclaircit (~+14 % L) pour rester
  /// lisible et vivant ; en light c'est la graine telle quelle. À NE PAS
  /// utiliser comme fond de bouton (garder [primary] pour les fills de marque).
  static Color get primaryAccent {
    final base = _accentSeed;
    return _isDark ? _lighten(base, 0.14) : base;
  }

  // Rampe dark : base légèrement relevée (moins « trou noir »), pas vers le
  // haut réguliers (~+6 L*) pour une élévation lisible et calme. En AMOLED,
  // les fonds basculent vers le vrai noir / quasi-noir (paliers très sombres).
  static Color get background => _amoled
      ? const Color(0xFF000000)
      : (_isDark ? const Color(0xFF0F1518) : const Color(0xFFF7F8FA));
  static Color get surfaceLow => _amoled
      ? const Color(0xFF070809)
      : (_isDark ? const Color(0xFF161E21) : const Color(0xFFF1F5F4));
  static Color get inputFill => _amoled
      ? const Color(0xFF0D0F10)
      : (_isDark ? const Color(0xFF1B2427) : const Color(0xFFF3F6F6));
  static Color get surfaceCard => _amoled
      ? const Color(0xFF0D0F10)
      : (_isDark ? const Color(0xFF1A2326) : const Color(0xFFFFFFFF));
  static Color get surfaceContainer => _amoled
      ? const Color(0xFF121517)
      : (_isDark ? const Color(0xFF222C2F) : const Color(0xFFEEF3F2));
  static Color get surfaceHigh => _amoled
      ? const Color(0xFF181B1D)
      : (_isDark ? const Color(0xFF2A3539) : const Color(0xFFE5ECEB));
  static Color get surfaceHighest => _amoled
      ? const Color(0xFF202427)
      : (_isDark ? const Color(0xFF333F43) : const Color(0xFFD8E2E1));
  static Color get surfaceSelected =>
      _isDark ? const Color(0xFF15322E) : const Color(0xFFE7F4F1);
  static Color get surfaceIconSoft =>
      _isDark ? const Color(0xFF183631) : const Color(0xFFE5F2EF);
  static Color get surfaceSplashMid =>
      _isDark ? const Color(0xFF10191B) : const Color(0xFFF8FBFA);
  static Color get surfaceSplashBottom =>
      _isDark ? const Color(0xFF0D1517) : const Color(0xFFEAF2F1);

  // Texte dark adouci : on évite le blanc pur (#F5F7F7 éblouit sur fond
  // sombre). ~90 % de blanc = lisible sans « brûler » les yeux.
  static Color get titleColor =>
      _isDark ? const Color(0xFFE6EBEA) : const Color(0xFF111827);
  static Color get bodyColor =>
      _isDark ? const Color(0xFFB6C0BE) : const Color(0xFF4B5563);
  static Color get hintColor =>
      _isDark ? const Color(0xFF879491) : const Color(0xFF8A94A6);
  static Color get onDark =>
      _isDark ? const Color(0xFF0A0F0B) : const Color(0xFF1B1C1A);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Bordure/diviseur theme-aware : en dark, un gris clair (#D7DEE3) jure ;
  // on prend une ligne sombre douce, juste au-dessus des surfaces.
  static Color get outlineVariant => _amoled
      ? const Color(0xFF1C1F21)
      : (_isDark ? const Color(0xFF2C3739) : const Color(0xFFD7DEE3));
  static const Color error = Color(0xFFBA1A1A);
  static const Color success = Color(0xFF2F7D5B);
  static const Color warning = Color(0xFFB45309);

  // Variantes PREMIER-PLAN theme-aware (texte/icône/bordure d'état sur surface
  // sombre). En dark, les états sombres (#BA1A1A, #2F7D5B, #B45309) vibrent /
  // manquent de lisibilité → on les éclaircit. En light == version pleine.
  // NE PAS utiliser comme fond plein portant du texte blanc (garder error/…).
  static Color get errorAccent => _isDark ? const Color(0xFFFF6B6B) : error;
  static Color get successAccent => _isDark ? const Color(0xFF4ED98A) : success;
  static Color get warningAccent => _isDark ? const Color(0xFFF2A93C) : warning;

  static const Color successStrong = Color(0xFF087443);
  static const Color successSwitch = Color(0xFF0F9D58);
  static const Color successDark = Color(0xFF00A86B);
  static const Color verified = Color(0xFF169B51);
  static const Color errorStrong = Color(0xFFB42318);
  static const Color errorBright = Color(0xFFFF1F3D);

  static Color get successSoft =>
      _isDark ? const Color(0xFF153320) : const Color(0xFFE7FFF4);
  static Color get successSoftAlt =>
      _isDark ? const Color(0xFF15331F) : const Color(0xFFE6F8EB);
  static Color get successSwitchTrack =>
      _isDark ? const Color(0xFF1E5B2C) : const Color(0xFFB9F4C5);
  static Color get warningSoft =>
      _isDark ? const Color(0xFF3A2A10) : const Color(0xFFFFF4DE);
  static Color get errorSoft =>
      _isDark ? const Color(0xFF3A1414) : const Color(0xFFFFF0F0);

  static const Color categoryBlue = Color(0xFF2B7FFF);
  static const Color categoryBlueLight = Color(0xFF5AD7FF);
  static const Color categoryPink = Color(0xFFEB4D8A);
  static const Color categoryPinkDeep = Color(0xFFB42369);
  static const Color categoryPurple = Color(0xFF7A5CFA);
  static const Color categoryPurpleDeep = Color(0xFF4F46E5);
  static const Color categoryOrange = Color(0xFFFF9D00);
  static const Color categoryOrangeDeep = Color(0xFFFF8A00);
  static const Color categoryCyan = Color(0xFF0CA6A6);
  static const Color categoryYellow = Color(0xFFFFC857);
  static const Color categoryGray = Color(0xFF374151);

  static Color get categoryBlueSoft =>
      _isDark ? const Color(0xFF102236) : const Color(0xFFE8F1FF);
  static Color get categoryPinkSoft =>
      _isDark ? const Color(0xFF3A1225) : const Color(0xFFFFE7F1);

  // Paliers de boost d'offre (aligne sur le web). Or (Pro) > ambre (Populaire) >
  // ambre soft (Essentiel). Opaques, fort contraste, lisibles sur degrade.
  static const Color boostGold = Color(0xFFE89400);
  static const Color onBoostGold = Color(0xFF2A1500);
  static const Color boostAmber = Color(0xFFF7B500);
  static const Color onBoostAmber = Color(0xFF1B1300);
  static const Color boostSoft = Color(0xFFFFF3D4);
  static const Color onBoostSoft = Color(0xFF8A5A00);

  static const Color celebrationGold = Color(0xFFFFEB3B);

  /// Confetti posé SUR le hero vert de marque (écran de match). Aucune teinte
  /// verte : les verts de la charte sont les couleurs mêmes du dégradé de fond,
  /// un confetti vert y est invisible.
  static const List<Color> celebrationOnBrandConfetti = [
    onPrimary,
    celebrationGold,
    categoryOrange,
    categoryPink,
    primaryLight,
  ];

  /// Confetti posé sur les surfaces de l'app (overlay de succès). Teintes
  /// contrastées en light comme en dark.
  static const List<Color> celebrationSurfaceConfetti = [
    primary,
    celebrationGold,
    categoryOrange,
    categoryPink,
    categoryBlue,
  ];

  // Surface sombre profonde pour overlays/dialogs immersifs (independante du
  // theme : ces surfaces restent sombres en light comme en dark).
  static const Color surfaceImmersive = Color(0xFF1A1C2E);

  static const Color paymentOrangeMoney = Color(0xFFFF7900);
  static const Color paymentWave = Color(0xFF1D9BF0);

  static Color get profileGradientTop =>
      _isDark ? const Color(0xFF182023) : const Color(0xFFFFFFFF);
  static Color get profileGradientMid =>
      _isDark ? const Color(0xFF121A1F) : const Color(0xFFF4F7FB);
  static Color get profileGradientBottom =>
      _isDark ? const Color(0xFF0F1719) : const Color(0xFFEEF6F4);

  static const Color recruiterStart = Color(0xFF2F8F83);
  static const Color recruiterEnd = Color(0xFF136F63);

  static const Color socialGoogleBlue = Color(0xFF4285F4);
  static const Color socialGoogleGreen = Color(0xFF34A853);
  static const Color socialGoogleYellow = Color(0xFFFBBC05);
  static const Color socialGoogleRed = Color(0xFFEA4335);
  static const Color socialLinkedIn = Color(0xFF0A66C2);

  static LinearGradient get primaryGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _isDark
            ? const [Color(0xFF2F8F83), Color(0xFF136F63)]
            : const [primaryMedium, primary],
      );
  static LinearGradient get headerBrandGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _isDark
            ? const [Color(0xFF0B2F3A), Color(0xFF11564F), Color(0xFF1B7E73)]
            : const [primaryDark, primary, primaryMedium],
        stops: const [0.0, 0.45, 1.0],
      );
  static LinearGradient get actionIconGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _isDark
            ? const [Color(0xFF2F8F83), Color(0xFF0B2F3A)]
            : const [primaryMedium, primary, primaryDark],
      );

  static LinearGradient get recruiterGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _isDark
            ? const [Color(0xFF2F8F83), Color(0xFF11564F)]
            : const [recruiterStart, recruiterEnd],
      );

  static LinearGradient get splashBackground => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [surfaceCard, surfaceSplashMid, surfaceSplashBottom],
        stops: const [0.0, 0.55, 1.0],
      );

  static LinearGradient get landingHeroGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _isDark
            ? const [Color(0xFF0B2F3A), Color(0xFF11564F), Color(0xFF1B7E73)]
            : const [primaryDark, primary, primaryMedium],
      );
  static LinearGradient get heroAccueilGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _isDark
            ? const [Color(0xFF0B2F3A), Color(0xFF11564F), Color(0xFF1B7E73)]
            : const [primaryDark, primary, primaryMedium],
        stops: const [0.0, 0.55, 1.0],
      );

  static LinearGradient get heroOffersGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _isDark
            ? const [Color(0xFF0B2A34), Color(0xFF11564F), Color(0xFF1B7E73)]
            : const [primaryMedium, primary, primaryDark],
        stops: const [0.0, 0.55, 1.0],
      );

  static LinearGradient get heroTrainingsGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _isDark
            ? const [Color(0xFF0E2B34), Color(0xFF11564F), Color(0xFF1B7E73)]
            : const [primary, primaryMedium, secondary],
        stops: const [0.0, 0.55, 1.0],
      );

  static LinearGradient get heroMessagesGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _isDark
            ? const [Color(0xFF0B2F3A), Color(0xFF11564F), Color(0xFF1B7E73)]
            : const [primaryDark, primary, primaryMedium],
        stops: const [0.0, 0.55, 1.0],
      );

  static LinearGradient get heroNotificationsGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _isDark
            ? const [Color(0xFF0B2F3A), Color(0xFF11564F), Color(0xFF2E2415)]
            : const [primaryDark, primary, secondary],
        stops: const [0.0, 0.55, 1.0],
      );

  static LinearGradient get heroProfileGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _isDark
            ? const [Color(0xFF0B2F3A), Color(0xFF11564F), Color(0xFF2E2415)]
            : const [primaryDark, primary, secondaryDeep],
        stops: const [0.0, 0.55, 1.0],
      );

  static LinearGradient get landingCtaGradient => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: _isDark
            ? const [Color(0xFF1B7E73), Color(0xFF11564F)]
            : const [primaryMedium, primary],
      );

  static List<BoxShadow> get ambientShadow => [
        BoxShadow(
          color: (_isDark ? Colors.black : primaryDark).withValues(
            alpha: _isDark ? 0.22 : 0.07,
          ),
          blurRadius: _isDark ? 18 : 32,
          spreadRadius: 0,
          offset: Offset(0, _isDark ? 6 : 8),
        ),
      ];

  static List<BoxShadow> get lightShadow => [
        BoxShadow(
          color: (_isDark ? Colors.black : primaryDark).withValues(
            alpha: _isDark ? 0.16 : 0.05,
          ),
          blurRadius: _isDark ? 12 : 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<Color> get imageScrim => _isDark
      ? const [Color(0x00000000), Color(0x55000000), Color(0xB3000000)]
      : const [Color(0x00000000), Color(0x22000000), Color(0x66000000)];
  static const List<double> imageScrimStops = [0.55, 0.85, 1.0];
  static const List<List<Color>> avatarPalette = [
    [Color(0xFF14B488), Color(0xFF0CA6A6)],
    [Color(0xFF7A5CFA), Color(0xFF4F46E5)],
    [Color(0xFF2B7FFF), Color(0xFF1F9FBE)],
    [Color(0xFFFF8A00), Color(0xFFFF6B6B)],
    [Color(0xFFEB4D8A), Color(0xFFB42369)],
    [primary, primaryMedium],
  ];

  static List<Color> avatarGradientForSeed(String seed) {
    if (seed.isEmpty) return avatarPalette.first;
    final hash = seed.codeUnits.fold<int>(0, (acc, c) => (acc + c) & 0xFFFF);
    return avatarPalette[hash % avatarPalette.length];
  }

  // Mesh « marque » multi-stops doux pour fonds hero (top bar accueil, etc.).
  // Diagonale vert vibrant → olive profond, très désaturé en dark pour rester
  // calme. À poser SOUS du contenu (faible alpha conseillé via les helpers).
  static LinearGradient get meshBrand => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _isDark
            ? const [
                Color(0xFF13322F),
                Color(0xFF173B33),
                Color(0xFF0F1518),
              ]
            : const [
                Color(0xFFEAF7EF),
                Color(0xFFE0F1E8),
                Color(0xFFF7F8FA),
              ],
        stops: const [0.0, 0.5, 1.0],
      );

  /// Voile mesh radial subtil (halo de marque) pour accentuer un coin de hero.
  static RadialGradient get meshBrandGlow => RadialGradient(
        center: const Alignment(-0.8, -1.0),
        radius: 1.4,
        colors: [
          primaryMedium.withValues(alpha: _isDark ? 0.16 : 0.14),
          primaryMedium.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 1.0],
      );

  static List<BoxShadow> get glowShadow => [
        BoxShadow(
          color: primaryLight.withValues(alpha: 0.20),
          blurRadius: 48,
          spreadRadius: 8,
          offset: const Offset(0, 0),
        ),
        BoxShadow(
          color: primaryDark.withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];
}
