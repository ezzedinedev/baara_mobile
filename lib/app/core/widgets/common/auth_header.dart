import 'package:flutter/material.dart' show BuildContext, Column, CrossAxisAlignment, SizedBox, StatelessWidget, Text, TextAlign, TextStyle, Widget;
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../widgets.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    this.logoSize = 18,
    this.fontSize = 20,
    required this.title,
    this.titleStyle,
    this.subtitle,
    this.center = false,
    this.spacing = 24.0,
  });

  final double logoSize;
  final double fontSize;
  final String title;
  final TextStyle? titleStyle;
  final String? subtitle;
  final bool center;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final titleWidget = Text(
      title,
      style: titleStyle ?? AppTextStyles.displayXl.copyWith(
        fontSize: fontSize,
      ),
      textAlign: center ? TextAlign.center : TextAlign.start,
    );

    final subtitleWidget = subtitle != null
        ? Text(
            subtitle!,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.bodyColor,
              height: 1.55,
            ),
            textAlign: center ? TextAlign.center : TextAlign.start,
          )
        : null;

    return Column(
      crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22),
        OpportuneLogo(iconSize: logoSize, fontSize: fontSize, centerAlign: center),
        SizedBox(height: spacing),
        titleWidget,
        if (subtitleWidget != null) ...[const SizedBox(height: 14), subtitleWidget],
        const SizedBox(height: 44),
      ],
    );
  }
}
