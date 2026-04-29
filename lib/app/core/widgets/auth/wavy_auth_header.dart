import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../common/wavy_decorations.dart';

/// Header auth avec un dégradé primaire + texture topographique + séparateur
/// en vague vers le contenu blanc en dessous. Utilisé par la landing page,
/// sign up, et les écrans de login.
///
/// [height] contrôle la hauteur totale (landing = ~60% écran, sign up = ~35%).
/// [showLeading] affiche une flèche retour à gauche.
/// [title]/[subtitle] sont affichés centrés au sein du header (s'ils sont
/// passés) — utile pour OTP / success pages.
/// [titleUnderline] : petit trait rouge/vert sous un titre sous la vague
/// (voir mockup "Sign up" avec le trait horizontal sous le titre).
class WavyAuthHeader extends StatelessWidget {
  const WavyAuthHeader({
    super.key,
    this.height = 280,
    this.showLeading = false,
    this.onLeadingTap,
    this.gradient,
    this.foregroundIcon,
    this.title,
    this.subtitle,
  });

  final double height;
  final bool showLeading;
  final VoidCallback? onLeadingTap;
  final LinearGradient? gradient;
  final IconData? foregroundIcon;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipPath(
        clipper: const WaveClipper(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Fond avec gradient primaire.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: gradient ?? AppColors.landingHeroGradient,
              ),
            ),
            // Couche texture topographique (cercles concentriques translucides).
            const CustomPaint(painter: TopoPainter()),
            // Leading arrow back.
            if (showLeading)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 14,
                child: WavyHeaderLeadingButton(onTap: onLeadingTap),
              ),
            // Contenu central (icône + titre + sous-titre).
            if (foregroundIcon != null || title != null || subtitle != null)
              Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                  bottom: 60,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (foregroundIcon != null) ...[
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.onPrimary.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.onPrimary.withValues(alpha: 0.24),
                          ),
                        ),
                        child: Icon(
                          foregroundIcon,
                          color: AppColors.onPrimary,
                          size: 36,
                        ),
                      ),
                      // Spacer uniquement s'il y a un titre/sous-titre dessous.
                      // Sans cette condition l'icone seule (cas profileEdit)
                      // gaspillait 18px → overflow de 16px sur petits ecrans.
                      if (title != null || subtitle != null)
                        const SizedBox(height: 18),
                    ],
                    if (title != null)
                      Text(
                        title!,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.displayMd.copyWith(
                          color: AppColors.onPrimary,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          subtitle!,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.onPrimary.withValues(alpha: 0.92),
                            height: 1.4,
                          ),
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

