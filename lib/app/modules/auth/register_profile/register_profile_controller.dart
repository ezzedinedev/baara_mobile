import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/api_constants.dart';
import '../../../../routes/app_routes.dart';

enum RegisterProfileType { student, professional, company }

class RegisterProfileController extends GetxController {
  final selected = Rx<RegisterProfileType?>(null);
  final isOpeningWeb = false.obs;

  bool get canContinue => selected.value != null && !isOpeningWeb.value;

  String get actionLabel => 'CONTINUER';

  void select(RegisterProfileType type) {
    selected.value = type;
  }

  Future<void> onContinue() async {
    final choice = selected.value;
    if (choice == null) {
      return;
    }

    if (choice == RegisterProfileType.company) {
      await _openCompanyRegistrationForm();
      return;
    }

    final profileValue =
        choice == RegisterProfileType.student ? 'student' : 'professional';

    Get.toNamed(
      AppRoutes.register,
      arguments: <String, String>{'registration_profile': profileValue},
    );
  }

  void goBack() {
    Get.offAllNamed(AppRoutes.landing);
  }

  Future<void> _openCompanyRegistrationForm() async {
    isOpeningWeb.value = true;
    final uri = Uri.tryParse(ApiConstants.companyRegisterWebUrl);

    if (uri == null) {
      isOpeningWeb.value = false;
      Get.snackbar(
        'Inscription entreprise',
        'Le lien du formulaire web est invalide.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final openedInApp = await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
          enableDomStorage: true,
        ),
      );
      if (openedInApp) {
        return;
      }

      final openedExternal = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!openedExternal) {
        Get.snackbar(
          'Inscription entreprise',
          'Impossible d\'ouvrir le formulaire web. Lien: ${ApiConstants.companyRegisterWebUrl}',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } on Exception {
      Get.snackbar(
        'Inscription entreprise',
        'Ouverture web impossible. Lien: ${ApiConstants.companyRegisterWebUrl}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isOpeningWeb.value = false;
    }
  }
}
