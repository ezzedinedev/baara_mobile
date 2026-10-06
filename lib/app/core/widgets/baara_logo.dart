import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import 'baara_mark.dart';

/// Lockup Baara : le symbole officiel suivi du mot « Baara ».
///
/// Mêmes couleurs que le logo du site : corps et texte vert forêt sur fond
/// clair, blancs sur fond sombre ; la tête reste vert feuille.
class BaaraLogo extends StatelessWidget {
  const BaaraLogo({
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
    final onDark = Theme.of(context).brightness == Brightness.dark;
    final ink = onDark ? Colors.white : BaaraMark.brandForest;

    final logo = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment:
          centerAlign ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        if (showIcon) ...[
          BaaraMark(size: iconSize + 14, color: ink),
          const SizedBox(width: 10),
        ],
        Text(
          'Baara',
          style: AppTextStyles.logoGreen(size: fontSize).copyWith(color: ink),
        ),
      ],
    );

    return centerAlign ? Center(child: logo) : logo;
  }
}
