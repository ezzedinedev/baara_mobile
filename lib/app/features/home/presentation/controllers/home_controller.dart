import 'package:get/get.dart';

import '../../../../core/services/realtime_service.dart';

class HomeController extends GetxController {
  final currentTabIndex = 0.obs;

  // Stubs for compatibility with FcmService
  final activeConversationId = RxnString();
  void loadConversations() {}
  void loadConversationThread(String id) {}

  @override
  void onInit() {
    super.onInit();
    // Point d'entrée authentifié : on démarre le temps réel (no-op si pas de
    // session ou déjà connecté).
    if (Get.isRegistered<RealtimeService>()) {
      Get.find<RealtimeService>().start();
    }
  }

  void changeTab(int index) {
    currentTabIndex.value = index;
  }
}
