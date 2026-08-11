import 'package:get/get.dart';
import 'package:baara/app/core/services/onboarding_service.dart';
import 'package:baara/app/core/services/post_auth_bootstrap.dart';
import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:baara/app/core/utils/onboarding_progress.dart';
import 'package:baara/app/core/utils/user_facing_error.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import 'package:baara/routes/app_routes.dart';
import 'package:baara/app/features/profile/domain/repositories/i_profile_repository.dart';

class OnboardingController extends GetxController {
  OnboardingController(this._onboarding, this._profileRepository);

  final OnboardingService _onboarding;
  final IProfileRepository _profileRepository;

  final currentStep = 0.obs;
  final isBusy = false.obs;

  /// Message sous le corps de l'étape (ex. rappel « finir plus tard »).
  final stepHint = RxnString();

  Future<void> skip() => _finish();

  Future<void> next({required bool isLast}) async {
    if (isBusy.value) return;
    if (isLast) {
      await _finish();
      return;
    }

    final step = currentStep.value;
    try {
      isBusy.value = true;
      stepHint.value = null;

      if (step == 0) {
        await Get.toNamed<void>(AppRoutes.profileEdit);
        if (!await _tryAdvanceProfileStep()) return;
      } else if (step == 1) {
        await Get.toNamed<void>(AppRoutes.profileCv);
        if (!await _tryAdvanceCvStep()) return;
      }

      if (step < 2) currentStep.value = step + 1;
    } catch (e) {
      AppToast.error('Erreur', userFacingError(e));
    } finally {
      isBusy.value = false;
    }
  }

  Future<bool> _tryAdvanceProfileStep() async {
    final profile = await _profileRepository.getProfile();
    if (onboardingProfileStepDone(profile)) {
      stepHint.value = 'Profil mis à jour — bravo !';
      return true;
    }
    return _confirmSkipStep(
      title: 'Profil incomplet',
      message:
          'Ajoutez au moins un titre, une bio, une photo ou une compétence. '
          'Vous pourrez compléter depuis l\'onglet Profil à tout moment.',
      onRetry: () async {
        await Get.toNamed<void>(AppRoutes.profileEdit);
      },
    );
  }

  Future<bool> _tryAdvanceCvStep() async {
    final profile = await _profileRepository.getProfile();
    if (onboardingCvStepDone(profile)) {
      stepHint.value = 'CV ou parcours enregistré — parfait !';
      return true;
    }
    return _confirmSkipStep(
      title: 'CV pas encore prêt',
      message:
          'Importez ou créez votre CV, ou ajoutez une expérience / formation. '
          'Vous pourrez le faire plus tard depuis Profil → Mon CV.',
      onRetry: () async {
        await Get.toNamed<void>(AppRoutes.profileCv);
      },
    );
  }

  Future<bool> _confirmSkipStep({
    required String title,
    required String message,
    required Future<void> Function() onRetry,
  }) async {
    stepHint.value = message;
    final ctx = Get.context;
    if (ctx == null) return false;
    final choice = await showConfirmSheet(
      context: ctx,
      icon: AppIcons.info,
      iconColor: AppColors.warningAccent,
      title: title,
      message: message,
      confirmLabel: 'Compléter maintenant',
      cancelLabel: 'Plus tard',
    );
    if (choice == true) {
      await onRetry();
      return false;
    }
    if (choice == false) {
      AppToast.info('À votre rythme', 'Vous pourrez finir depuis votre profil.');
      return true;
    }
    return false;
  }

  Future<void> _finish() async {
    await _onboarding.markCompleted();
    await PostAuthBootstrap.activatePushAfterLogin();

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
