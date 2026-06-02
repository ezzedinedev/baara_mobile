import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'wavy_decorations.dart';

/// Header en vague pour les pages de contenu (offres, formations, messages,
/// notifications, profil...). Reprend la charte des écrans d'authentification :
/// gradient primaire, texture topographique, vague en bas.
///
/// Contrairement à [WavyAuthHeader] (titre centré, contenu d'auth), celui-ci
/// est aligné à gauche, expose un titre + sous-titre, et accepte une liste
/// d'actions à droite (icônes type cloche, filtre...).
class WavyContentHeader extends StatelessWidget {
  const WavyContentHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.height = 230,
    this.showLeading = true,
    this.onLeadingTap,
    this.actions = const [],
    this.gradient,
  });

  final String title;
  final String? subtitle;
  final double height;
  final bool showLeading;
  final VoidCallback? onLeadingTap;
  final List<Widget> actions;
  final LinearGradient? gradient;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipPath(
        clipper: const WaveClipper(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: gradient ?? AppColors.landingHeroGradient,
              ),
            ),
            const CustomPaint(painter: TopoPainter()),
            Padding(
              padding: EdgeInsets.fromLTRB(20, topPadding + 10, 14, 50),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (showLeading) ...[
                        WavyHeaderLeadingButton(onTap: onLeadingTap),
                        const SizedBox(width: 6),
                      ],
                      const Spacer(),
                      ...actions,
                    ],
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: AppTextStyles.displayMd.copyWith(
                      color: AppColors.onPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 48,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.onPrimary.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle!,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onPrimary.withValues(alpha: 0.92),
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
