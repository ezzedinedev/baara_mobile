import 'package:get/get.dart';
import 'package:baara/app/core/network/api_provider.dart';
import '../../data/repositories/ia_repository_impl.dart';
import '../../domain/repositories/i_ia_repository.dart';
import '../controllers/chatbot_controller.dart';
import '../controllers/score_profil_controller.dart';
import '../controllers/cv_audit_controller.dart';

class IaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<IIaRepository>(
      () => IaRepositoryImpl(apiProvider: Get.find<ApiProvider>()),
    );
    Get.lazyPut(() => ChatbotController(Get.find<IIaRepository>()));
    Get.lazyPut(() => ScoreProfilController(Get.find<IIaRepository>()));
    Get.lazyPut(() => CvAuditController(Get.find<IIaRepository>()));
  }
}
