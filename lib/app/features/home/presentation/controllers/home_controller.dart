import 'package:get/get.dart';

import '../../../../core/services/realtime_service.dart';
import '../../../messaging/presentation/controllers/messages_controller.dart';
import '../../../community/presentation/controllers/community_controller.dart';

class HomeController extends GetxController {
  final currentTabIndex = 0.obs;

  // Index des onglets (cf. _LazyTabStack dans home_screen).
  static const _networkTab = 2;
  static const _messagesTab = 3;

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
    // Rafraîchit les compteurs à l'entrée de l'onglet → badges (non-lus,
    // demandes) toujours exacts, même après lecture/réception ailleurs.
    if (index == _messagesTab && Get.isRegistered<MessagesController>()) {
      Get.find<MessagesController>().loadConversations();
    } else if (index == _networkTab &&
        Get.isRegistered<CommunityController>()) {
      Get.find<CommunityController>().loadPendingConnections();
    }
  }
}
