import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'wavy_decorations.dart';

/// En-tête de page de contenu.
///
/// L'ancienne version empilait trois effets qui se disputaient l'attention : une
/// découpe en vague, une trame d'anneaux concentriques et un tiret souligné sous
/// le titre. Résultat, un bandeau chargé et daté. Ici : un dégradé profond, deux
/// halos lumineux très diffus, une base arrondie — et le titre qui respire.
///
/// L'API n'a pas bougé : les 11 écrans qui s'en servent gagnent le nouveau look
/// sans être touchés (c'est tout l'intérêt d'un composant partagé).
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

  /// Rayon de la base. Assez généreux pour se lire comme une forme, pas comme
  /// un coin arrondi timide.
  static const double _bottomRadius = 34;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: height + topPadding,
      width: double.infinity,
      child: DecoratedBox(
        // Ombre portée sous la base : le contenu qui suit passe *sous* l'en-tête
        // au lieu de le toucher bord à bord.
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(_bottomRadius),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(_bottomRadius),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: gradient ?? AppColors.landingHeroGradient,
                ),
              ),

              // Deux halos très diffus, décalés hors cadre : ils donnent de la
              // profondeur sans dessiner de motif reconnaissable.
              Positioned(
                top: -height * 0.55,
                right: -height * 0.35,
                child: _Glow(size: height * 1.25, opacity: 0.16),
              ),
              Positioned(
                bottom: -height * 0.45,
                left: -height * 0.30,
                child: _Glow(size: height * 0.95, opacity: 0.10),
              ),

              // Voile diagonal : une lumière qui glisse, à peine perceptible.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.onPrimary.withValues(alpha: 0.10),
                      AppColors.onPrimary.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.08),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.fromLTRB(22, topPadding + 10, 16, 26),
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
                        // Un titre large se resserre : sans ça, il « bave ».
                        letterSpacing: -0.6,
                        height: 1.1,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onPrimary.withValues(alpha: 0.78),
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Halo radial : blanc au centre, transparent au bord.
class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.onPrimary.withValues(alpha: opacity),
              AppColors.onPrimary.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.72],
          ),
        ),
      ),
    );
  }
}
