import 'package:get/get.dart';
import 'package:baara/app/core/network/api_provider.dart';

import '../../data/repositories/cv_assistant_repository.dart';
import '../../data/repositories/cv_import_repository.dart';
import '../../data/repositories/cv_preview_repository.dart';
import '../../data/repositories/cv_editor_repository.dart';
import '../controllers/cv_assistant_controller.dart';
import '../controllers/cv_import_controller.dart';
import '../controllers/cv_preview_controller.dart';
import '../controllers/cv_editor_controller.dart';

class CvBuilderBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CvAssistantRepository>(
      () => CvAssistantRepository(apiProvider: Get.find<ApiProvider>()),
    );
    Get.lazyPut<CvAssistantController>(
      () => CvAssistantController(Get.find<CvAssistantRepository>()),
    );
    Get.lazyPut<CvImportRepository>(
      () => CvImportRepository(apiProvider: Get.find<ApiProvider>()),
    );
    Get.lazyPut<CvImportController>(
      () => CvImportController(Get.find<CvImportRepository>()),
    );
    Get.lazyPut<CvPreviewRepository>(
      () => CvPreviewRepository(apiProvider: Get.find<ApiProvider>()),
    );
    Get.lazyPut<CvPreviewController>(
      () => CvPreviewController(Get.find<CvPreviewRepository>()),
    );
    Get.lazyPut<CvEditorRepository>(
      () => CvEditorRepository(apiProvider: Get.find<ApiProvider>()),
    );
    Get.lazyPut<CvEditorController>(
      () => CvEditorController(Get.find<CvEditorRepository>()),
    );
  }
}
