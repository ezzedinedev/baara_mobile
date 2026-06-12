import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/haptics.dart';
import '../common/press_scale.dart';

/// Bouton « social » (Google, etc.) réutilisable sur les écrans de connexion.
/// Surface carte arrondie, bordure douce, feedback PressScale + haptique léger.
class AuthSocialButton extends StatelessWidget {
  const AuthSocialButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      haptic: false,
      curve: AppMotion.springEmphasized,
      onTap: () {
        AppHaptics.tap();
        onTap();
      },
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppShapes.squircleRadius(AppRadius.lg),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.55),
          ),
          boxShadow: AppColors.lightShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: AppTextStyles.titleMd.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
