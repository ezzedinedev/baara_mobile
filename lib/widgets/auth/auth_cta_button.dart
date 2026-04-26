import 'package:flutter/material.dart';

import '../../app/core/theme/app_colors.dart';
import '../../app/core/theme/app_text_styles.dart';
import '../../app/core/utils/haptics.dart';

/// CTA principale des écrans auth : pill arrondi plein, couleur primaire.
/// Support loading state via spinner inline.
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

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Material(
        color: disabled ? bg.withValues(alpha: 0.6) : bg,
        borderRadius: BorderRadius.circular(999),
        elevation: disabled ? 0 : 2,
        shadowColor: bg.withValues(alpha: 0.4),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: disabled
              ? null
              : () {
                  AppHaptics.success();
                  onPressed!();
                },
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
                      Text(
                        label,
                        style: AppTextStyles.buttonLg.copyWith(
                          color: fg,
                          letterSpacing: 0.3,
                          fontSize: 15,
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
