import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_text_styles.dart';

class GlassChip extends StatelessWidget {
  const GlassChip({
    super.key,
    required this.label,
    this.icon,
    this.iconColor,
    this.style = GlassChipStyle.surface,
    this.color = AppColors.primary,
    this.dense = false,
  });

  final String label;
  final IconData? icon;

  /// Override de la couleur de l'icone si differente de la couleur principale.
  final Color? iconColor;
  final GlassChipStyle style;

  /// Couleur thematique (utilisee pour `solid` et `tonal`, et pour l'icone
  /// par defaut).
  final Color color;

  /// Variante compacte (font + padding plus petits).
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, borderColor) = switch (style) {
      GlassChipStyle.surface => (
          AppColors.surfaceLow,
          AppColors.bodyColor,
          AppColors.outlineVariant.withValues(alpha: 0.18),
        ),
      GlassChipStyle.glass => (
          AppColors.onPrimary.withValues(alpha: 0.18),
          AppColors.onPrimary,
          AppColors.onPrimary.withValues(alpha: 0.24),
        ),
      GlassChipStyle.solid => (
          color,
          AppColors.onPrimary,
          Colors.transparent,
        ),
      GlassChipStyle.tonal => (
          color.withValues(alpha: 0.12),
          color,
          color.withValues(alpha: 0.20),
        ),
    };

    final iconC = iconColor ?? foreground;
    final hPad = dense ? 8.0 : 10.0;
    final vPad = dense ? 4.0 : 6.0;
    final iconSize = dense ? 12.0 : 14.0;
    final fontSize = dense ? 10.0 : 11.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: iconC),
            SizedBox(width: dense ? 4 : 6),
          ],
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}

/// Style visuel d'un [GlassChip] selon le contexte de pose.
enum GlassChipStyle {
  /// Sur fond clair de l'app (surfaceCard, background). Bordure discrete.
  surface,

  /// Sur fond gradient hero / image. Translucide blanc cassé.
  glass,

  /// Couleur pleine pour emphase forte.
  solid,

  /// Couleur thematique douce (12% alpha sur fond, color sur texte).
  tonal,
}
