import 'package:get/get.dart';
import 'package:opportune_bf/app/core/network/api_provider.dart';

import '../../data/repositories/training_repository_impl.dart';
import '../../domain/repositories/i_training_repository.dart';
import '../controllers/training_detail_controller.dart';

class TrainingDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ITrainingRepository>(
      () => TrainingRepositoryImpl(apiProvider: Get.find<ApiProvider>()),
    );
    Get.lazyPut(
        () => TrainingDetailController(Get.find<ITrainingRepository>()));
  }
}
