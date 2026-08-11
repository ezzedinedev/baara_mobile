import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/password_strength.dart';

/// Indicateur visuel de robustesse du mot de passe (barres animées + label).
///
/// Style premium type iCloud / Apple ID : 4 segments colorés, label contextuel,
/// critères manquants affichés sous la barre.
class AuthPasswordStrength extends StatelessWidget {
  const AuthPasswordStrength({
    super.key,
    required this.password,
    this.showCriteria = true,
  });

  final String password;
  final bool showCriteria;

  @override
  Widget build(BuildContext context) {
    final strength = PasswordStrengthEvaluator.evaluate(password);
    if (strength == PasswordStrength.empty) return const SizedBox.shrink();

    final missing = showCriteria
        ? PasswordStrengthEvaluator.missingCriteria(password)
        : <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: _StrengthBar(
                  filled: i < strength.bars,
                  color: _barColor(strength),
                  index: i,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: AppMotion.short,
          child: Text(
            'Force : ${strength.labelFr}',
            key: ValueKey(strength),
            style: AppTextStyles.labelSm.copyWith(
              color: _barColor(strength),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (missing.isNotEmpty) ...[
          const SizedBox(height: 6),
          ...missing.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '· $c',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.hintColor,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  static Color _barColor(PasswordStrength s) => switch (s) {
        PasswordStrength.weak => AppColors.error,
        PasswordStrength.fair => const Color(0xFFE8A317),
        PasswordStrength.good => AppColors.primaryMedium,
        PasswordStrength.strong => AppColors.primaryDark,
        PasswordStrength.empty => AppColors.outlineVariant,
      };
}

class _StrengthBar extends StatelessWidget {
  const _StrengthBar({
    required this.filled,
    required this.color,
    required this.index,
  });

  final bool filled;
  final Color color;
  final int index;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: filled ? 1.0 : 0.0),
      duration: Duration(milliseconds: 280 + index * 60),
      curve: AppMotion.emphasizedDecelerate,
      builder: (context, t, _) {
        return Container(
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: Color.lerp(
              AppColors.outlineVariant.withValues(alpha: 0.45),
              color,
              t,
            ),
          ),
        );
      },
    );
  }
}
