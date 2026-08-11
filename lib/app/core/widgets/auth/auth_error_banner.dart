import 'package:flutter/material.dart';
import 'package:baara/app/core/theme/app_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_text_styles.dart';

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: AppSpacing.lg),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            AppIcons.info,
            color: AppColors.errorStrong,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.errorStrong,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
