import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';
import '../../utils/haptics.dart';

class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.97,
    this.duration = const Duration(milliseconds: 220),
    this.haptic = true,
    this.enabled = true,
    this.curve,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  final double scale;
  final Duration duration;
  final bool haptic;
  final bool enabled;

  /// Courbe du press « ressort » global. Par défaut [AppMotion.spring]
  /// (overshoot doux au relâchement). Passer une autre courbe pour ajuster
  /// localement sans toucher les usages existants.
  final Curve? curve;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.duration,
      lowerBound: 0.0,
      upperBound: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _press() {
    if (!widget.enabled) return;
    _ctrl.forward();
  }

  void _release() {
    if (!widget.enabled) return;
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final reduceMotion = mediaQuery?.disableAnimations == true ||
        mediaQuery?.accessibleNavigation == true;

    if (!widget.enabled) {
      return widget.child;
    }
    if (reduceMotion) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap == null
            ? null
            : () {
                if (widget.haptic) AppHaptics.tap();
                widget.onTap!();
              },
        onLongPress: widget.onLongPress,
        child: widget.child,
      );
    }
    return Listener(
      onPointerDown: (_) => _press(),
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap == null
            ? null
            : () {
                if (widget.haptic) AppHaptics.tap();
                widget.onTap!();
              },
        onLongPress: widget.onLongPress,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) {
            // Press-down : easing standard (pas d'overshoot indésirable).
            // Release : courbe « ressort » (défaut [AppMotion.spring]) pour un
            // rebond doux. On garde l'overshoot dans [0,1] côté valeur du
            // contrôleur, l'effet élastique se voit sur l'échelle.
            final releaseCurve = widget.curve ?? AppMotion.spring;
            final eased = _ctrl.status == AnimationStatus.reverse
                ? releaseCurve.transform(_ctrl.value)
                : Curves.easeInOut.transform(_ctrl.value);
            final s = 1.0 - (eased * (1.0 - widget.scale));
            return Transform.scale(scale: s, child: child);
          },
          child: widget.child,
        ),
      ),
    );
  }
}
