import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/haptics.dart';
import '../common/press_scale.dart';

/// Bouton de connexion, inscription, etc.
class AuthCtaButton extends StatelessWidget {
  const AuthCtaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.trailing = Icons.arrow_forward_rounded,
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
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.primary;
    final fg = foregroundColor ?? AppColors.onPrimary;
    final disabled = onPressed == null || isLoading;

    return PressScale(
      enabled: !disabled,
      haptic: false,
      onTap: disabled
          ? null
          : () {
              AppHaptics.success();
              onPressed!();
            },
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: disabled ? null : AppColors.landingCtaGradient,
            color: disabled ? bg.withValues(alpha: 0.55) : null,
            borderRadius: BorderRadius.circular(999),
            boxShadow: disabled
                ? null
                : [
                    BoxShadow(
                      color: bg.withValues(alpha: 0.22),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation(fg),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          style: AppTextStyles.buttonLg.copyWith(
                            color: fg,
                            letterSpacing: 0,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: 10),
                        Icon(trailing, color: fg, size: 20),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
