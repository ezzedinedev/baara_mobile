import 'package:get/get.dart';
import '../controllers/recruiter_login_controller.dart';

class RecruiterLoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RecruiterLoginController());
  }
}
