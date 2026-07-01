import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../utils/haptics.dart';

/// Toucher « haptique visuel » 2026 : au contact, une **onde de lumière** se
/// propage depuis le point exact de pression, puis s'estompe. Combiné à un léger
/// enfoncement (press-scale). Drop-in de [PressScale] (mêmes `child`/`onTap`),
/// avec en plus le [borderRadius] pour clipper l'onde à la forme.
///
/// Robuste : `IgnorePointer` sur la couche lumineuse, [RepaintBoundary], et repli
/// statique en « réduire les animations ».
class TouchBloom extends StatefulWidget {
  const TouchBloom({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.color,
    this.scale = 0.98,
    this.haptic = true,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadiusGeometry? borderRadius;
  final Color? color;
  final double scale;
  final bool haptic;
  final bool enabled;

  @override
  State<TouchBloom> createState() => _TouchBloomState();
}

class _TouchBloomState extends State<TouchBloom>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bloom = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  Offset? _center;
  bool _pressed = false;

  @override
  void dispose() {
    _bloom.dispose();
    super.dispose();
  }

  void _down(Offset local) {
    if (!widget.enabled) return;
    setState(() {
      _center = local;
      _pressed = true;
    });
    _bloom.forward(from: 0);
  }

  void _up() {
    if (!_pressed) return;
    setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.maybeOf(context);
    final reduceMotion =
        mq?.disableAnimations == true || mq?.accessibleNavigation == true;

    void handleTap() {
      if (widget.haptic) AppHaptics.tap();
      widget.onTap?.call();
    }

    if (!widget.enabled || reduceMotion) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap == null ? null : handleTap,
        onLongPress: widget.onLongPress,
        child: widget.child,
      );
    }

    final radius = (widget.borderRadius ?? BorderRadius.zero).resolve(
      Directionality.maybeOf(context),
    );
    final color = widget.color ?? AppColors.primaryAccent;

    return Listener(
      onPointerDown: (e) => _down(e.localPosition),
      onPointerUp: (_) => _up(),
      onPointerCancel: (_) => _up(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap == null ? null : handleTap,
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: _pressed ? widget.scale : 1.0,
          duration: AppMotion.short,
          curve: _pressed ? Curves.easeOut : AppMotion.spring,
          child: RepaintBoundary(
            child: Stack(
              children: [
                widget.child,
                Positioned.fill(
                  child: IgnorePointer(
                    child: ClipRRect(
                      borderRadius: radius,
                      child: AnimatedBuilder(
                        animation: _bloom,
                        builder: (context, _) {
                          if (_center == null ||
                              _bloom.value == 0 ||
                              _bloom.value == 1) {
                            return const SizedBox.shrink();
                          }
                          return CustomPaint(
                            painter: _BloomPainter(
                              center: _center!,
                              progress: _bloom.value,
                              color: color,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BloomPainter extends CustomPainter {
  _BloomPainter({
    required this.center,
    required this.progress,
    required this.color,
  });

  final Offset center;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Rayon = jusqu'au coin le plus éloigné (l'onde couvre toute la carte).
    final maxR = [
      (center - Offset.zero).distance,
      (center - Offset(size.width, 0)).distance,
      (center - Offset(0, size.height)).distance,
      (center - Offset(size.width, size.height)).distance,
    ].reduce((a, b) => a > b ? a : b);

    final r = maxR * Curves.easeOut.transform(progress);
    if (r <= 0) return;
    // Halo lumineux qui grandit et s'efface (peak au centre, doux au bord).
    final alpha = (1 - progress) * 0.28;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: alpha),
          color.withValues(alpha: alpha * 0.5),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, paint);
  }

  @override
  bool shouldRepaint(_BloomPainter old) =>
      old.progress != progress || old.center != center || old.color != color;
}
