import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get displayXl => GoogleFonts.manrope(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: AppColors.titleColor,
        letterSpacing: 0,
        height: 1.08,
      );

  static TextStyle get displayLg => GoogleFonts.manrope(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.titleColor,
        letterSpacing: 0,
        height: 1.1,
      );

  static TextStyle get displayMd => GoogleFonts.manrope(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.titleColor,
        letterSpacing: 0,
        height: 1.15,
      );

  static TextStyle get headlineLg => GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.titleColor,
        letterSpacing: 0,
        height: 1.25,
      );

  static TextStyle get headlineMd => GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.titleColor,
        letterSpacing: 0,
        height: 1.3,
      );

  static TextStyle get headlineSm => GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.titleColor,
        height: 1.35,
      );

  static TextStyle get titleLg => GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.titleColor,
        height: 1.4,
      );

  static TextStyle get titleMd => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.titleColor,
        height: 1.4,
      );

  static TextStyle get bodyLg => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.bodyColor,
        height: 1.65,
      );

  static TextStyle get bodyMd => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.bodyColor,
        height: 1.6,
      );

  static TextStyle get bodySm => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.bodyColor,
        height: 1.5,
      );

  static TextStyle get labelLg => GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.bodyColor,
        letterSpacing: 0,
        height: 1.4,
      );

  static TextStyle get labelMd => GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.hintColor,
        letterSpacing: 0,
        height: 1.4,
      );

  static TextStyle get labelSm => GoogleFonts.manrope(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.hintColor,
        letterSpacing: 0,
      );

  static TextStyle logoGreen({double size = 26}) => GoogleFonts.manrope(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: AppColors.primaryLight,
        letterSpacing: 0,
      );

  static TextStyle logoDark({double size = 26}) => GoogleFonts.manrope(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: AppColors.titleColor,
        letterSpacing: 0,
      );

  static TextStyle get buttonLg => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: AppColors.titleColor,
        height: 1.0,
      );

  static TextStyle get buttonMd => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: AppColors.onPrimary,
        height: 1.0,
      );

  static TextStyle get splashPercent => GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        letterSpacing: 0,
      );
}
