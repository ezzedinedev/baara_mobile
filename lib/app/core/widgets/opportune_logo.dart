import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class OpportuneLogo extends StatelessWidget {
  const OpportuneLogo({
    super.key,
    this.iconSize = 20,
    
    this.fontSize = 22,
    this.showIcon = true,
    this.centerAlign = false,
  });

  final double iconSize;
  final double fontSize;
  final bool showIcon;
  final bool centerAlign;

  @override
  Widget build(BuildContext context) {
    final logo = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment:
          centerAlign ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        if (showIcon) ...[
          Container(
            width: iconSize + 14,
            height: iconSize + 14,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular((iconSize + 14) * 0.28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryLight.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.work_rounded,
              color: AppColors.onPrimary,
              size: iconSize,
            ),
          ),
          const SizedBox(width: 10),
        ],
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Oppor',
                style: AppTextStyles.logoGreen(size: fontSize),
              ),
              TextSpan(
                text: 'Tune',
                style: AppTextStyles.logoDark(size: fontSize),
              ),
              TextSpan(
                text: ' BF',
                style: AppTextStyles.logoDark(size: fontSize * 0.75).copyWith(
                  color: AppColors.bodyColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return centerAlign ? Center(child: logo) : logo;
  }
}
