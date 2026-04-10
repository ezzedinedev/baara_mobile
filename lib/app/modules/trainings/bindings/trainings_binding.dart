import 'package:get/get.dart';

import '../controllers/trainings_controller.dart';

class TrainingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TrainingsController>(() => TrainingsController());
  }
}