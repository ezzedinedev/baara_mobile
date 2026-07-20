import 'package:get/get.dart';
import 'package:jobaway/app/core/network/api_provider.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../controllers/email_verification_controller.dart';

class EmailVerificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<IAuthRepository>(
      () => AuthRepositoryImpl(apiProvider: Get.find<ApiProvider>()),
    );
    Get.lazyPut(() => EmailVerificationController(Get.find<IAuthRepository>()));
  }
}
