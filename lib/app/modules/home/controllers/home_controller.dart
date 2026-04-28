import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/auth_token_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/asset_url.dart';
import '../../../core/network/api_provider.dart';
import '../../../../routes/app_routes.dart';
import '../../../core/widgets/widgets.dart';
import 'home_profile_manager.dart';


part 'home_controller_parts/models.dart';
part 'home_controller_parts/parsing.dart';
part 'home_controller_parts/load_and_swipe.dart';
part 'home_controller_parts/formations_methods.dart';
part 'home_controller_parts/messaging_methods.dart';
part 'home_controller_parts/scoring_methods.dart';

class HomeController extends GetxController {
  HomeController() : _apiProvider = Get.find<ApiProvider>() {
    profileManager = HomeProfileManager(_apiProvider);
  }

  static final NumberFormat _moneyFormat = NumberFormat.decimalPattern('fr_FR');

  final ApiProvider _apiProvider;
  late final HomeProfileManager profileManager;

  final currentTabIndex = 0.obs;
  final currentOfferIndex = 0.obs;
  final offerDragDx = 0.0.obs;
  final isOfferAnimating = false.obs;
  final pendingMatch = Rx<HomeOfferMatchResult?>(null);
  final activeConversationId = RxnString();
  final chatInputCtrl = TextEditingController();
  final isSendingChat = false.obs;
  final enrollingFormationId = RxnString();
  final completingLessonId = RxnString();
  final loadingLearningFormationId = RxnString();
  final messageThreads = <String, RxList<HomeChatMessage>>{}.obs;
  final unreadCounters = <String, int>{}.obs;
  final notifications = <HomeNotificationPreview>[].obs;
  final offers = <HomeOfferPreview>[].obs;
  final formations = <HomeFormationPreview>[].obs;
  final isLoadingOffers = false.obs;
  final isLoadingFormations = false.obs;
  final offersLoadError = ''.obs;
  final formationsLoadError = ''.obs;

  static const int profileTabIndex = 4;

  /// Items visibles dans la bottom nav. Le profil est volontairement exclu :
  /// il est accessible via l'avatar en haut à gauche de l'écran d'accueil.
  /// `label` est une cle i18n — la traduction se fait au render via `.tr`.
  final navItems = const <HomeNavItem>[
    HomeNavItem(label: 'nav.home', icon: IconlyBold.home),
    HomeNavItem(label: 'nav.messages', icon: IconlyBold.chat),
    HomeNavItem(label: 'nav.offers', icon: IconlyBold.work),
    HomeNavItem(label: 'nav.trainings', icon: IconlyBold.paper),
  ];

  /// Profil candidat synthetique calcule a chaud depuis le profil reel
  /// charge du backend. Plus de hardcode — chaque score est specifique a
  /// l'utilisateur connecte. Si le profil n'est pas encore charge, on
  /// retombe sur des valeurs neutres pour ne pas bloquer le scoring.
  HomeCandidateProfile get candidateProfile {
    final profile = profileManager.profile.value;
    final locations = <String>[
      if (profile.city.trim().isNotEmpty) profile.city.trim(),
      if (profile.region.trim().isNotEmpty) profile.region.trim(),
    ];
    return HomeCandidateProfile(
      headline: profile.headline.trim().isEmpty
          ? 'Candidat'
          : profile.headline.trim(),
      experienceYears: _candidateExperienceYears,
      preferredLocations: locations,
      // Sans preference user explicite, on accepte tous les contrats courants.
      preferredContracts: const [
        'CDI',
        'CDD',
        'Stage',
        'Alternance',
        'Freelance',
        'Mission',
      ],
      skills: profile.skills.isEmpty
          ? const <String>[]
          : profile.skills.toList(growable: false),
    );
  }

  /// Heuristique annees d'experience : derivee du nombre d'experiences
  /// renseignees + un poids 1.5 par defaut. Si aucune entree, on retombe
  /// sur 0 (junior). A remplacer si le backend expose un champ explicite.
  int get _candidateExperienceYears {
    final cv = profileManager.cvSections;
    final experiences = cv
        .where((s) => s.sectionType.toLowerCase().contains('experience'))
        .length;
    return (experiences * 1.5).round();
  }

  /// Conversations chargees depuis le backend (GET /messages).
  /// Plus de donnees demo — la liste reste vide tant que la requete
  /// n'a pas abouti ou que le backend n'a pas de conversation.
  final conversations = <HomeConversationPreview>[].obs;
  final isLoadingConversations = false.obs;
  final conversationsLoadError = ''.obs;

  /// Nombre total de tabs dans l'IndexedStack (nav items + onglet profil caché).
  int get _totalTabs => navItems.length + 1;

  void changeTab(int index) {
    if (index < 0 || index >= _totalTabs) {
      return;
    }
    currentTabIndex.value = index;
  }

  /// Ouvre l'onglet profil (non présent dans la bottom nav).
  void goToProfile() => currentTabIndex.value = profileTabIndex;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
    loadPublishedContent();
    loadConversations();
    profileManager.loadAll();
  }

  @override
  void onClose() {
    chatInputCtrl.dispose();
    super.onClose();
  }

  Future<void> logout() async {
    await const AuthTokenStore().clearSession();
    Get.offAllNamed(AppRoutes.profileSelection);
  }

  Future<List<dynamic>> _fetchPublishedOffers() async {
    final response = await _apiProvider.getJson(ApiConstants.offers);
    if (response['success'] == true) {
      return _extractItems(response['data']);
    }

    final fallback = await _apiProvider.getJson(ApiConstants.offersFeatured);
    if (fallback['success'] == true) {
      return _extractItems(fallback['data']);
    }

    throw Exception(
      _extractApiMessage(
        response,
        fallback: 'Impossible de charger les offres publiees.',
      ),
    );
  }

  void _addNotification({
    required String title,
    required String body,
    required String category,
    required IconData icon,
  }) {
    notifications.insert(
      0,
      HomeNotificationPreview(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        body: body,
        category: category,
        createdAt: DateTime.now(),
        icon: icon,
        isRead: false,
      ),
    );
  }

}
