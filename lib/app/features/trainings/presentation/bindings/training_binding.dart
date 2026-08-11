import 'package:get/get.dart';
import 'package:baara/app/core/network/api_provider.dart';
import '../../data/repositories/training_repository_impl.dart';
import '../../domain/repositories/i_training_repository.dart';
import '../controllers/trainings_controller.dart';

class TrainingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ITrainingRepository>(
      () => TrainingRepositoryImpl(apiProvider: Get.find<ApiProvider>()),
    );
    Get.lazyPut(() => TrainingsController(Get.find<ITrainingRepository>()));
  }
}
