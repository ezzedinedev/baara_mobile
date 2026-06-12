import 'package:flutter/material.dart';

/// En-tête parallax léger pour les écrans à grand hero scrollable qui n'utilisent
/// pas de `SliverAppBar` (listes classiques type `ListView`).
///
/// Le hero ([child]) se translate vers le haut plus lentement que le contenu
/// (effet de profondeur), se zoome très légèrement et s'estompe au défilement.
/// L'animation est pilotée par un [ScrollController] via un [AnimatedBuilder]
/// (rebuild localisé du seul header), donc aucun `setState` par frame ni
/// rebuild global : performant même sur les listes longues.
///
/// Usage : placer ce widget en tête d'une `Column`/`ListView` enveloppée d'un
/// `Stack`, ou simplement comme premier enfant d'une liste pilotée par le même
/// [controller]. Respecte les préférences « réduire les animations ».
class ParallaxHeader extends StatelessWidget {
  const ParallaxHeader({
    super.key,
    required this.controller,
    required this.child,
    this.height,
    this.parallaxFactor = 0.4,
    this.maxScale = 1.12,
    this.fade = true,
  });

  /// Contrôleur de la liste défilante hébergeant ce header.
  final ScrollController controller;

  /// Contenu du hero (image, dégradé, bloc mesh…).
  final Widget child;

  /// Hauteur fixe optionnelle du hero. Si nulle, le hero garde sa taille
  /// intrinsèque (utile pour les blocs auto-dimensionnés).
  final double? height;

  /// Vitesse relative du parallax : 0 = fixe avec le contenu, 1 = suit le scroll
  /// (aucun parallax). 0.4 = le hero monte à 40 % de la vitesse du contenu.
  final double parallaxFactor;

  /// Zoom maximum appliqué quand on tire vers le bas (overscroll) — sensation
  /// élastique premium.
  final double maxScale;

  /// Estompe le hero au défilement vers le haut.
  final bool fade;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.maybeOf(context);
    final reduceMotion =
        mq?.disableAnimations == true || mq?.accessibleNavigation == true;
    if (reduceMotion) {
      return height != null ? SizedBox(height: height, child: child) : child;
    }

    final hero = AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // offset > 0 : on défile vers le haut. offset < 0 : overscroll (pull).
        final offset = controller.hasClients ? controller.offset : 0.0;

        // Parallax vertical : le hero monte plus lentement que le contenu.
        final translateY = offset > 0 ? -(offset * (1 - parallaxFactor)) : 0.0;

        // Zoom élastique au pull-to-refresh / overscroll en haut.
        final pull = offset < 0 ? -offset : 0.0;
        final scale = (1.0 + (pull / 320)).clamp(1.0, maxScale).toDouble();

        // Fondu progressif sur les ~180 premiers px de scroll.
        final opacity = fade && offset > 0
            ? (1.0 - (offset / 180)).clamp(0.0, 1.0).toDouble()
            : 1.0;

        return Transform.translate(
          offset: Offset(0, translateY),
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.topCenter,
            child: Opacity(opacity: opacity, child: child),
          ),
        );
      },
      child: child,
    );

    final wrapped =
        height != null ? SizedBox(height: height, child: hero) : hero;
    return RepaintBoundary(child: wrapped);
  }
}
