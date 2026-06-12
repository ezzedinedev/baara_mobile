import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'press_scale.dart';

/// Bouton d'outil discret — fond neutre, pas de verre dégradé.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.onBrandHeader = false,
    this.size = 42,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool onBrandHeader;
  final double size;

  @override
  Widget build(BuildContext context) {
    final btn = PressScale(
      scale: 0.96,
      onTap: onTap,
      // Zone tactile garantie >= 44x44 (MD3 48 / HIG 44) sans agrandir le
      // visuel : la puce reste a [size], la hit-area l'enveloppe.
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        child: Center(
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: onBrandHeader
                  ? AppColors.onPrimary.withValues(alpha: 0.14)
                  : AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: onBrandHeader
                    ? AppColors.onPrimary.withValues(alpha: 0.2)
                    : AppColors.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Icon(
              icon,
              size: 22,
              color: onBrandHeader ? AppColors.onPrimary : AppColors.titleColor,
            ),
          ),
        ),
      ),
    );
    // Accessibilite : expose toujours le role bouton ; le libelle vocal reprend
    // le [tooltip] quand il est fourni.
    final semantic = Semantics(button: true, label: tooltip, child: btn);
    if (tooltip == null) return semantic;
    return Tooltip(message: tooltip!, child: semantic);
  }
}
