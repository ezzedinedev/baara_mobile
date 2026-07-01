import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Inclinaison « matériau physique » 2026 : le [child] s'incline en 3D (légère
/// perspective) selon la position réelle du téléphone, lue via l'accéléromètre
/// (vecteur gravité). Donne la sensation d'un objet en verre/métal qu'on
/// regarderait sous un angle.
///
/// **Robuste & sans risque** : si aucun capteur n'est disponible (desktop, web,
/// tests) ou en cas d'erreur du flux, on retombe sur un rendu **plat** (zéro
/// tilt). Respecte « réduire les animations ». Le sous-arbre est isolé dans un
/// [RepaintBoundary] ; les valeurs sont lissées (passe-bas) pour un mouvement
/// fluide sans à-coups.
class GyroTilt extends StatefulWidget {
  const GyroTilt({
    super.key,
    required this.child,
    this.maxTilt = 0.10,
    this.smoothing = 0.12,
  });

  final Widget child;

  /// Amplitude max de l'inclinaison en radians (≈ 6° par défaut). Discret.
  final double maxTilt;

  /// Coefficient du lissage passe-bas (0–1). Plus petit = plus doux/inerte.
  final double smoothing;

  @override
  State<GyroTilt> createState() => _GyroTiltState();
}

class _GyroTiltState extends State<GyroTilt> {
  StreamSubscription<AccelerometerEvent>? _sub;
  double _rotX = 0; // inclinaison avant/arrière
  double _rotY = 0; // inclinaison gauche/droite
  bool _active = false;

  @override
  void initState() {
    super.initState();
    // L'abonnement se fait au 1er build (besoin du MediaQuery pour reduceMotion).
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeSubscribe());
  }

  void _maybeSubscribe() {
    if (!mounted) return;
    final mq = MediaQuery.maybeOf(context);
    final reduceMotion =
        mq?.disableAnimations == true || mq?.accessibleNavigation == true;
    if (reduceMotion) return;

    try {
      _sub = accelerometerEventStream(
        samplingPeriod: const Duration(milliseconds: 33),
      ).listen(
        _onEvent,
        // Pas de capteur (desktop/web) → on reste plat, sans planter.
        onError: (_) => _stop(),
        cancelOnError: true,
      );
    } catch (_) {
      _stop();
    }
  }

  void _onEvent(AccelerometerEvent e) {
    if (!mounted) return;
    // x : gauche(-)/droite(+) ; y : bas(-)/haut(+). Normalisé sur g≈9.81.
    final targetY = (e.x / 9.81).clamp(-1.0, 1.0) * widget.maxTilt;
    final targetX = -(e.y / 9.81).clamp(-1.0, 1.0) * widget.maxTilt;
    final nextX = _rotX + (targetX - _rotX) * widget.smoothing;
    final nextY = _rotY + (targetY - _rotY) * widget.smoothing;
    // Évite les rebuilds inutiles sous le seuil de perception.
    if ((nextX - _rotX).abs() < 0.0005 &&
        (nextY - _rotY).abs() < 0.0005 &&
        _active) {
      return;
    }
    setState(() {
      _rotX = nextX;
      _rotY = nextY;
      _active = true;
    });
  }

  void _stop() {
    _sub?.cancel();
    _sub = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_active) return widget.child;
    return RepaintBoundary(
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0012) // perspective
          ..rotateX(_rotX)
          ..rotateY(_rotY),
        child: widget.child,
      ),
    );
  }
}
