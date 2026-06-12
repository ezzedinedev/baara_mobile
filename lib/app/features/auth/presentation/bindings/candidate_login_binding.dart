import 'package:get/get.dart';
import 'package:opportune_bf/app/core/network/api_provider.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../controllers/candidate_login_controller.dart';

class CandidateLoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<IAuthRepository>(
        () => AuthRepositoryImpl(apiProvider: Get.find<ApiProvider>()));
    Get.lazyPut(() => CandidateLoginController(Get.find<IAuthRepository>()));
  }
}
