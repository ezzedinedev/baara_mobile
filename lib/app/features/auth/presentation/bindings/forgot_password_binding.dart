import 'package:get/get.dart';
import 'package:baara/app/core/network/api_provider.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../controllers/forgot_password_controller.dart';

class ForgotPasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<IAuthRepository>(
      () => AuthRepositoryImpl(apiProvider: Get.find<ApiProvider>()),
    );
    // fenix: recrée le controller après un dispose (Get.offAllNamed), sinon les
    // TextEditingController réutilisés déclenchent « used after being disposed ».
    Get.lazyPut(() => ForgotPasswordController(Get.find<IAuthRepository>()),
        fenix: true);
  }
}
