import 'package:flutter/material.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class RegisterBadges extends StatelessWidget {
  const RegisterBadges({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _RegisterMiniBadge(
                icon: AppIcons.shieldDone,
                iconColor: AppColors.successAccent,
                title: '100% Securise',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _RegisterMiniBadge(
                icon: AppIcons.chart,
                iconColor: AppColors.primaryAccent,
                title: '0% Commission',
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _RegisterMiniBadge(
                icon: Icons.school_outlined,
                iconColor: AppColors.warningAccent,
                title: 'Formation incluse',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _RegisterMiniBadge(
                icon: AppIcons.shieldDone,
                iconColor: AppColors.primaryMedium,
                title: 'Recruteurs verifies',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RegisterMiniBadge extends StatelessWidget {
  const _RegisterMiniBadge({
    required this.icon,
    required this.iconColor,
    required this.title,
  });

  final IconData icon;
  final Color iconColor;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.bodyColor,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
