import 'package:get/get.dart';

import '../controllers/training_detail_controller.dart';
import '../controllers/trainings_controller.dart';

/// Binding du detail formation : injecte un [TrainingDetailController] frais
/// et garantit la presence du [TrainingsController] pour partager l'etat
/// "enrolled" avec la liste.
class TrainingDetailBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<TrainingsController>()) {
      Get.lazyPut<TrainingsController>(() => TrainingsController());
    }
    Get.lazyPut<TrainingDetailController>(() => TrainingDetailController());
  }
}
