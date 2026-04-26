import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_theme_controller.dart';

/// Charte graphique OpporTune BF — Jobaway Green/White System
/// Toutes les couleurs UI passent par ces tokens.
class AppColors {
  AppColors._();

  // ── Brand primary : vert forêt vibrant (la teinte de la landing) ───────
  // C'est la couleur dominante. Utiliser sur les CTAs, indicateurs actifs,
  // gradients de header. Doit communiquer l'énergie de la marque.
  static const Color primary = Color(0xFF056E00);
  static const Color primaryLight = Color(0xFF78EB54);
  static const Color primaryMedium = Color(0xFF45A735);
  // primaryDark conserve sa valeur historique (olive sombre) pour ne pas
  // casser les 30+ references. Pour un vrai accent olive sémantique,
  // utiliser le token `secondary` ci-dessous.
  static const Color primaryDark = Color(0xFF26472B);

  // ── Brand secondary : vert olive feutré (accent intérieur app) ─────────
  // Token sémantique introduit pour distinguer les usages "accent muté" des
  // surfaces qui doivent réellement pop avec le primary vibrant. Préférer
  // `secondary` quand l'intention est un accent calme (séparateurs, tags
  // discrets, badges informatifs) — laisser `primary` pour les pop.
  static const Color secondary = Color(0xFF26472B);
  static const Color secondaryDeep = Color(0xFF1B2F1F);
  static const Color secondaryMid = Color(0xFF4F6E55);
  static Color get secondarySoft =>
      _isDark ? const Color(0xFF1A2A1F) : const Color(0xFFEFF3EC);

  static bool get _isDark =>
      Get.isRegistered<AppThemeController>() &&
      Get.find<AppThemeController>().isDarkMode.value;

  static Color get background =>
      _isDark ? const Color(0xFF0F1410) : const Color(0xFFFAF9F6);
  static Color get surfaceLow =>
      _isDark ? const Color(0xFF171D18) : const Color(0xFFF4F3F0);
  static Color get inputFill =>
      _isDark ? const Color(0xFF1D241F) : const Color(0xFFF2EFE9);
  static Color get surfaceCard =>
      _isDark ? const Color(0xFF1A211C) : const Color(0xFFFFFFFF);
  static Color get surfaceContainer =>
      _isDark ? const Color(0xFF202821) : const Color(0xFFEFEEEB);
  static Color get surfaceHigh =>
      _isDark ? const Color(0xFF263026) : const Color(0xFFE9E8E5);
  static Color get surfaceHighest =>
      _isDark ? const Color(0xFF303A31) : const Color(0xFFE3E2DF);
  static Color get surfaceSelected =>
      _isDark ? const Color(0xFF18321F) : const Color(0xFFF2FBF0);
  static Color get surfaceIconSoft =>
      _isDark ? const Color(0xFF203720) : const Color(0xFFE8F5E3);
  static Color get surfaceSplashMid =>
      _isDark ? const Color(0xFF141B15) : const Color(0xFFF8FFF8);
  static Color get surfaceSplashBottom =>
      _isDark ? const Color(0xFF101711) : const Color(0xFFEEF8EE);

  static Color get titleColor =>
      _isDark ? const Color(0xFFF5F7F2) : const Color(0xFF111111);
  static Color get bodyColor =>
      _isDark ? const Color(0xFFC7D0C4) : const Color(0xFF666666);
  static Color get hintColor =>
      _isDark ? const Color(0xFF8F9B8E) : const Color(0xFF9E9E9E);
  static Color get onDark =>
      _isDark ? const Color(0xFF0A0F0B) : const Color(0xFF1B1C1A);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color outlineVariant = Color(0xFFBECBB4);
  static const Color error = Color(0xFFBA1A1A);
  static const Color success = Color(0xFF056E00);
  static const Color warning = Color(0xFFB45309);

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

  static const Color paymentOrangeMoney = Color(0xFFFF7900);
  static const Color paymentWave = Color(0xFF1D9BF0);

  static Color get profileGradientTop =>
      _isDark ? const Color(0xFF1A211C) : const Color(0xFFFFFFFF);
  static Color get profileGradientMid =>
      _isDark ? const Color(0xFF141A1F) : const Color(0xFFF4F7FB);
  static Color get profileGradientBottom =>
      _isDark ? const Color(0xFF121A15) : const Color(0xFFF2FBF0);

  static const Color recruiterStart = Color(0xFF90D880);
  static const Color recruiterEnd = Color(0xFF6AB860);

  static const Color socialGoogleBlue = Color(0xFF4285F4);
  static const Color socialGoogleGreen = Color(0xFF34A853);
  static const Color socialGoogleYellow = Color(0xFFFBBC05);
  static const Color socialGoogleRed = Color(0xFFEA4335);
  static const Color socialLinkedIn = Color(0xFF0A66C2);

