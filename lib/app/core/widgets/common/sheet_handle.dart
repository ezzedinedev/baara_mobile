import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';

/// Poignée de glissement standard en haut des feuilles modales (bottom sheets).
/// Centralise le motif `40×4` arrondi recopié dans plusieurs feuilles.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key, this.topPadding = 12, this.bottomPadding = 0});

  final double topPadding;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.outlineVariant,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      ),
    );
  }
}
