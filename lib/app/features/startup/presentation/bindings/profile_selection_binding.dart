import 'package:get/get.dart';
import '../controllers/profile_selection_controller.dart';

class ProfileSelectionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ProfileSelectionController());
  }
}
