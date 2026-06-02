import 'package:get/get.dart';
import 'package:opportune_bf/routes/app_routes.dart';

class LandingController extends GetxController {
  void goToProfileSelection() {
    Get.toNamed(AppRoutes.profileSelection);
  }
}
