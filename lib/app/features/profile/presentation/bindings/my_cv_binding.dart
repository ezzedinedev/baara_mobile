import 'package:get/get.dart';
import 'package:jobaway/app/core/network/api_provider.dart';

import '../../data/repositories/cv_preview_repository.dart';
import '../controllers/my_cv_controller.dart';

/// Écran « Mes CVs ». Réutilise [CvPreviewRepository] : c'est déjà lui qui
/// expose l'état du CV côté serveur (`GET /profile/cv-builder`).
class MyCvBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CvPreviewRepository>(
      () => CvPreviewRepository(apiProvider: Get.find<ApiProvider>()),
    );
    Get.lazyPut<MyCvController>(
      () => MyCvController(Get.find<CvPreviewRepository>()),
    );
  }
}
