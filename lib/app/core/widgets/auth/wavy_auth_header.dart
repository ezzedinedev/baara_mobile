import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_text_styles.dart';
import '../baara_mark.dart';
import '../common/app_back_button.dart';

/// En-tête de marque des écrans d'accueil, d'inscription et de connexion.
///
/// Même langage que le splash et la landing : un bandeau vert forêt aux coins
/// bas arrondis, un halo citron discret, le symbole Baara en filigrane (la
/// signature) et le logo en haut. L'icône de contexte (connexion, code,
/// mot de passe…) apparaît dans une pastille citron avec un léger rebond.
///
/// [height] est la hauteur utile, ajoutée à la barre d'état (jamais rognée
/// par elle). [showLeading] affiche le bouton retour. [title]/[subtitle] sont
/// optionnels : la plupart des écrans portent leur titre sous l'en-tête.
/// [gradient] remplace le fond uni si un écran a besoin d'une variante.
///
/// Le nom historique (`Wavy`) est conservé pour ne pas toucher aux appels.
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

  static const double _radius = 32;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final isCompact = height < 190;
    final badge = isCompact ? 52.0 : 60.0;

    // Le bandeau est sombre et passe sous la barre d'état : icônes claires.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: SizedBox(
        height: height + topInset,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(_radius),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: BaaraMark.brandForest,
                  gradient: gradient,
                ),
              ),
              // Halo citron en haut à droite : de la lumière, pas un motif.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(1.1, -1.2),
                    radius: 1.3,
                    colors: [
                      BaaraMark.brandLime.withValues(alpha: 0.22),
                      BaaraMark.brandLime.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
              // Le personnage du logo en filigrane, coupé par le bord.
              Positioned(
                right: -36,
                bottom: -46,
                child: ExcludeSemantics(
                  child: BaaraMark(
                    size: height * 0.95,
                    color: Colors.white.withValues(alpha: 0.06),
                    headColor: BaaraMark.brandLime.withValues(alpha: 0.10),
                  ),
                ),
              ),
              Positioned(
                top: topInset + 8,
                left: 14,
                right: 14,
                child: SizedBox(
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (showLeading)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: AppBackButton(
                            onDark: true,
                            onTap: onLeadingTap ??
                                () => Navigator.of(context).maybePop(),
                          ),
                        ),
                      Semantics(
                        label: 'Baara',
                        image: true,
                        child: Image.asset(
                          'assets/images/logo/baara_logo_light.png',
                          height: 22,
                          filterQuality: FilterQuality.high,
                          excludeFromSemantics: true,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (foregroundIcon != null || title != null || subtitle != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(24, topInset + 56, 24, 22),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (foregroundIcon != null)
                        _IconBadge(icon: foregroundIcon!, size: badge),
                      if (foregroundIcon != null && title != null)
                        SizedBox(height: isCompact ? 10 : 14),
                      if (title != null)
                        Text(
                          title!,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.displayHero.copyWith(
                            color: Colors.white,
                            fontSize: isCompact ? 22 : 26,
                            letterSpacing: -0.4,
                          ),
                        ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle!,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: Colors.white.withValues(alpha: 0.80),
                            height: 1.4,
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

/// Pastille citron portant l'icône de l'écran, qui apparaît avec un rebond.
class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.size});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: reduceMotion ? 1 : 0.6, end: 1),
        duration: Duration(milliseconds: reduceMotion ? 0 : 520),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: BaaraMark.brandLime,
            borderRadius: AppShapes.squircleRadius(size * 0.34),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, color: BaaraMark.brandForest, size: size * 0.46),
        ),
      ),
    );
  }
}
