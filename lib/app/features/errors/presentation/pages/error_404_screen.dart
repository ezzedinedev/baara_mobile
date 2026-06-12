import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_motion.dart';
import 'package:opportune_bf/app/core/theme/app_shapes.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/routes/app_routes.dart';

/// Écran 404 — langage 2026 : fond mesh de marque subtil, illustration
/// expressive (chiffre hero + icône), titre `displayHero`, bouton retour
/// squircle avec press spring. Aucune logique de route modifiée.
class Error404Screen extends StatelessWidget {
  const Error404Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        // Fond mesh de marque très doux (chrome plein écran, pas une liste).
        decoration: BoxDecoration(gradient: AppColors.meshBrand),
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.meshBrandGlow),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    _Illustration(),
                    SizedBox(height: AppSpacing.xxl + AppSpacing.sm),
                    _Texts(),
                    SizedBox(height: AppSpacing.xxl + AppSpacing.sm),
                    _Actions(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Illustration expressive : grand « 404 » hero estompé derrière une pastille
/// squircle tonale portant l'icône boussole.
class _Illustration extends StatelessWidget {
  const _Illustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // Chiffre hero estompé en arrière-plan (présence éditoriale).
          Text(
            '404',
            style: AppTextStyles.displayXxl.copyWith(
              fontSize: 116,
              color: AppColors.primaryAccent.withValues(alpha: 0.10),
            ),
          ),
          // Pastille squircle tonale avec icône expressive.
          Container(
            width: 116,
            height: 116,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.12),
              shape: AppShapes.squircle(AppRadius.xl),
              shadows: AppColors.lightShadow,
            ),
            child: Icon(
              IconlyBold.discovery,
              size: 56,
              color: AppColors.primaryAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _Texts extends StatelessWidget {
  const _Texts();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Page introuvable',
          style: AppTextStyles.displayHero,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          "La page que vous cherchez n'existe pas ou a été déplacée.",
          style: AppTextStyles.bodyMd
              .copyWith(color: AppColors.bodyColor, height: 1.5),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PressScale(
          curve: AppMotion.spring,
          onTap: () {
            AppHaptics.tap();
            Get.offAllNamed(AppRoutes.home);
          },
          child: Container(
            width: double.infinity,
            height: 56,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: AppColors.primary,
              shape: AppShapes.squircle(AppRadius.lg),
              shadows: AppColors.ambientShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(IconlyBold.home,
                    size: 19, color: AppColors.onPrimary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  "Retour à l'accueil",
                  style: AppTextStyles.titleMd.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        PressScale(
          curve: AppMotion.spring,
          onTap: () {
            AppHaptics.tap();
            Get.back<void>();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Text(
              'Revenir en arrière',
              style: AppTextStyles.titleMd.copyWith(
                color: AppColors.primaryAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
