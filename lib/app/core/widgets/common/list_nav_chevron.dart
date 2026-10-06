import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';

/// Chevron de fin de ligne pour les listes navigables (réglages, profil…).
class ListNavChevron extends StatelessWidget {
  const ListNavChevron({
    super.key,
    this.color,
    this.size = 22,
  });

  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      AppIcons.listChevron,
      size: size,
      color: color ?? AppColors.hintColor.withValues(alpha: 0.5),
    );
  }
}
