import 'dart:async';
import 'package:flutter/material.dart';

/// Apparition au montage : fade + slide vers le haut + leger scale depuis 0.96.
/// Idéal pour heros / cards principales pour donner un effet "premium".
class RevealOnMount extends StatefulWidget {
  const RevealOnMount({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 520),
    this.offsetY = 24,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;

  @override
  State<RevealOnMount> createState() => _RevealOnMountState();
}

class _RevealOnMountState extends State<RevealOnMount>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _curve =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _ctrl.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) {
        final t = _curve.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, widget.offsetY * (1 - t)),
            child: Transform.scale(
              scale: 0.96 + 0.04 * t,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Pastille avec halo pulsé concentrique. Pour signaler "online", "unread",
/// ou tout indicateur d'activité. La halo respire 0 → max → 0 en boucle.
class PulsingDot extends StatefulWidget {
  const PulsingDot({
    super.key,
    required this.color,
    this.size = 10,
    this.haloSize = 18,
    this.borderColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  final Color color;
  final double size;
  final double haloSize;
  final Color? borderColor;
  final Duration duration;

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.haloSize,
        height: widget.haloSize,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final t = _ctrl.value;
            // Le halo grandit et fade en meme temps.
            final haloScale = 0.5 + 0.7 * t;
            final haloAlpha = (1 - t) * 0.55;
            return Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: haloScale,
                  child: Container(
                    width: widget.haloSize,
                    height: widget.haloSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color.withValues(alpha: haloAlpha),
                    ),
                  ),
                ),
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color,
                    border: widget.borderColor != null
                        ? Border.all(color: widget.borderColor!, width: 1.6)
                        : null,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Effet Ken Burns sur une image : un slow zoom + leger panning qui boucle
/// en ping-pong. Donne du mouvement aux covers statiques.
class KenBurnsImage extends StatefulWidget {
  const KenBurnsImage({
    super.key,
    required this.image,
    this.duration = const Duration(seconds: 12),
    this.maxScale = 1.08,
  });

  final ImageProvider image;
  final Duration duration;
  final double maxScale;

  @override
  State<KenBurnsImage> createState() => _KenBurnsImageState();
}

class _KenBurnsImageState extends State<KenBurnsImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_ctrl.value);
          final scale = 1.0 + (widget.maxScale - 1.0) * t;
          // Pan diagonal subtil.
          final dx = -8 * t;
          final dy = -4 * t;
          return Transform(
            transform: Matrix4.identity()
              ..translateByDouble(dx, dy, 0, 1)
              ..scaleByDouble(scale, scale, scale, 1),
            alignment: Alignment.center,
            child: Image(
              image: widget.image,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}

/// Une fleche/widget qui se decale en horizontal (0 → 4px → 0) en continu
/// pour signaler "ca avance dans cette direction". Parfait pour CTA arrow.
class NudgeArrow extends StatefulWidget {
  const NudgeArrow({
    super.key,
    required this.child,
    this.amplitude = 4,
    this.duration = const Duration(milliseconds: 1200),
  });

  final Widget child;
  final double amplitude;
  final Duration duration;

  @override
  State<NudgeArrow> createState() => _NudgeArrowState();
}

class _NudgeArrowState extends State<NudgeArrow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_ctrl.value);
        return Transform.translate(
          offset: Offset(widget.amplitude * t, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Compteur entier qui s'anime de la valeur precedente vers la nouvelle.
/// Utilise pour stats / badges qui changent.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    required this.builder,
    this.duration = const Duration(milliseconds: 540),
  });

  final int value;
  final Duration duration;
  final Widget Function(BuildContext, int) builder;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => builder(context, v.round()),
    );
  }
}
