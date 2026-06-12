import 'package:get/get.dart';
import 'package:opportune_bf/app/core/network/api_provider.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../controllers/register_controller.dart';

class RegisterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<IAuthRepository>(
        () => AuthRepositoryImpl(apiProvider: Get.find<ApiProvider>()));
    Get.lazyPut(() => RegisterController(Get.find<IAuthRepository>()));
  }
}
