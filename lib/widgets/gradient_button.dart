import 'package:flutter/material.dart';

import '../app/core/theme/app_colors.dart';
import '../app/core/theme/app_text_styles.dart';

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.height = 56,
    this.width,
    this.gradient,
    this.textColor,
    this.fontSize = 15,
    this.borderRadius = 50,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final double? width;
  final LinearGradient? gradient;
  final Color? textColor;
  final double fontSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final grad = gradient ?? AppColors.primaryGradient;
    final disabledGradient = LinearGradient(
      colors: grad.colors
          .map((color) => color.withValues(alpha: 0.45))
          .toList(),
      begin: grad.begin,
      end: grad.end,
    );

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed != null ? grad : disabledGradient,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: onPressed != null
              ? [
                  BoxShadow(
                    color: AppColors.primaryMedium.withValues(alpha: 0.30),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          textColor ?? AppColors.onPrimary,
                        ),
                      ),
                    )
                  : Text(
                      label,
                      style: AppTextStyles.buttonLg.copyWith(
                        fontSize: fontSize,
                        color: textColor ?? AppColors.titleColor,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