  static LinearGradient get primaryGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _isDark
            ? const [Color(0xFF287A32), Color(0xFF1A5B24)]
            : const [primaryLight, primaryMedium],
      );

  static LinearGradient get recruiterGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _isDark
            ? const [Color(0xFF2D7B3A), Color(0xFF1E5B2C)]
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
            ? const [Color(0xFF102414), Color(0xFF17411F), Color(0xFF236C2B)]
            : const [primary, primaryMedium, primaryLight],
      );

  // Per-section hero gradients — chaque grand espace de l'app gagne une
  // teinte distinctive tout en restant ancre dans la charte primaire.
  static LinearGradient get heroAccueilGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _isDark
            ? const [Color(0xFF0F2A20), Color(0xFF12513A), Color(0xFF0CA6A6)]
            : const [Color(0xFF14B488), primary, Color(0xFF0CA6A6)],
        stops: const [0.0, 0.55, 1.0],
      );

  static LinearGradient get heroOffersGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _isDark
            ? const [Color(0xFF0E2545), Color(0xFF124E58), Color(0xFF1A6E48)]
            : const [Color(0xFF2B7FFF), Color(0xFF1F9FBE), primary],
        stops: const [0.0, 0.55, 1.0],
      );

  static LinearGradient get heroTrainingsGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _isDark
            ? const [Color(0xFF1F1745), Color(0xFF34277A), Color(0xFF1D5C3A)]
            : const [Color(0xFF7A5CFA), Color(0xFF4F46E5), primary],
        stops: const [0.0, 0.55, 1.0],
      );

  static LinearGradient get heroMessagesGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _isDark
            ? const [Color(0xFF053A3D), Color(0xFF0A6E72), Color(0xFF1A6E48)]
            : const [Color(0xFF0CA6A6), Color(0xFF14B488), primary],
        stops: const [0.0, 0.55, 1.0],
      );

  static LinearGradient get heroNotificationsGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _isDark
            ? const [Color(0xFF0F2A20), Color(0xFF1A5B2C), Color(0xFF236C2B)]
            : const [primaryMedium, primary, secondaryDeep],
        stops: const [0.0, 0.55, 1.0],
      );

  static LinearGradient get heroProfileGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _isDark
            ? const [Color(0xFF0F2A20), Color(0xFF1A5B2C), Color(0xFF26472B)]
            : const [primary, primaryMedium, primaryDark],
        stops: const [0.0, 0.55, 1.0],
      );

  static LinearGradient get landingCtaGradient => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: _isDark
            ? const [Color(0xFF236C2B), Color(0xFF17411F)]
            : const [primaryMedium, primary],
      );

  static List<BoxShadow> get ambientShadow => [
        BoxShadow(
          color: (_isDark ? Colors.black : primaryDark).withValues(
            alpha: _isDark ? 0.34 : 0.07,
          ),
          blurRadius: _isDark ? 22 : 32,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get lightShadow => [
        BoxShadow(
          color: (_isDark ? Colors.black : primaryDark).withValues(
            alpha: _isDark ? 0.28 : 0.05,
          ),
          blurRadius: _isDark ? 14 : 16,
          offset: const Offset(0, 4),
        ),
      ];

  // ── Image scrim ────────────────────────────────────────────────────────
  // Voile noir transparent pour assombrir le bas d'une image (lisibilité
  // des badges/CTA posés dessus) — sans masquer le contenu visuel principal.
  // À utiliser avec `stops: [0.55, 0.85, 1.0]` côté widget pour limiter le
  // voile au tiers bas. Light mode : 25% bas ; dark mode : plus fort.
  static List<Color> get imageScrim => _isDark
      ? const [Color(0x00000000), Color(0x55000000), Color(0xB3000000)]
      : const [Color(0x00000000), Color(0x22000000), Color(0x66000000)];

  /// Stops par défaut pour `imageScrim` — concentre le voile dans le bas
  /// pour ne pas écraser le sujet de l'image.
  static const List<double> imageScrimStops = [0.55, 0.85, 1.0];

  // ── Avatar palette ────────────────────────────────────────────────────
  // Gradients pour avatars sans photo (initiales). Choisis pour rester
  // distinguables et accessibles côté contraste avec onPrimary blanc dessus.
  // Index par hash(seed) % length pour stabilité visuelle.
  static const List<List<Color>> avatarPalette = [
    [Color(0xFF14B488), Color(0xFF0CA6A6)],
    [Color(0xFF7A5CFA), Color(0xFF4F46E5)],
    [Color(0xFF2B7FFF), Color(0xFF1F9FBE)],
    [Color(0xFFFF8A00), Color(0xFFFF6B6B)],
    [Color(0xFFEB4D8A), Color(0xFFB42369)],
    [primary, primaryMedium],
  ];

  /// Renvoie la paire de couleurs d'avatar pour un identifiant donné.
  /// Pure fonction — même seed → même gradient.
  static List<Color> avatarGradientForSeed(String seed) {
    if (seed.isEmpty) return avatarPalette.first;
    final hash = seed.codeUnits.fold<int>(0, (acc, c) => (acc + c) & 0xFFFF);
    return avatarPalette[hash % avatarPalette.length];
  }

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
