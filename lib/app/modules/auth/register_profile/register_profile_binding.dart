import 'package:get/get.dart';

import 'register_profile_controller.dart';

class RegisterProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RegisterProfileController>(() => RegisterProfileController());
  }
}

