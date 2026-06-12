import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_motion.dart';

/// Transition de page « signature » 2026 (maison — aucune dépendance ajoutée).
///
/// Ressenti « shared-axis / fade-through » de Material Motion sans le package
/// `animations` : la page entrante monte d'un cran (slide vertical subtil),
/// gonfle légèrement (scale) et apparaît en fondu décéléré ; la page sortante
/// s'efface et recule très légèrement. Le tout sur les courbes `AppMotion`.
///
/// Branchée globalement via `GetMaterialApp.customTransition` +
/// `defaultTransition: Transition.custom`. Les `GetPage` qui définissent leur
/// propre `transition` (ex. composer en `downToUp`, viewers en `fadeIn`)
/// conservent la leur : Get n'utilise `customTransition` que pour les routes
/// en `Transition.custom`.
class AppPageTransition extends CustomTransition {
  AppPageTransition();

  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Respect des préférences d'accessibilité : pas de mouvement si demandé.
    final mq = MediaQuery.maybeOf(context);
    final reduceMotion =
        mq?.disableAnimations == true || mq?.accessibleNavigation == true;
    if (reduceMotion) {
      return FadeTransition(opacity: animation, child: child);
    }

    // ── Page entrante : fade-through + légers slide & scale (emphasized). ──
    final enterCurve = CurvedAnimation(
      parent: animation,
      curve: AppMotion.emphasizedDecelerate,
      reverseCurve: AppMotion.emphasizedAccelerate,
    );

    final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        // Le contenu apparaît un peu après le début du mouvement (fade-through).
        curve: const Interval(0.20, 1.0, curve: Curves.easeOut),
        reverseCurve: const Interval(0.0, 0.80, curve: Curves.easeIn),
      ),
    );

    final slideIn = Tween<Offset>(
      begin: const Offset(0, 0.035),
      end: Offset.zero,
    ).animate(enterCurve);

    final scaleIn = Tween<double>(begin: 0.97, end: 1.0).animate(enterCurve);

    // ── Page sortante : léger fondu + recul (profondeur). ──
    final fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: const Interval(0.0, 0.60, curve: Curves.easeIn),
      ),
    );

    final scaleOut = Tween<double>(begin: 1.0, end: 0.985).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: AppMotion.emphasized,
      ),
    );

    return FadeTransition(
      opacity: fadeOut,
      child: ScaleTransition(
        scale: scaleOut,
        child: FadeTransition(
          opacity: fadeIn,
          child: SlideTransition(
            position: slideIn,
            child: ScaleTransition(
              scale: scaleIn,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
