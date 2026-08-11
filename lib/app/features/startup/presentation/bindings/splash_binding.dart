import 'package:get/get.dart';
import 'package:baara/app/core/network/api_provider.dart';
import 'package:baara/app/core/services/auth_token_store.dart';
import 'package:baara/app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:baara/app/features/auth/domain/repositories/i_auth_repository.dart';
import '../controllers/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<IAuthRepository>(
      () => AuthRepositoryImpl(apiProvider: Get.find<ApiProvider>()),
    );
    Get.lazyPut(
      () => SplashController(
        Get.find<AuthTokenStore>(),
        Get.find<IAuthRepository>(),
      ),
    );
  }
}
