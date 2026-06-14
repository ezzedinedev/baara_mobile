import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_text_styles.dart';
import '../illustrations/success_illustration.dart';
import 'press_scale.dart';

/// Feuille de confirmation de succès réutilisable, bâtie sur
/// [SuccessIllustration] (coche + confettis, dark-aware). Utilisée pour les
/// moments de réussite sans écran dédié (ex. candidature envoyée).
///
/// Non bloquante : l'appelant peut continuer son flux. Se ferme sur tap du
/// bouton « Continuer » ou en glissant.
Future<void> showSuccessSheet(
  BuildContext context, {
  required String title,
  required String message,
  String actionLabel = 'Continuer',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceCard,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppRadius.sheetTop)),
    ),
    builder: (sheetCtx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHighest,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Center(child: SuccessIllustration()),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.bodyColor,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PressScale(
              onTap: () => Navigator.of(sheetCtx).pop(),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  actionLabel,
                  style: AppTextStyles.buttonMd.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
