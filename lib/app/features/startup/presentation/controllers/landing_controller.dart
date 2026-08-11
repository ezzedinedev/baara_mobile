import 'package:get/get.dart';
import 'package:baara/routes/app_routes.dart';

class LandingController extends GetxController {
  void goToProfileSelection() {
    Get.toNamed(AppRoutes.profileSelection);
  }
}
