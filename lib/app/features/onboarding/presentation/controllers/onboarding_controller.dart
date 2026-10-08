import 'package:get/get.dart';
import 'package:baara/app/core/services/onboarding_service.dart';
import 'package:baara/app/core/services/post_auth_bootstrap.dart';
import 'package:baara/routes/app_routes.dart';

/// Présentation affichée juste après l'inscription.
///
/// Elle présente l'app, sans redemander d'informations : la personne vient
/// de remplir le formulaire d'inscription. Ouvrir le formulaire de profil
/// (puis insister avec « Profil incomplet ») donnait l'impression de tout
/// ressaisir. Le profil se complète ensuite à son rythme, depuis la carte
/// « Profil à X % » de l'accueil.
class OnboardingController extends GetxController {
  OnboardingController(this._onboarding);

  final OnboardingService _onboarding;

  /// Profil, CV, opportunités, puis notifications (la demande système ne part
  /// qu'après avoir expliqué son intérêt, jamais à froid).
  static const stepCount = 4;

  final currentStep = 0.obs;
  final isBusy = false.obs;

  /// « Passer » / « Plus tard » : on termine sans ouvrir la demande de
  /// notifications (activable ensuite depuis les Réglages).
  Future<void> skip() => _finish(askPush: false);

  Future<void> next({required bool isLast}) async {
    if (isBusy.value) return;
    if (isLast) {
      isBusy.value = true;
      try {
        await _finish(askPush: true);
      } finally {
        isBusy.value = false;
      }
      return;
    }
    if (currentStep.value < stepCount - 1) currentStep.value++;
  }

  Future<void> _finish({required bool askPush}) async {
    await _onboarding.markCompleted();
    if (askPush) {
      await PostAuthBootstrap.activatePushAfterLogin();
    } else {
      await PostAuthBootstrap.syncPushToken();
    }

    final pending = await _onboarding.consumePendingRoute();
    if (pending != null && pending.isNotEmpty) {
      Get.offAllNamed(AppRoutes.home);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      Get.toNamed<void>(pending);
      return;
    }

    Get.offAllNamed(AppRoutes.home, arguments: {'tab': 1});
  }
}
