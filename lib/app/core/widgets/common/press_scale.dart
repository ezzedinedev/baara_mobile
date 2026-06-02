import 'package:flutter/material.dart';

import '../../utils/haptics.dart';

/// Wrapper qui rejoue un micro-rebond (scale-down + spring back) au tap +
/// haptic léger, pour donner un retour tactile cohérent à toute zone
/// cliquable. À utiliser autour de cartes, list items, CTAs custom — partout
/// où un `InkWell` seul donne un feedback visuel insuffisant.
///
/// Usage :
/// ```dart
/// PressScale(
///   onTap: () => Get.toNamed('/foo'),
///   child: MyCard(...),
/// )
/// ```
///
/// Empile-le AVANT d'autres effets visuels (Hero, AnimatedSwitcher) pour que
/// le scale ne casse pas leur géométrie.
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
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Échelle minimale atteinte au moment du press (0.94 = plus marqué,
  /// 0.99 = quasi imperceptible). 0.97 est le sweet spot iOS-like.
  final double scale;

  /// Durée d'aller (et de retour, géré par AnimationController.reverse).
  final Duration duration;

  /// Si false, désactive AppHaptics.tap() au tap (utile sur des éléments
  /// déjà brigués par un parent qui haptic lui-même).
  final bool haptic;

  /// Si false, le widget agit comme un passe-plat (pas d'animation, pas
  /// de tap). Pratique pour piloter via une condition (loading, disabled).
  final bool enabled;

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
    final reduceMotion =
        mediaQuery?.disableAnimations == true ||
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
            final eased = Curves.easeInOut.transform(_ctrl.value);
            final s = 1.0 - (eased * (1.0 - widget.scale));
            return Transform.scale(scale: s, child: child);
          },
          child: widget.child,
        ),
      ),
    );
  }
}
