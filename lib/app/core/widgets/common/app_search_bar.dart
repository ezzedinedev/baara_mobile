import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/haptics.dart';

/// Champ de recherche intégré au flux de page (sans ombre flottante).
class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.trailing,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        children: [
          Icon(
            IconlyLight.search,
            color: AppColors.bodyColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.titleColor),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.hintColor,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              if (controller.text.isEmpty) {
                return trailing ?? const SizedBox.shrink();
              }
              return InkWell(
                onTap: () {
                  AppHaptics.tap();
                  controller.clear();
                  onChanged?.call('');
                  onClear?.call();
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.bodyColor,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
