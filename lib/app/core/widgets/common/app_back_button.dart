import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../utils/haptics.dart';

/// Bouton retour unifié de l'app : pastille ronde + chevron.
/// - [onDark] = true : posé sur un header coloré/sombre (cercle translucide
///   clair + chevron blanc) — identique aux wavy headers.
/// - [onDark] = false : sur fond clair (carte blanche + chevron foncé).
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onTap, this.onDark = false});

  final VoidCallback? onTap;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final bg = onDark
        ? AppColors.onPrimary.withValues(alpha: 0.18)
        : AppColors.surfaceCard;
    final borderColor = onDark
        ? AppColors.onPrimary.withValues(alpha: 0.24)
        : AppColors.outlineVariant.withValues(alpha: 0.40);
    final iconColor = onDark ? AppColors.onPrimary : AppColors.titleColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          AppHaptics.tap();
          if (onTap != null) {
            onTap!();
          } else {
            Navigator.of(context).maybePop();
          }
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor),
          ),
          child: Icon(Icons.chevron_left_rounded, color: iconColor, size: 26),
        ),
      ),
    );
  }
}
