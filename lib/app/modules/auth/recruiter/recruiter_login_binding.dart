import 'package:get/get.dart';

import 'recruiter_login_controller.dart';

class RecruiterLoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RecruiterLoginController>(() => RecruiterLoginController());
  }
}
