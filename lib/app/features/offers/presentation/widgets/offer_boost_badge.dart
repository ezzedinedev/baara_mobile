import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import 'package:jobaway/app/core/theme/app_colors.dart';
import 'package:jobaway/app/core/theme/app_text_styles.dart';

/// Badge de mise en avant d'une offre, distinct par plan (aligne sur le web) :
/// tier 1 = Essentiel (ambre clair), 2 = Populaire (ambre), 3 = Pro (or).
/// Chips opaques a fort contraste : lisibles sur fond clair comme sur degrade.
class OfferBoostBadge extends StatelessWidget {
  const OfferBoostBadge({
    super.key,
    required this.tier,
    required this.label,
  });

  final int tier;
  final String label;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final IconData icon;
    switch (tier) {
      case 3:
        bg = AppColors.boostGold;
        fg = AppColors.onBoostGold;
        icon = Icons.workspace_premium_rounded;
        break;
      case 2:
        bg = AppColors.boostAmber;
        fg = AppColors.onBoostAmber;
        icon = IconlyBold.star;
        break;
      default:
        bg = AppColors.boostSoft;
        fg = AppColors.onBoostSoft;
        icon = IconlyLight.star;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.bodySm.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
