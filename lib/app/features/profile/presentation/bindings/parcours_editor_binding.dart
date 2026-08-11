import 'package:get/get.dart';
import 'package:baara/app/core/network/api_provider.dart';

import '../../data/repositories/cv_editor_repository.dart';
import '../controllers/parcours_editor_controller.dart';

class ParcoursEditorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => CvEditorRepository(apiProvider: Get.find<ApiProvider>()),
    );
    Get.lazyPut(() => ParcoursEditorController(Get.find<CvEditorRepository>()));
  }
}
