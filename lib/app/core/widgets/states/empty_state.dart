import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_text_styles.dart';

/// État vide sobre — pas d'animation pulsée.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final accent = this.accent ?? AppColors.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfaceIconSoft,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(icon, size: 32, color: accent),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleLg.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(height: 1.45),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  actionLabel!,
                  style: AppTextStyles.buttonMd,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
