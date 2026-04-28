part of '../home_controller.dart';

extension HomeControllerMessaging on HomeController {
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

  /// Charge la liste des notifications depuis le backend
  /// (`GET /api/v1/notifications`). Renseigne `notifications` avec ce qui
  /// existe vraiment cote serveur pour l'utilisateur courant.
  Future<void> loadNotifications() async {
    try {
      final token = await const AuthTokenStore().readToken();
      final response = await _apiProvider.getJson(
        ApiConstants.notifications,
        headers: ApiConstants.authHeadersWithoutContentType(token),
      );

      if (response['success'] != true) return;

      final data = response['data'];
      final items = data is Map ? data['items'] : null;
      if (items is! List) return;

      final parsed = items
          .whereType<Map>()
          .map((m) => _parseNotification(Map<String, dynamic>.from(m)))
          .whereType<HomeNotificationPreview>()
          .toList(growable: false);

      notifications.assignAll(parsed);
    } catch (_) {
      // Silent : la liste reste vide, l'UI affiche son empty state.
    }
  }

  /// Pull-to-refresh : recharge depuis le backend.
  Future<void> refreshNotifications() => loadNotifications();

  HomeNotificationPreview? _parseNotification(Map<String, dynamic> raw) {
    final id = raw['id']?.toString();
    if (id == null || id.isEmpty) return null;
    final type = (raw['type']?.toString() ?? '').toLowerCase();
    final createdAtRaw = raw['created_at']?.toString();
    final createdAt = createdAtRaw != null
        ? DateTime.tryParse(createdAtRaw) ?? DateTime.now()
        : DateTime.now();

    return HomeNotificationPreview(
      id: id,
      title: raw['title']?.toString() ?? '',
      body: raw['body']?.toString() ?? '',
      category: _categoryFromType(type),
      createdAt: createdAt,
      icon: _iconFromType(type),
      isRead: raw['is_read'] == true,
    );
  }

  /// Mappe le `type` backend (training, message, application, profile, ...)
  /// vers la categorie consommee par `_categoryPalette` cote ecran.
  String _categoryFromType(String type) {
    switch (type) {
      case 'training':
      case 'formation':
        return 'Formation';
      case 'message':
      case 'chat':
        return 'Message';
      case 'application':
      case 'offer':
      case 'job':
        return 'Offre';
      case 'profile':
        return 'Profil';
      case 'portfolio':
        return 'Portfolio';
      default:
        return type.isEmpty ? 'Notification' : type;
    }
  }

