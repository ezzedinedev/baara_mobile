import 'dart:async';

import 'package:get/get.dart';

import '../../../../core/services/realtime_service.dart';
import '../../../messaging/presentation/controllers/messages_controller.dart';
import '../../../community/presentation/controllers/community_controller.dart';
import '../../../notifications/presentation/controllers/notifications_controller.dart';

class HomeController extends GetxController {
  final currentTabIndex = 0.obs;

  // Index des onglets (cf. _LazyTabStack dans home_screen) :
  // 0 Accueil · 1 Offre · 2 Communauté · 3 Suivi · 4 Profil.
  static const _networkTab = 2;

  /// Segment actif du hub Opportunités (0 = Offres, 1 = Formations). Permet à
  /// l'accueil de pré-sélectionner le bon segment via « Tout voir ».
  final opportunitesTab = 0.obs;

  /// Bascule sur l'onglet Opportunités en présélectionnant un segment.
  void openOpportunites({int segment = 0}) {
    opportunitesTab.value = segment;
    changeTab(1);
  }

  // Stubs for compatibility with FcmService
  final activeConversationId = RxnString();
  void loadConversations() {}
  void loadConversationThread(String id) {}

  // Rafraîchissement périodique des compteurs (pastilles nav + cloche).
  Timer? _badgeTimer;
  static const _badgeInterval = Duration(seconds: 45);

  @override
  void onInit() {
    super.onInit();
    // Point d'entrée authentifié : on démarre le temps réel (no-op si pas de
    // session ou déjà connecté).
    if (Get.isRegistered<RealtimeService>()) {
      Get.find<RealtimeService>().start();
    }
    // Alimente les badges DÈS le démarrage (sans attendre l'ouverture de chaque
    // onglet) puis les garde à jour périodiquement.
    refreshBadges();
    _badgeTimer = Timer.periodic(_badgeInterval, (_) => refreshBadges());
  }

  @override
  void onClose() {
    _badgeTimer?.cancel();
    super.onClose();
  }

  /// Recharge les compteurs alimentant les pastilles des onglets (messages,
  /// réseau) et la cloche (notifications). Appelé au boot, en polling, et
  /// peut l'être après un événement temps réel / push FCM.
  void refreshBadges() {
    // Notifications : compteur seul, sans perturber la liste affichée.
    if (Get.isRegistered<NotificationsController>()) {
      Get.find<NotificationsController>().refreshUnreadCount();
    }
    if (Get.isRegistered<MessagesController>()) {
      Get.find<MessagesController>().loadConversations();
    }
    if (Get.isRegistered<CommunityController>()) {
      Get.find<CommunityController>().loadPendingConnections();
    }
  }

  void changeTab(int index) {
    currentTabIndex.value = index;
    // Rafraîchit les compteurs à l'entrée de l'onglet → badges (demandes de
    // connexion) toujours exacts, même après une action ailleurs. Le hub Suivi
    // charge ses données à son montage (SuiviController.onInit).
    if (index == _networkTab && Get.isRegistered<CommunityController>()) {
      Get.find<CommunityController>().loadPendingConnections();
    }
  }
}
