import 'package:flutter/material.dart';

/// Charte graphique OpporTune BF — Jobaway Green/White System
/// Toutes les couleurs UI passent par ces tokens.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF056E00);
  static const Color primaryLight = Color(0xFF78EB54);
  static const Color primaryMedium = Color(0xFF45A735);
  static const Color primaryDark = Color(0xFF26472B);

  static const Color background = Color(0xFFFAF9F6);
  static const Color surfaceLow = Color(0xFFF4F3F0);
  static const Color inputFill = Color(0xFFF2EFE9);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFEFEEEB);
  static const Color surfaceHigh = Color(0xFFE9E8E5);
  static const Color surfaceHighest = Color(0xFFE3E2DF);
  static const Color surfaceSelected = Color(0xFFF2FBF0);
  static const Color surfaceIconSoft = Color(0xFFE8F5E3);
  static const Color surfaceSplashMid = Color(0xFFF8FFF8);
  static const Color surfaceSplashBottom = Color(0xFFEEF8EE);

  static const Color titleColor = Color(0xFF111111);
  static const Color bodyColor = Color(0xFF666666);
  static const Color hintColor = Color(0xFF9E9E9E);
  static const Color onDark = Color(0xFF1B1C1A);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color outlineVariant = Color(0xFFBECBB4);
  static const Color error = Color(0xFFBA1A1A);
  static const Color success = Color(0xFF056E00);
  static const Color warning = Color(0xFFB45309);

  static const Color recruiterStart = Color(0xFF90D880);
  static const Color recruiterEnd = Color(0xFF6AB860);

  static const Color socialGoogleBlue = Color(0xFF4285F4);
  static const Color socialGoogleGreen = Color(0xFF34A853);
  static const Color socialGoogleYellow = Color(0xFFFBBC05);
  static const Color socialGoogleRed = Color(0xFFEA4335);
  static const Color socialLinkedIn = Color(0xFF0A66C2);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primaryMedium],
  );

  static const LinearGradient recruiterGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [recruiterStart, recruiterEnd],
  );

  static const LinearGradient splashBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surfaceCard, surfaceSplashMid, surfaceSplashBottom],
    stops: [0.0, 0.55, 1.0],
  );

  static List<BoxShadow> get ambientShadow => [
        BoxShadow(
          color: primaryDark.withValues(alpha: 0.07),
          blurRadius: 32,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get lightShadow => [
        BoxShadow(
          color: primaryDark.withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

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
