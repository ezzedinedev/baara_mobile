import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_text_styles.dart';

/// Séparateur « ou » réutilisable (login candidat / recruteur). Trait dégradé
/// qui s'estompe vers le centre pour un rendu plus raffiné qu'une ligne plate.
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key, this.label = 'ou'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final line = AppColors.outlineVariant.withValues(alpha: 0.55);
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [line.withValues(alpha: 0), line],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            label,
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.hintColor,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [line, line.withValues(alpha: 0)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
