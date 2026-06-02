import 'package:get/get.dart';
import 'package:opportune_bf/app/core/network/api_provider.dart';

import '../../data/repositories/training_repository_impl.dart';
import '../../domain/repositories/i_training_repository.dart';
import '../controllers/training_player_controller.dart';

class TrainingPlayerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ITrainingRepository>(
      () => TrainingRepositoryImpl(apiProvider: Get.find<ApiProvider>()),
    );
    Get.lazyPut(
      () => TrainingPlayerController(Get.find<ITrainingRepository>()),
    );
  }
}
