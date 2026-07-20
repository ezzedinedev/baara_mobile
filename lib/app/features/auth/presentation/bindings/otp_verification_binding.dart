import 'package:get/get.dart';
import 'package:jobaway/app/core/network/api_provider.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../controllers/otp_verification_controller.dart';

class OtpVerificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<IAuthRepository>(
      () => AuthRepositoryImpl(apiProvider: Get.find<ApiProvider>()),
    );
    Get.lazyPut(() => OtpVerificationController(Get.find<IAuthRepository>()));
  }
}
