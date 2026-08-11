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
    this.trailing = AppIcons.arrowRight,
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
            gradient: disabled ? null : AppColors.landingCtaGradient,
            color: disabled ? bg.withValues(alpha: 0.55) : null,
            borderRadius: AppShapes.pill,
            boxShadow: disabled
                ? null
                : [
                    BoxShadow(
                      color: bg.withValues(alpha: _isHovered ? 0.32 : 0.22),
                      blurRadius: _isHovered ? 30 : 22,
                      offset: const Offset(0, 10),
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
                      color: fg.withValues(alpha: _isHovered ? 1.0 : 0.90),
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
                          const SizedBox(width: 10),
                          Icon(widget.trailing, color: fg, size: 20),
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
