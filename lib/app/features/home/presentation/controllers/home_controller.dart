import 'package:baara/app/core/services/app_update_service.dart';
import 'dart:async';

import 'package:get/get.dart';

import '../../../../core/services/candidate_session_guard.dart';
import '../../../../core/services/onboarding_service.dart';
import '../../../../core/services/post_auth_bootstrap.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../../routes/app_routes.dart';
import '../../../community/presentation/controllers/community_controller.dart';
import '../../../notifications/presentation/controllers/notifications_controller.dart';

class HomeController extends GetxController {
  final currentTabIndex = 0.obs;

  // Index des onglets (cf. _LazyTabStack dans home_screen) :
  // 0 Accueil · 1 Offre · 2 Communauté · 3 Suivi · 4 Profil.
  static const _networkTab = 2;

  /// Segment actif du hub Opportunités (0 = Offres, 1 = Formations).
  final opportunitesTab = 0.obs;

  /// Sous-onglet Suivi à ouvrir (0–4), consommé une fois par [SuiviScreen].
  final suiviSubTab = RxnInt();

  /// Candidature à mettre en évidence dans l'onglet Suivi (deep link / push).
  final highlightApplicationId = RxnString();

  /// Lit et efface le sous-onglet Suivi en attente.
  int? consumeSuiviSubTab() {
    final v = suiviSubTab.value;
    suiviSubTab.value = null;
    return v;
  }

  /// Lit et efface l'id candidature à surligner.
  String? consumeHighlightApplicationId() {
    final v = highlightApplicationId.value;
    highlightApplicationId.value = null;
    return v;
  }

  /// Bascule sur l'onglet Opportunités en présélectionnant un segment.
  void openOpportunites({int segment = 0}) {
    opportunitesTab.value = segment;
    changeTab(1);
  }

  // Rafraîchissement périodique des compteurs (pastilles nav + cloche).
  Timer? _badgeTimer;
  static const _badgeInterval = Duration(seconds: 45);

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      if (args['tab'] is int) currentTabIndex.value = args['tab'] as int;
      if (args['suiviTab'] is int) suiviSubTab.value = args['suiviTab'] as int;
      final appId = args['applicationId']?.toString();
      if (appId != null && appId.isNotEmpty) {
        highlightApplicationId.value = appId;
      }
    }
    unawaited(_bootstrapAuthenticatedArea());
    if (Get.isRegistered<RealtimeService>()) {
      Get.find<RealtimeService>().start();
    }
    refreshBadges();
    _badgeTimer = Timer.periodic(_badgeInterval, (_) => refreshBadges());
  }

  Future<void> _bootstrapAuthenticatedArea() async {
    if (Get.isRegistered<CandidateSessionGuard>()) {
      await Get.find<CandidateSessionGuard>().ensureCandidateOrSignOut();
    }
    if (Get.currentRoute != AppRoutes.home) return;
    final onboarding = Get.find<OnboardingService>();
    if (!await onboarding.isCompleted()) {
      Get.offAllNamed(AppRoutes.onboarding);
      return;
    }
    await PostAuthBootstrap.syncPushToken();
    // Mise à jour proposée ou imposée depuis l'admin du site.
    unawaited(AppUpdateService.checkAndPrompt());
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
    if (Get.isRegistered<NotificationsController>()) {
      Get.find<NotificationsController>().refreshUnreadCount();
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
