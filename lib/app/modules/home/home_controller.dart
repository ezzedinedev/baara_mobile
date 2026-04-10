import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/constants/api_constants.dart';
import '../../core/security/auth_token_store.dart';
import '../../data/providers/api_provider.dart';
import '../../../routes/app_routes.dart';
import 'home_profile_manager.dart';

class HomeNavItem {
  const HomeNavItem({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

class HomeOfferPreview {
  const HomeOfferPreview({
    required this.title,
    required this.company,
    required this.location,
    required this.salary,
    required this.contractType,
    required this.requiredSkills,
    required this.minYearsExperience,
    required this.description,
    required this.sector,
    required this.experienceLabel,
    required this.deadlineLabel,
    required this.isRemote,
  });

  final String title;
  final String company;
  final String location;
  final String salary;
  final String contractType;
  final List<String> requiredSkills;
  final int minYearsExperience;
  final String description;
  final String sector;
  final String experienceLabel;
  final String deadlineLabel;
  final bool isRemote;
}

class HomeCandidateProfile {
  const HomeCandidateProfile({
    required this.headline,
    required this.experienceYears,
    required this.preferredLocations,
    required this.preferredContracts,
    required this.skills,
  });

  final String headline;
  final int experienceYears;
  final List<String> preferredLocations;
  final List<String> preferredContracts;
  final List<String> skills;
}

class HomeOfferMatchResult {
  const HomeOfferMatchResult({
    required this.offer,
    required this.score,
  });

  final HomeOfferPreview offer;
  final int score;
}

class HomeFormationPreview {
  const HomeFormationPreview({
    required this.title,
    required this.providerName,
    required this.location,
    required this.formatLabel,
    required this.level,
    required this.lessons,
    required this.rating,
    required this.enrolledCount,
    required this.status,
    required this.priceLabel,
    required this.sector,
    required this.description,
    required this.durationLabel,
    required this.startDateLabel,
    required this.deadlineLabel,
    required this.certificationLabel,
    required this.languageLabel,
    required this.contactLabel,
    required this.objectives,
    required this.requirements,
  });

  final String title;
  final String providerName;
  final String location;
  final String formatLabel;
  final String level;
  final int lessons;
  final double rating;
  final int enrolledCount;
  final String status;
  final String priceLabel;
  final String sector;
  final String description;
  final String durationLabel;
  final String startDateLabel;
  final String deadlineLabel;
  final String certificationLabel;
  final String languageLabel;
  final String contactLabel;
  final List<String> objectives;
  final List<String> requirements;
}

class HomeConversationPreview {
  const HomeConversationPreview({
    required this.id,
    required this.title,
    required this.preview,
    required this.timeLabel,
    required this.unreadCount,
    required this.online,
  });

  final String id;
  final String title;
  final String preview;
  final String timeLabel;
  final int unreadCount;
  final bool online;
}

class HomeChatMessage {
  const HomeChatMessage({
    required this.text,
    required this.sentAt,
    required this.isMine,
  });

  final String text;
  final DateTime sentAt;
  final bool isMine;
}

class HomeNotificationPreview {
  const HomeNotificationPreview({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.createdAt,
    required this.icon,
    required this.isRead,
  });

  final String id;
  final String title;
  final String body;
  final String category;
  final DateTime createdAt;
  final IconData icon;
  final bool isRead;

  HomeNotificationPreview copyWith({
    String? id,
    String? title,
    String? body,
    String? category,
    DateTime? createdAt,
    IconData? icon,
    bool? isRead,
  }) {
    return HomeNotificationPreview(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      icon: icon ?? this.icon,
      isRead: isRead ?? this.isRead,
    );
  }
}

class HomeController extends GetxController {
  HomeController() : _apiProvider = Get.find<ApiProvider>() {
    profileManager = HomeProfileManager(_apiProvider);
  }

  static const int matchThreshold = 70;
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
  final messageThreads = <String, RxList<HomeChatMessage>>{}.obs;
  final unreadCounters = <String, int>{}.obs;
  final notifications = <HomeNotificationPreview>[].obs;
  final offers = <HomeOfferPreview>[].obs;
  final formations = <HomeFormationPreview>[].obs;
  final isLoadingOffers = false.obs;
  final isLoadingFormations = false.obs;
  final offersLoadError = ''.obs;
  final formationsLoadError = ''.obs;

  final navItems = const <HomeNavItem>[
    HomeNavItem(label: 'Accueil', icon: Icons.home_rounded),
    HomeNavItem(label: 'Messages', icon: Icons.chat_bubble_rounded),
    HomeNavItem(label: 'Offres', icon: Icons.local_offer_outlined),
    HomeNavItem(label: 'Formations', icon: Icons.school_outlined),
    HomeNavItem(label: 'Profil', icon: Icons.person_outline_rounded),
  ];

  final candidateProfile = const HomeCandidateProfile(
    headline: 'Developpeur Flutter Junior',
    experienceYears: 2,
    preferredLocations: ['Ouagadougou', 'Bobo-Dioulasso'],
    preferredContracts: ['CDI', 'CDD'],
    skills: [
      'Flutter',
      'Dart',
      'API REST',
      'Firebase',
      'UI',
      'Git',
      'Communication',
    ],
  );

  final conversations = const <HomeConversationPreview>[
    HomeConversationPreview(
      id: 'samatech',
      title: 'SamaTech Burkina',
      preview: 'Bonjour, votre profil nous interesse pour un entretien.',
      timeLabel: '12:45',
      unreadCount: 2,
      online: true,
    ),
    HomeConversationPreview(
      id: 'talent_sahel',
      title: 'Talent Sahel',
      preview: 'Pouvez-vous confirmer votre disponibilite cette semaine ?',
      timeLabel: 'Hier',
      unreadCount: 1,
      online: false,
    ),
    HomeConversationPreview(
      id: 'opportune_team',
      title: 'Equipe OpporTune',
      preview: 'Nouvelles offres recommandees selon votre profil.',
      timeLabel: 'Mar',
      unreadCount: 0,
      online: true,
    ),
  ];

  void changeTab(int index) {
    if (index < 0 || index >= navItems.length) {
      return;
    }
    currentTabIndex.value = index;
  }

  @override
  void onInit() {
    super.onInit();
    _seedMessagingState();
    _seedNotifications();
    loadPublishedContent();
    profileManager.loadAll();
  }

  @override
  void onClose() {
    chatInputCtrl.dispose();
    super.onClose();
  }

  Future<void> loadPublishedContent() async {
    await Future.wait([
      reloadOffers(),
      reloadFormations(),
    ]);
  }

  Future<void> reloadOffers() async {
    isLoadingOffers.value = true;
    offersLoadError.value = '';

    try {
      final rawItems = await _fetchPublishedOffers();
      final parsed = rawItems
          .map(_parseOffer)
          .whereType<HomeOfferPreview>()
          .toList(growable: false);

      offers.assignAll(parsed);
      currentOfferIndex.value = 0;
      offerDragDx.value = 0;
      pendingMatch.value = null;
    } on Exception catch (error) {
      offersLoadError.value = _friendlyErrorMessage(
        error,
        fallback: 'Impossible de charger les offres publiees.',
      );
      if (offers.isEmpty) {
        offers.clear();
      }
    } finally {
      isLoadingOffers.value = false;
    }
  }

  Future<void> reloadFormations() async {
    isLoadingFormations.value = true;
    formationsLoadError.value = '';

    try {
      final response = await _apiProvider.getJson(ApiConstants.trainings);
      if (response['success'] != true) {
        throw Exception(
          _extractApiMessage(
            response,
            fallback: 'Impossible de charger les formations publiees.',
          ),
        );
      }

      final parsed = _extractItems(response['data'])
          .map(_parseTraining)
          .whereType<HomeFormationPreview>()
          .toList(growable: false);

      formations.assignAll(parsed);
    } on Exception catch (error) {
      formationsLoadError.value = _friendlyErrorMessage(
        error,
        fallback: 'Impossible de charger les formations publiees.',
      );
      if (formations.isEmpty) {
        formations.clear();
      }
    } finally {
      isLoadingFormations.value = false;
    }
  }

  void onOfferChanged(int index) {
    currentOfferIndex.value = index;
  }

  void updateOfferDrag(double deltaX) {
    if (isOfferAnimating.value || offers.isEmpty) {
      return;
    }
    offerDragDx.value += deltaX;
  }

  Future<void> endOfferDrag(double velocityX) async {
    if (isOfferAnimating.value || offers.isEmpty) {
      return;
    }

    final drag = offerDragDx.value;
    final shouldSwipe = drag.abs() > 110 || velocityX.abs() > 850;
    if (!shouldSwipe) {
      await _animateBackToCenter();
      return;
    }

    await _animateSwipe(drag >= 0);
  }

  Future<void> swipeOfferLeft() => _animateSwipe(false);

  Future<void> swipeOfferRight() => _animateSwipe(true);

  void rewindOffer() {
    if (isOfferAnimating.value || offers.isEmpty) {
      return;
    }
    currentOfferIndex.value =
        (currentOfferIndex.value - 1 + offers.length) % offers.length;
    offerDragDx.value = 0;
  }

  void clearPendingMatch() {
    pendingMatch.value = null;
  }

  void openConversation(HomeConversationPreview conversation) {
    activeConversationId.value = conversation.id;
    unreadCounters[conversation.id] = 0;
  }

  void closeConversation() {
    activeConversationId.value = null;
    chatInputCtrl.clear();
  }

  HomeConversationPreview? get activeConversation {
    final id = activeConversationId.value;
    if (id == null) {
      return null;
    }
    for (final conversation in conversations) {
      if (conversation.id == id) {
        return conversation;
      }
    }
    return null;
  }

  RxList<HomeChatMessage> threadFor(String conversationId) {
    return messageThreads.putIfAbsent(
      conversationId,
      () => <HomeChatMessage>[].obs,
    );
  }

  int unreadFor(String conversationId) {
    return unreadCounters[conversationId] ?? 0;
  }

  int get unreadNotificationsCount =>
      notifications.where((notification) => !notification.isRead).length;

  void markNotificationAsRead(String notificationId) {
    final index = notifications.indexWhere(
      (notification) => notification.id == notificationId,
    );
    if (index < 0 || notifications[index].isRead) {
      return;
    }
    notifications[index] = notifications[index].copyWith(isRead: true);
  }

  void markAllNotificationsAsRead() {
    notifications.assignAll(
      notifications
          .map((notification) => notification.copyWith(isRead: true))
          .toList(growable: false),
    );
  }

  Future<void> sendActiveMessage() async {
    final conversationId = activeConversationId.value;
    final text = chatInputCtrl.text.trim();
    if (conversationId == null || text.isEmpty || isSendingChat.value) {
      return;
    }

    isSendingChat.value = true;
    final now = DateTime.now();
    threadFor(conversationId).add(
      HomeChatMessage(
        text: text,
        sentAt: now,
        isMine: true,
      ),
    );
    chatInputCtrl.clear();

    await Future<void>.delayed(const Duration(milliseconds: 650));
    final reply = _autoReplyForConversation(conversationId);
    threadFor(conversationId).add(
      HomeChatMessage(
        text: reply,
        sentAt: DateTime.now(),
        isMine: false,
      ),
    );
    _addNotification(
      title: 'Nouveau message',
      body: reply,
      category: 'Message',
      icon: Icons.chat_bubble_outline_rounded,
    );
    isSendingChat.value = false;
  }

  HomeOfferPreview offerAtOffset(int offset) {
    if (offers.isEmpty) {
      throw StateError('Aucune offre disponible');
    }

    final index = (currentOfferIndex.value + offset) % offers.length;
    return offers[index];
  }

  int scoreForOffset(int offset) {
    return scoreForOffer(offerAtOffset(offset));
  }

  int scoreForOffer(HomeOfferPreview offer) {
    final profileSkills =
        candidateProfile.skills.map((skill) => skill.toLowerCase()).toSet();
    final requiredSkills =
        offer.requiredSkills.map((skill) => skill.toLowerCase()).toList();

    var skillMatches = 0;
    for (final skill in requiredSkills) {
      if (profileSkills.contains(skill)) {
        skillMatches += 1;
      }
    }

    final skillScore = requiredSkills.isEmpty
        ? 50
        : ((skillMatches / requiredSkills.length) * 50).round();

    final locationScore = candidateProfile.preferredLocations
            .map((e) => e.toLowerCase())
            .any((location) => offer.location.toLowerCase().contains(location))
        ? 20
        : 5;

    final contractScore = candidateProfile.preferredContracts
            .map((e) => e.toLowerCase())
            .contains(offer.contractType.toLowerCase())
        ? 15
        : 4;

    final experienceGap =
        candidateProfile.experienceYears - offer.minYearsExperience;
    final experienceScore = experienceGap >= 0
        ? 15
        : experienceGap == -1
            ? 9
            : 3;

    final total = skillScore + locationScore + contractScore + experienceScore;
    return total.clamp(0, 100);
  }

  Future<void> _animateBackToCenter() async {
    isOfferAnimating.value = true;
    offerDragDx.value = 0;
    await Future<void>.delayed(const Duration(milliseconds: 180));
    isOfferAnimating.value = false;
  }

  Future<void> _animateSwipe(bool toRight) async {
    if (isOfferAnimating.value || offers.isEmpty) {
      return;
    }

    final swipedOffer = offerAtOffset(0);
    final swipedScore = scoreForOffer(swipedOffer);

    isOfferAnimating.value = true;
    offerDragDx.value = toRight ? 420 : -420;
    await Future<void>.delayed(const Duration(milliseconds: 210));
    currentOfferIndex.value = (currentOfferIndex.value + 1) % offers.length;
    offerDragDx.value = 0;
    isOfferAnimating.value = false;

    if (!toRight) {
      return;
    }

    if (swipedScore >= matchThreshold) {
      pendingMatch.value = HomeOfferMatchResult(
        offer: swipedOffer,
        score: swipedScore,
      );
      _addNotification(
        title: 'Match avec une offre',
        body: '${swipedOffer.company} - ${swipedOffer.title} ($swipedScore%)',
        category: 'Offre',
        icon: Icons.local_offer_outlined,
      );
      return;
    }

    Get.snackbar(
      'Compatibilite',
      'Pas de match pour ${swipedOffer.title} ($swipedScore%)',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
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

  List<dynamic> _extractItems(dynamic payload) {
    if (payload is List) {
      return payload;
    }

    final map = _asMap(payload);
    if (map == null) {
      return const [];
    }

    final items = map['items'];
    if (items is List) {
      return items;
    }

    final pageItems = map['data'];
    if (pageItems is List) {
      return pageItems;
    }

    return const [];
  }

  HomeOfferPreview? _parseOffer(dynamic payload) {
    final data = _asMap(payload);
    if (data == null) {
      return null;
    }

    final employer =
        _asMap(data['employer']) ?? _asMap(data['employer_profile']);
    final skills = _asStringList(data['required_skills']);

    return HomeOfferPreview(
      title: _firstNonEmpty([
        _asString(data['title']),
      ], fallback: 'Offre publiee'),
      company: _firstNonEmpty([
        _asString(employer?['company_name']),
        _asString(data['company_name']),
      ], fallback: 'Entreprise'),
      location: _formatOfferLocation(data, employer),
      salary: _formatSalary(data),
      contractType: _firstNonEmpty([
        _asString(data['contract_type']),
      ], fallback: 'Contrat non precise'),
      requiredSkills: skills,
      minYearsExperience: _parseMinYearsExperience(data['experience_level']),
      description: _firstNonEmpty([
        _asString(data['description']),
      ], fallback: 'Aucune description fournie.'),
      sector: _firstNonEmpty([
        _asString(_asMap(data['sector'])?['name']),
      ], fallback: 'Secteur non precise'),
      experienceLabel: _formatExperienceLabel(data),
      deadlineLabel: _formatOfferDeadline(
        data['deadline'] ?? data['application_deadline'],
      ),
      isRemote: _asBool(data['is_remote']),
    );
  }

  HomeFormationPreview? _parseTraining(dynamic payload) {
    final data = _asMap(payload);
    if (data == null) {
      return null;
    }

    final provider = _asMap(data['provider']);

    return HomeFormationPreview(
      title: _firstNonEmpty([
        _asString(data['title']),
      ], fallback: 'Formation publiee'),
      providerName: _resolveTrainingProviderName(provider),
      location: _firstNonEmpty([
        _asString(data['location']),
      ], fallback: 'Lieu non precise'),
      formatLabel: _formatTrainingFormat(data['format']),
      level: _formatTrainingLevel(data['level']),
      lessons: _asInt(data['modules_count']),
      rating: _asDouble(data['avg_rating']),
      enrolledCount: _asInt(data['enrolled_count']),
      status: _formatTrainingStatus(data),
      priceLabel: _formatTrainingPrice(data['cost_fcfa']),
      sector: _firstNonEmpty([
        _asString(_asMap(data['sector'])?['name']),
      ], fallback: 'Secteur non precise'),
      description: _firstNonEmpty([
        _asString(data['description']),
        _asString(data['summary']),
        _asString(data['overview']),
      ], fallback: 'Description non fournie.'),
      durationLabel: _formatTrainingDuration(data),
      startDateLabel: _formatTrainingDateLabel(
        data['start_date'] ?? data['starts_at'] ?? data['published_at'],
        fallback: 'Date de debut non precisee',
      ),
      deadlineLabel: _formatTrainingDateLabel(
        data['registration_deadline'] ?? data['deadline'] ?? data['end_date'],
        fallback: 'Date limite non precisee',
      ),
      certificationLabel: _formatTrainingCertification(data),
      languageLabel: _firstNonEmpty([
        _asString(data['language']),
        _asString(data['teaching_language']),
      ], fallback: 'Langue non precisee'),
      contactLabel: _firstNonEmpty([
        _asString(data['contact_email']),
        _asString(data['contact_phone']),
        _asString(provider?['email']),
      ], fallback: 'Contact non precise'),
      objectives: _asTextList(
        data['objectives'] ?? data['goals'] ?? data['learning_outcomes'],
      ),
      requirements: _asTextList(
        data['requirements'] ?? data['prerequisites'] ?? data['audience'],
      ),
    );
  }

  String _formatOfferLocation(
    Map<String, dynamic> offer,
    Map<String, dynamic>? employer,
  ) {
    final parts = <String>[
      if (_asString(offer['city']) case final city? when city.isNotEmpty) city,
      if (_asString(offer['region']) case final region? when region.isNotEmpty)
        region,
      if (_asBool(offer['is_remote'])) 'Remote',
    ];

    if (parts.isEmpty && employer != null) {
      if (_asString(employer['city']) case final city? when city.isNotEmpty) {
        parts.add(city);
      }
      if (_asString(employer['region']) case final region?
          when region.isNotEmpty) {
        parts.add(region);
      }
    }

    return parts.isEmpty ? 'Lieu non precise' : parts.join(' • ');
  }

  String _formatSalary(Map<String, dynamic> data) {
    if (!_asBool(data['salary_visible'])) {
      return 'Salaire a negocier';
    }

    final min = _asNum(data['salary_min']);
    final max = _asNum(data['salary_max']);
    final currency = _firstNonEmpty([
      _asString(data['salary_currency']),
    ], fallback: 'XOF');

    if (min == null && max == null) {
      return 'Salaire non precise';
    }
    if (min != null && max != null) {
      return '${_formatMoney(min)} - ${_formatMoney(max)} $currency';
    }
    if (min != null) {
      return 'A partir de ${_formatMoney(min)} $currency';
    }
    return 'Jusqu\'a ${_formatMoney(max!)} $currency';
  }

  String _formatExperienceLabel(Map<String, dynamic> data) {
    final experienceLevel = _asString(data['experience_level']);
    if (experienceLevel != null && experienceLevel.isNotEmpty) {
      return experienceLevel;
    }

    final minYears = _parseMinYearsExperience(data['experience_level']);
    if (minYears > 0) {
      return '$minYears an(s)';
    }

    final requiredLevel = _asString(data['required_level']);
    if (requiredLevel != null && requiredLevel.isNotEmpty) {
      return requiredLevel;
    }

    return 'Non precise';
  }

  int _parseMinYearsExperience(dynamic value) {
    final raw = _asString(value);
    if (raw == null) {
      return 0;
    }

    final match = RegExp(r'(\d+)').firstMatch(raw);
    if (match == null) {
      return 0;
    }

    return int.tryParse(match.group(1) ?? '') ?? 0;
  }

  String _formatOfferDeadline(dynamic value) {
    final raw = _asString(value);
    if (raw == null || raw.isEmpty) {
      return 'Date limite non precisee';
    }

    final date = DateTime.tryParse(raw);
    if (date == null) {
      return 'Date limite non precisee';
    }

    return 'Cloture le ${DateFormat('dd/MM/yyyy').format(date.toLocal())}';
  }

  String _formatTrainingFormat(dynamic value) {
    switch ((_asString(value) ?? '').toLowerCase()) {
      case 'online':
        return 'En ligne';
      case 'onsite':
        return 'Presentiel';
      case 'hybrid':
        return 'Hybride';
      default:
        return 'Format non precise';
    }
  }

  String _formatTrainingLevel(dynamic value) {
    switch ((_asString(value) ?? '').toLowerCase()) {
      case 'beginner':
        return 'Debutant';
      case 'intermediate':
        return 'Intermediaire';
      case 'advanced':
        return 'Avance';
      default:
        return _firstNonEmpty([
          _asString(value),
        ], fallback: 'Tous niveaux');
    }
  }

  String _formatTrainingStatus(Map<String, dynamic> data) {
    final status = (_asString(data['status']) ?? '').toLowerCase();
    if (status == 'active') {
      return 'Publiee';
    }

    return _firstNonEmpty([
      _asString(data['status']),
    ], fallback: 'Disponible');
  }

  String _formatTrainingDuration(Map<String, dynamic> data) {
    final explicit = _firstNonEmpty([
      _asString(data['duration']),
      _asString(data['duration_label']),
    ], fallback: '');
    if (explicit.isNotEmpty) {
      return explicit;
    }

    final hours = _asNum(data['duration_hours'] ?? data['hours_count']);
    if (hours != null && hours > 0) {
      return '${hours.round()} h';
    }

    final weeks = _asNum(data['duration_weeks']);
    if (weeks != null && weeks > 0) {
      return '${weeks.round()} semaine(s)';
    }

    return 'Duree non precisee';
  }

  String _formatTrainingCertification(Map<String, dynamic> data) {
    if (_asBool(data['certificate_available'] ?? data['has_certificate'])) {
      return 'Certificat disponible';
    }

    return _firstNonEmpty([
      _asString(data['certificate_label']),
      _asString(data['certification']),
    ], fallback: 'Certification non precisee');
  }

  String _formatTrainingDateLabel(
    dynamic value, {
    required String fallback,
  }) {
    final raw = _asString(value);
    if (raw == null || raw.isEmpty) {
      return fallback;
    }

    final date = DateTime.tryParse(raw);
    if (date == null) {
      return raw;
    }

    return DateFormat('dd/MM/yyyy').format(date.toLocal());
  }

  String _formatTrainingPrice(dynamic value) {
    final cost = _asNum(value);
    if (cost == null || cost <= 0) {
      return 'Gratuite';
    }

    return '${_formatMoney(cost)} XOF';
  }

  String _resolveTrainingProviderName(Map<String, dynamic>? provider) {
    final employerProfile = _asMap(provider?['employer_profile']);

    return _firstNonEmpty([
      _asString(employerProfile?['company_name']),
      _joinNames(
        _asString(provider?['first_name']),
        _asString(provider?['last_name']),
      ),
      _asString(provider?['email']),
    ], fallback: 'Organisme de formation');
  }

  String _joinNames(String? firstName, String? lastName) {
    final values = [
      if (firstName != null && firstName.trim().isNotEmpty) firstName.trim(),
      if (lastName != null && lastName.trim().isNotEmpty) lastName.trim(),
    ];

    return values.join(' ').trim();
  }

  String _friendlyErrorMessage(
    Object error, {
    required String fallback,
  }) {
    final message = error.toString();
    if (message.contains('Impossible de joindre l\'API')) {
      return 'Connexion au service impossible pour le moment.';
    }

    return message.replaceFirst('Exception: ', '').trim().isEmpty
        ? fallback
        : message.replaceFirst('Exception: ', '').trim();
  }

  String _extractApiMessage(
    Map<String, dynamic> data, {
    required String fallback,
  }) {
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }

    final errors = data['errors'];
    if (errors is Map<String, dynamic>) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }

    return fallback;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry('$key', val));
    }
    return null;
  }

  List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => _asString(item))
          .whereType<String>()
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }

  List<String> _asTextList(dynamic value) {
    if (value is List) {
      return _asStringList(value);
    }

    final raw = _asString(value);
    if (raw == null) {
      return const [];
    }

    return raw
        .split(RegExp(r'\r\n|\r|\n|;'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  String? _asString(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();
    return text.isEmpty || text == 'null' ? null : text;
  }

  int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(_asString(value) ?? '') ?? 0;
  }

  double _asDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(_asString(value) ?? '') ?? 0;
  }

  num? _asNum(dynamic value) {
    if (value is num) {
      return value;
    }
    return num.tryParse(_asString(value) ?? '');
  }

  bool _asBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }

    final text = (_asString(value) ?? '').toLowerCase();
    return text == '1' || text == 'true' || text == 'yes';
  }

  String _formatMoney(num value) {
    return _moneyFormat.format(value.round());
  }

  String _firstNonEmpty(
    Iterable<String?> values, {
    required String fallback,
  }) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return fallback;
  }

  void _seedMessagingState() {
    for (final conversation in conversations) {
      unreadCounters[conversation.id] = conversation.unreadCount;
      messageThreads[conversation.id] = <HomeChatMessage>[
        HomeChatMessage(
          text: conversation.preview,
          sentAt: DateTime.now().subtract(const Duration(minutes: 12)),
          isMine: false,
        ),
      ].obs;
    }
  }

  void _seedNotifications() {
    final now = DateTime.now();
    notifications.assignAll([
      HomeNotificationPreview(
        id: 'welcome',
        title: 'Profil candidat',
        body: 'Completez votre CV et votre portfolio pour etre visible.',
        category: 'Profil',
        createdAt: now.subtract(const Duration(minutes: 5)),
        icon: Icons.person_outline_rounded,
        isRead: false,
      ),
      HomeNotificationPreview(
        id: 'messages',
        title: 'Messages recruteurs',
        body: 'Vous avez des conversations a consulter.',
        category: 'Message',
        createdAt: now.subtract(const Duration(hours: 1)),
        icon: Icons.chat_bubble_outline_rounded,
        isRead: false,
      ),
      HomeNotificationPreview(
        id: 'portfolio',
        title: 'Portfolio',
        body: 'Les entreprises peuvent consulter les projets publics.',
        category: 'Portfolio',
        createdAt: now.subtract(const Duration(hours: 3)),
        icon: Icons.workspaces_outlined,
        isRead: true,
      ),
    ]);
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

  String _autoReplyForConversation(String conversationId) {
    switch (conversationId) {
      case 'samatech':
        return 'Merci pour votre retour. Nous revenons vers vous avec un horaire.';
      case 'talent_sahel':
        return 'Parfait, votre disponibilite est bien enregistree.';
      case 'opportune_team':
        return 'Nouvelle alerte: 3 offres correspondent a votre profil.';
      default:
        return 'Message recu. Nous vous repondrons rapidement.';
    }
  }
}
