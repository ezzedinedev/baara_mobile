import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/haptics.dart';
import '../gradient_button.dart';

/// Barre d'actions fixe en bas — flux CV (import, éditeur, landing, assistant).
class CvStickyActionBar extends StatelessWidget {
  const CvStickyActionBar({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.isLoading = false,
    this.primaryEnabled = true,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool isLoading;
  final bool primaryEnabled;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        boxShadow: AppColors.lightShadow,
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GradientButton(
                label: primaryLabel,
                height: 52,
                borderRadius: AppRadius.md,
                textColor: AppColors.onPrimary,
                isLoading: isLoading,
                onPressed: primaryEnabled && !isLoading ? () {
                  AppHaptics.tap();
                  onPrimary?.call();
                } : null,
              ),
              if (secondaryLabel != null && onSecondary != null) ...[
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          AppHaptics.tap();
                          onSecondary!();
                        },
                  child: Text(
                    secondaryLabel!,
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.bodyColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
