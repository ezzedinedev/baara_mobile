import 'package:get/get.dart';
import 'package:opportune_bf/app/core/network/api_provider.dart';
import '../../../../data/repositories/ai_repository.dart';
import '../controllers/chatbot_controller.dart';
import '../controllers/score_profil_controller.dart';
import '../controllers/cv_audit_controller.dart';

class IaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AiRepository>(
      () => AiRepository(apiProvider: Get.find<ApiProvider>()),
    );
    Get.lazyPut(() => ChatbotController(Get.find<AiRepository>()));
    Get.lazyPut(() => ScoreProfilController(Get.find<AiRepository>()));
    Get.lazyPut(() => CvAuditController(Get.find<AiRepository>()));
  }
}
