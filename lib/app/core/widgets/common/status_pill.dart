import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_text_styles.dart';

/// Pastille d'état raffinée : icône + libellé sur un fond tonal doux avec
/// bordure assortie. Pensée pour les statuts de candidature, mais générique
/// (passer [color] + [label] + [icon]). Variante [dense] pour les contextes
/// compacts (cartes de pipeline).
///
/// La couleur d'accent doit être une variante *Accent* (theme-aware) pour
/// rester lisible en dark ; le fond et la bordure en sont dérivés en alpha.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.dense = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final hPad = dense ? 8.0 : 10.0;
    final vPad = dense ? 4.0 : 6.0;
    final iconSize = dense ? 12.0 : 14.0;
    final fontSize = dense ? 10.0 : 11.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: color),
            SizedBox(width: dense ? 4 : 5),
          ],
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pastille « X% match » cohérente partout (liste d'offres, pipeline, accueil).
/// Affiche une étincelle + le score sur un fond vert de marque tonal.
class MatchScorePill extends StatelessWidget {
  const MatchScorePill({
    super.key,
    required this.score,
    this.dense = false,
  });

  /// Score en pourcentage entier (0–100).
  final int score;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final hPad = dense ? 8.0 : 9.0;
    final vPad = dense ? 3.0 : 4.0;
    final iconSize = dense ? 11.0 : 12.0;
    final fontSize = dense ? 10.0 : 11.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: AppColors.primaryAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: AppColors.primaryAccent.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded,
              size: iconSize, color: AppColors.primaryAccent),
          SizedBox(width: dense ? 4 : 5),
          Text(
            '$score% match',
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.primaryAccent,
              fontWeight: FontWeight.w800,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
