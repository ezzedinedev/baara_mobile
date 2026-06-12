import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_text_styles.dart';
import '../common/app_back_button.dart';
import '../common/wavy_decorations.dart';

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
    // Mode compact (profile_selection, profile_edit) : on resserre l'icone et
    // les paddings pour rentrer dans 150dp. La vague (~40dp) reste lisible et
    // l'icone ne deborde plus sur petits ecrans (Tecno KG5j) ni sur appareils
    // avec status bar haute / notch.
    // 200 inclus dans le compact : sinon icône 72 + titre + réserve 60 ne
    // tiennent pas sous la status bar → overflow.
    final isCompact = height < 220;
    final iconSize = isCompact ? 48.0 : 72.0;
    final iconInnerSize = isCompact ? 24.0 : 36.0;
    final topGap = isCompact ? 6.0 : 20.0;
    final bottomReserve = isCompact ? 36.0 : 60.0;
    // La hauteur design s'AJOUTE à la status bar (au lieu d'être rognée par
    // elle) → le contenu dispose toujours de `height` réels, plus d'overflow
    // selon le notch/la status bar de l'appareil.
    final topInset = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: height + topInset,
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
                child: AppBackButton(
                  onDark: true,
                  onTap: () {
                    if (onLeadingTap != null) {
                      onLeadingTap!();
                    } else {
                      Navigator.of(context).maybePop();
                    }
                  },
                ),
              ),
            // Contenu central (icône + titre + sous-titre).
            if (foregroundIcon != null || title != null || subtitle != null)
              Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + topGap,
                  bottom: bottomReserve,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (foregroundIcon != null) ...[
                      Container(
                        width: iconSize,
                        height: iconSize,
                        decoration: BoxDecoration(
                          color: AppColors.onPrimary.withValues(alpha: 0.18),
                          borderRadius:
                              AppShapes.squircleRadius(iconSize * 0.32),
                          border: Border.all(
                            color: AppColors.onPrimary.withValues(alpha: 0.24),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.onPrimary.withValues(alpha: 0.12),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          foregroundIcon,
                          color: AppColors.onPrimary,
                          size: iconInnerSize,
                        ),
                      ),
                      // Spacer uniquement s'il y a un titre/sous-titre dessous.
                      // Sans cette condition l'icone seule (cas profileEdit)
                      // gaspillait 18px → overflow de 16px sur petits ecrans.
                      if (title != null || subtitle != null)
                        SizedBox(height: isCompact ? 10 : 18),
                    ],
                    if (title != null)
                      Text(
                        title!,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.displayHero.copyWith(
                          color: AppColors.onPrimary,
                          fontSize: isCompact ? 24 : 32,
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
