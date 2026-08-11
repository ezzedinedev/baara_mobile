import 'package:get/get.dart';
import 'package:baara/app/core/network/api_provider.dart';

import '../../data/repositories/quiz_repository.dart';
import '../../data/repositories/training_repository_impl.dart';
import '../../domain/repositories/i_training_repository.dart';
import '../controllers/training_player_controller.dart';

class TrainingPlayerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ITrainingRepository>(
      () => TrainingRepositoryImpl(apiProvider: Get.find<ApiProvider>()),
    );
    Get.lazyPut<QuizRepository>(
      () => QuizRepository(apiProvider: Get.find<ApiProvider>()),
    );
    Get.lazyPut(
      () => TrainingPlayerController(
        Get.find<ITrainingRepository>(),
        Get.find<QuizRepository>(),
      ),
    );
  }
}
