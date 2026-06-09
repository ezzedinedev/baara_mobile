import 'package:get/get.dart';
import 'package:opportune_bf/app/core/services/auth_token_store.dart';
import '../controllers/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SplashController(Get.find<AuthTokenStore>()));
  }
}
