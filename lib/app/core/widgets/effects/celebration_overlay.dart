import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:jobaway/app/core/theme/app_colors.dart';

/// Burst de **confetti de célébration** posé en plein écran via [Overlay], sans
/// écran dédié. Réutilise le package `confetti` (déjà présent pour l'écran de
/// match). Court (~1.5 s), auto-nettoyé (ConfettiController + OverlayEntry
/// disposés). Idéal pour les moments de succès (candidature envoyée, connexion
/// acceptée).
///
/// Respecte reduce-motion : si `MediaQuery.disableAnimations` est actif (ou si
/// aucun overlay n'est disponible), ne fait rien — l'action reste fonctionnelle
/// (le toast / haptique d'origine subsiste côté appelant).
///
/// Peut être appelé sans `BuildContext` (depuis un controller) : passe alors par
/// [Get.overlayContext]. Usage :
/// ```dart
/// showCelebration();                 // depuis un controller
/// showCelebration(context: context); // depuis un widget
/// ```
void showCelebration({BuildContext? context, int particles = 22}) {
  final ctx = context ?? Get.overlayContext ?? Get.context;
  if (ctx == null) return;

  final media = MediaQuery.maybeOf(ctx);
  final reduceMotion =
      media?.disableAnimations == true || media?.accessibleNavigation == true;
  if (reduceMotion) return;

  final overlay = Overlay.maybeOf(ctx, rootOverlay: true);
  if (overlay == null) return;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _CelebrationOverlay(
      particles: particles,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _CelebrationOverlay extends StatefulWidget {
  const _CelebrationOverlay({required this.particles, required this.onDone});

  final int particles;
  final VoidCallback onDone;

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay> {
  late final ConfettiController _controller =
      ConfettiController(duration: const Duration(milliseconds: 700));

  @override
  void initState() {
    super.initState();
    _controller.play();
    // Le confetti continue de tomber après l'émission : on nettoie un peu après.
    Future.delayed(const Duration(milliseconds: 1700), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        // Émetteur descendu dans le viewport : un blast explosif calé sur
        // `topCenter` perd la moitié de ses particules hors cadre, au-dessus de
        // l'écran.
        child: Align(
          alignment: const Alignment(0, -0.35),
          child: ConfettiWidget(
            confettiController: _controller,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: AppColors.celebrationSurfaceConfetti,
            numberOfParticles: widget.particles,
            maxBlastForce: 18,
            minBlastForce: 6,
            gravity: 0.22,
            emissionFrequency: 0.05,
          ),
        ),
      ),
    );
  }
}
