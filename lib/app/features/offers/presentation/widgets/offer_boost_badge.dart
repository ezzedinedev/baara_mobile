import 'package:flutter/material.dart';

import 'package:opportune_bf/app/core/theme/app_text_styles.dart';

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
        bg = const Color(0xFFE89400);
        fg = const Color(0xFF2A1500);
        icon = Icons.workspace_premium_rounded;
        break;
      case 2:
        bg = const Color(0xFFF7B500);
        fg = const Color(0xFF1B1300);
        icon = Icons.star_rounded;
        break;
      default:
        bg = const Color(0xFFFFF3D4);
        fg = const Color(0xFF8A5A00);
        icon = Icons.star_outline_rounded;
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
