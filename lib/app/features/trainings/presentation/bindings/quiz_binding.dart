import 'package:get/get.dart';
import 'package:baara/app/core/network/api_provider.dart';

import '../../data/repositories/quiz_repository.dart';
import '../controllers/quiz_controller.dart';

class QuizBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<QuizRepository>(
      () => QuizRepository(apiProvider: Get.find<ApiProvider>()),
    );
    Get.lazyPut<QuizController>(
      () => QuizController(Get.find<QuizRepository>()),
    );
  }
}
