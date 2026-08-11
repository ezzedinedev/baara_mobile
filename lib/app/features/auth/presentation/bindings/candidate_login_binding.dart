import 'package:get/get.dart';
import 'package:baara/app/core/network/api_provider.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../controllers/candidate_login_controller.dart';

class CandidateLoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<IAuthRepository>(
        () => AuthRepositoryImpl(apiProvider: Get.find<ApiProvider>()));
    // fenix: recrée une instance fraîche si le controller a été disposé par un
    // Get.offAllNamed (OTP / mot de passe oublié → connexion). Sans ça, l'ancien
    // controller disposé était réutilisé → « TextEditingController used after
    // being disposed » sur les champs.
    Get.lazyPut(() => CandidateLoginController(Get.find<IAuthRepository>()),
        fenix: true);
  }
}
