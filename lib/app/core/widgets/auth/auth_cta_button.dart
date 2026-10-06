import 'package:flutter/material.dart';

import '../../theme/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/haptics.dart';
import '../common/press_scale.dart';

/// Bouton de connexion, inscription, etc.
class AuthCtaButton extends StatefulWidget {
  const AuthCtaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.trailing = AppIcons.actionForward,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? trailing;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  State<AuthCtaButton> createState() => _AuthCtaButtonState();
}

class _AuthCtaButtonState extends State<AuthCtaButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundColor ?? AppColors.primary;
    final fg = widget.foregroundColor ?? AppColors.onPrimary;
    final disabled = widget.onPressed == null || widget.isLoading;
    // Inactif (pas d'action) : surface neutre et texte atténué, plutôt qu'une
    // couleur de marque délavée. En chargement, le bouton garde sa couleur.
    final inactive = widget.onPressed == null && !widget.isLoading;
    final ink = inactive ? AppColors.hintColor : fg;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: PressScale(
        enabled: !disabled,
        haptic: false,
        curve: AppMotion.springEmphasized,
        onTap: disabled
            ? null
            : () {
                AppHaptics.success();
                widget.onPressed!();
              },
        child: AnimatedContainer(
          duration: AppMotion.short,
          curve: AppMotion.emphasized,
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            // Couleur explicite = aplat ; sinon dégradé de marque.
            gradient: inactive || widget.backgroundColor != null
                ? null
                : AppColors.landingCtaGradient,
            color: inactive ? AppColors.surfaceHigh : widget.backgroundColor,
            borderRadius: AppShapes.pill,
            boxShadow: inactive
                ? null
                : [
                    BoxShadow(
                      // Sur un aplat clair, une ombre teintée ferait une bande
                      // colorée : ombre neutre à la place.
                      color: widget.backgroundColor != null
                          ? Colors.black.withValues(alpha: _isHovered ? 0.26 : 0.18)
                          : bg.withValues(alpha: _isHovered ? 0.26 : 0.16),
                      blurRadius: _isHovered ? 28 : 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation(fg),
                    ),
                  )
                : AnimatedDefaultTextStyle(
                    duration: AppMotion.short,
                    style: AppTextStyles.buttonLg.copyWith(
                      color: inactive
                          ? ink
                          : fg.withValues(alpha: _isHovered ? 1.0 : 0.90),
                      letterSpacing: 0,
                      fontSize: 15,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.trailing != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            widget.trailing ?? AppIcons.actionForward,
                            color: ink,
                            size: 18,
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
