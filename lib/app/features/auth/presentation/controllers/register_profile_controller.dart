import 'package:get/get.dart';
import 'package:opportune_bf/routes/app_routes.dart';

class RegisterProfileController extends GetxController {
  final RxString selectedProfile = ''.obs;

  void selectProfile(String profile) {
    selectedProfile.value = profile;
  }

  void onContinue() {
    if (selectedProfile.value.isNotEmpty) {
      Get.toNamed(AppRoutes.register,
          arguments: {'registration_profile': selectedProfile.value});
    }
  }
}