  IconData _iconFromType(String type) {
    switch (type) {
      case 'training':
      case 'formation':
        return Icons.school_outlined;
      case 'message':
      case 'chat':
        return Icons.chat_bubble_outline_rounded;
      case 'application':
      case 'offer':
      case 'job':
        return Icons.work_outline_rounded;
      case 'profile':
        return Icons.person_outline_rounded;
      case 'portfolio':
        return Icons.workspaces_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  /// Charge la liste des conversations depuis le backend Laravel
  /// (`GET /api/v1/messages`). Aucune donnee demo n'est injectee.
  Future<void> loadConversations() async {
    if (isLoadingConversations.value) return;
    isLoadingConversations.value = true;
    conversationsLoadError.value = '';
    try {
      final token = await const AuthTokenStore().readToken();
      final response = await _apiProvider.getJson(
        ApiConstants.conversations,
        headers: ApiConstants.authHeadersWithoutContentType(token),
      );

      if (response['success'] != true) {
        throw Exception(_extractApiMessage(
          response,
          fallback: 'Impossible de charger les conversations.',
        ));
      }

      final items = _extractConversationItems(response['data']);
      final parsed = items
          .map((raw) => _parseConversation(raw))
          .whereType<HomeConversationPreview>()
          .toList(growable: false);

      conversations.assignAll(parsed);
      // Synchronise les compteurs non-lus.
      unreadCounters.clear();
      for (final c in parsed) {
        unreadCounters[c.id] = c.unreadCount;
      }
    } on Exception catch (error) {
      conversationsLoadError.value = _friendlyErrorMessage(
        error,
        fallback: 'Impossible de charger les conversations.',
      );
    } finally {
      isLoadingConversations.value = false;
    }
  }

  /// Charge les messages d'une conversation et les place dans
  /// `messageThreads[conversationId]`. Marque la conversation comme lue.
  Future<void> loadConversationThread(String conversationId) async {
    try {
      final token = await const AuthTokenStore().readToken();
      final response = await _apiProvider.getJson(
        '${ApiConstants.conversations}/$conversationId',
        headers: ApiConstants.authHeadersWithoutContentType(token),
      );
      if (response['success'] != true) return;

      final raw = _extractConversationItems(response['data']);
      final messages = raw
          .map((m) => _parseChatMessage(m))
          .whereType<HomeChatMessage>()
          .toList(growable: false);
      threadFor(conversationId).assignAll(messages);
      // Marque comme lue cote backend.
      await _markConversationRead(conversationId, token);
      unreadCounters[conversationId] = 0;
    } on Exception {
      // Echec silencieux : le thread reste vide, l'utilisateur peut retry.
    }
  }

  Future<void> _markConversationRead(
    String conversationId,
    String token,
  ) async {
    try {
      await _apiProvider.postJson(
        '${ApiConstants.conversations}/$conversationId/read',
        const {},
        headers: ApiConstants.authHeaders(token),
      );
    } on Exception {
      // Idempotent : tant pis si ca echoue.
    }
  }

  void openConversation(HomeConversationPreview conversation) {
    activeConversationId.value = conversation.id;
    unreadCounters[conversation.id] = 0;
    loadConversationThread(conversation.id);
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

  /// Total des messages non lus toutes conversations confondues. Utilise
  /// pour le badge rouge sur l'icone Messages de la bottom nav.
  int get unreadMessagesTotal {
    if (unreadCounters.isEmpty) return 0;
    return unreadCounters.values.fold<int>(0, (acc, n) => acc + n);
  }

  int get unreadNotificationsCount =>
      notifications.where((notification) => !notification.isRead).length;

  /// Marque une notification comme lue : optimiste cote UI, push backend
  /// (`POST /notifications/{id}/read`). Rollback si le serveur refuse.
  Future<void> markNotificationAsRead(String notificationId) async {
    final index = notifications.indexWhere(
      (notification) => notification.id == notificationId,
    );
    if (index < 0 || notifications[index].isRead) {
      return;
    }
    final original = notifications[index];
    notifications[index] = original.copyWith(isRead: true);

    try {
      final token = await const AuthTokenStore().readToken();
      final response = await _apiProvider.postJson(
        '${ApiConstants.notifications}/$notificationId/read',
        const <String, dynamic>{},
        headers: ApiConstants.authHeaders(token),
      );
      if (response['success'] != true) {
        notifications[index] = original;
      }
    } catch (_) {
      notifications[index] = original;
    }
  }

  /// Marque toutes les notifications comme lues
  /// (`POST /notifications/read-all`).
  Future<void> markAllNotificationsAsRead() async {
    final snapshot = notifications.toList(growable: false);
    notifications.assignAll(
      snapshot.map((n) => n.copyWith(isRead: true)).toList(growable: false),
    );

    try {
      final token = await const AuthTokenStore().readToken();
      final response = await _apiProvider.postJson(
        '${ApiConstants.notifications}/read-all',
        const <String, dynamic>{},
        headers: ApiConstants.authHeaders(token),
      );
      if (response['success'] != true) {
        notifications.assignAll(snapshot);
      }
    } catch (_) {
      notifications.assignAll(snapshot);
    }
  }

  /// Envoi reel d'un message via `POST /api/v1/messages/{id}/send`.
  /// Le candidat ne peut repondre que si une conversation existe deja
  /// (le recruteur doit l'initier — regle backend `authorizeConversation`).
  Future<void> sendActiveMessage() async {
    final conversationId = activeConversationId.value;
    final text = chatInputCtrl.text.trim();
    if (conversationId == null || text.isEmpty || isSendingChat.value) {
      return;
    }

    isSendingChat.value = true;
    final tempMessage = HomeChatMessage(
      text: text,
      sentAt: DateTime.now(),
      isMine: true,
    );
    threadFor(conversationId).add(tempMessage);
    chatInputCtrl.clear();

    try {
      final token = await const AuthTokenStore().readToken();
      final response = await _apiProvider.postJson(
        '${ApiConstants.conversations}/$conversationId/send',
        {'content': text},
        headers: ApiConstants.authHeaders(token),
      );

      if (response['success'] != true) {
        throw Exception(_extractApiMessage(
          response,
          fallback: 'Echec de l\'envoi du message.',
        ));
      }
    } on Exception catch (error) {
      // Rollback : retire le message en cas d'echec et previent l'utilisateur.
      threadFor(conversationId).remove(tempMessage);
      Get.snackbar(
        'Messagerie',
        _friendlyErrorMessage(
          error,
          fallback: 'Le message n\'a pas pu etre envoye.',
        ),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSendingChat.value = false;
    }
  }

  // -------------- Parsing helpers --------------

  List<dynamic> _extractConversationItems(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is List) return inner;
      final messages = data['messages'];
      if (messages is List) return messages;
    }
    return const [];
  }

  HomeConversationPreview? _parseConversation(dynamic raw) {
    final data = _asMap(raw);
    if (data == null) return null;
    final id = _asString(data['id']);
    if (id == null || id.isEmpty) return null;

    // Le titre vient de l'employer (cote candidat parle a un employeur).
    final employer = _asMap(data['employer']);
    final candidate = _asMap(data['candidate']);
    final candidateUser = candidate != null ? _asMap(candidate['user']) : null;

    String title = _firstNonEmpty([
      _asString(employer?['company_name']),
      _asString(employer?['name']),
    ], fallback: '');
    if (title.isEmpty && candidateUser != null) {
      final first = (candidateUser['first_name'] ?? '').toString().trim();
      final last = (candidateUser['last_name'] ?? '').toString().trim();
      final full = '$first $last'.trim();
      if (full.isNotEmpty) title = full;
    }
    if (title.isEmpty) title = 'Conversation';

    final latest = _asMap(data['latestMessage'] ?? data['latest_message']);
    final preview = _firstNonEmpty([
      _asString(latest?['content']),
      _asString(data['last_message']),
    ], fallback: 'Pas encore de message');

    final lastTimeRaw =
        data['last_message_at'] ?? latest?['sent_at'] ?? data['updated_at'];
    final lastTime = _parseDate(lastTimeRaw);

    final unread = _asInt(
      data['unread_candidate'] ?? data['unread_count'] ?? data['unread'] ?? 0,
    );

    return HomeConversationPreview(
      id: id,
      title: title,
      preview: preview,
      timeLabel: _formatConversationTime(lastTime),
      unreadCount: unread,
      online: _asBool(data['is_online'] ?? data['online']),
    );
  }

  HomeChatMessage? _parseChatMessage(dynamic raw) {
    final data = _asMap(raw);
    if (data == null) return null;
    final text = _firstNonEmpty([
      _asString(data['content']),
      _asString(data['text']),
      _asString(data['message']),
    ], fallback: '');
    if (text.isEmpty) return null;
    final sentAt = _parseDate(data['sent_at'] ?? data['created_at']);
    final senderId = _asString(data['sender_id']);
    final candidateProfileId = _asString(data['candidate_profile_id']);
    // Heuristique : un message dont sender_id == user.id du candidat est "mien".
    // A defaut on regarde si le flag is_mine est expose.
    final isMine = _asBool(data['is_mine']) ||
        (senderId != null &&
            candidateProfileId != null &&
            senderId == candidateProfileId);
    return HomeChatMessage(
      text: text,
      sentAt: sentAt ?? DateTime.now(),
      isMine: isMine,
    );
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  String _formatConversationTime(DateTime? d) {
    if (d == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dDay = DateTime(d.year, d.month, d.day);
    if (dDay == today) {
      return '${d.hour.toString().padLeft(2, '0')}:'
          '${d.minute.toString().padLeft(2, '0')}';
    }
    final yesterday = today.subtract(const Duration(days: 1));
    if (dDay == yesterday) return 'Hier';
    final diff = today.difference(dDay).inDays;
    if (diff < 7) {
      const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return days[d.weekday - 1];
    }
    return '${d.day}/${d.month}';
  }
}
