import 'package:get/get.dart';

import 'core/security/auth_token_store.dart';
import 'data/providers/api_provider.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthTokenStore>(() => const AuthTokenStore(), fenix: true);
    Get.lazyPut<ApiProvider>(() => ApiProvider(), fenix: true);
  }
}