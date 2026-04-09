import 'package:get/get.dart';

import 'candidate_login_controller.dart';

class CandidateLoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CandidateLoginController>(() => CandidateLoginController());
  }
}
