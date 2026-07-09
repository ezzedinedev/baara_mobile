import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:opportune_bf/app/core/services/location_service.dart';
import 'package:opportune_bf/app/core/services/realtime_events.dart';
import 'package:opportune_bf/app/core/utils/user_facing_error.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/i_messaging_repository.dart';

class MessagesController extends GetxController {
  final IMessagingRepository _repository;
  MessagesController(this._repository);

  static const int _convPerPage = 20;

  final conversations = <Conversation>[].obs;
  final activeMessages = <Message>[].obs;

  final searchQuery = ''.obs;
  // Persistant ici (plus dans build()) : la saisie de recherche survit aux
  // rebuilds de la liste.
  final searchCtrl = TextEditingController();

  List<Conversation> get filteredConversations {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return conversations;
    return conversations
        .where((c) =>
            c.title.toLowerCase().contains(q) ||
            c.lastMessage.toLowerCase().contains(q))
        .toList();
  }

  final isLoadingConversations = false.obs;
  final isLoadingMoreConversations = false.obs;
  final hasMoreConversations = false.obs;
  final isLoadingMessages = false.obs;
  final isSending = false.obs;
  final showVoiceRecorder = false.obs;
  final activeConversationId = RxnString();
  int _convPage = 1;

  // ── Temps réel (Cluster B) ─────────────────────────────────────────────────
  /// L'interlocuteur est en train d'écrire.
  final peerTyping = false.obs;

  /// Présence en ligne de l'interlocuteur (depuis la conversation).
  final peerOnline = false.obs;

  /// Dernière activité connue de l'interlocuteur (pour « Vu il y a … »).
  final peerLastSeen = Rxn<DateTime>();

  /// Accusé de lecture du pair au chargement (état initial des ✓✓).
  final peerLastReadAt = Rxn<DateTime>();

  Timer? _peerTypingExpiry; // auto-expire l'indicateur "typing" reçu.
  Timer? _typingStopTimer; // arrête mon "typing" après inactivité.
  DateTime? _lastTypingPingAt; // throttle des pings "typing:true".
  bool _myTyping = false; // mon dernier état envoyé.

  StreamSubscription<RealtimeEvent>? _realtimeSub;

  @override
  void onInit() {
    super.onInit();
    loadConversations();

    final id = Get.parameters['id'];
    if (id != null) {
      loadMessages(id);
    }

    if (Get.isRegistered<RealtimeEventBus>()) {
      _realtimeSub =
          Get.find<RealtimeEventBus>().stream.listen(_handleRealtimeEvent);
    }
  }

  void _handleRealtimeEvent(RealtimeEvent event) {
    switch (event) {
      case RealtimeMessageSent(:final conversationId, :final message):
        loadConversations();
        if (conversationId != null &&
            activeConversationId.value == conversationId) {
          if (message != null) {
            final exists = activeMessages.any((m) => m.id == message.id);
            if (!exists) {
              activeMessages.add(message);
              maybeLoadSmartReplies();
            }
          } else {
            loadMessages(conversationId);
          }
        }
      case RealtimeTyping(
          :final conversationId,
          :final userId,
          :final typing,
        ):
        onPeerTyping(conversationId, userId, typing);
      case RealtimeMessagesRead(:final conversationId, :final readAt):
        onMessagesRead(conversationId, readAt);
      case RealtimeMessageReaction(
          :final messageId,
          :final userId,
          :final emoji,
          :final removed,
        ):
        onMessageReaction(messageId, userId, emoji, removed);
      case RealtimeNotificationCreated():
        loadConversations();
      case RealtimeStoryCreated():
        break;
    }
  }

  // ── Wave 2 — Réponses suggérées (IA) ───────────────────────────────────────
  /// Suggestions de réponse pour la conversation active (3 max).
  final smartReplies = <String>[].obs;
  final isLoadingSmartReplies = false.obs;
  // Évite de recharger en boucle pour le même dernier message.
  String? _smartRepliesForMessageId;

  /// Pertinent : dernier message reçu (pas le mien) et non encore répondu.
  bool get _shouldSuggestReplies {
    if (activeMessages.isEmpty) return false;
    return !activeMessages.last.isMine;
  }

  /// Charge les réponses suggérées si c'est pertinent. [force] ignore le cache.
  Future<void> maybeLoadSmartReplies({bool force = false}) async {
    final convId = activeConversationId.value;
    if (convId == null || !_shouldSuggestReplies) {
      smartReplies.clear();
      return;
    }
    final lastId = activeMessages.last.id;
    if (!force && lastId == _smartRepliesForMessageId) return;
    _smartRepliesForMessageId = lastId;
    try {
      isLoadingSmartReplies.value = true;
      final result = await _repository.smartReplies(convId);
      // `fallback` est géré silencieusement : on affiche quand même.
      smartReplies.assignAll(result.suggestions.take(3));
    } catch (e) {
      // Indispo IA (502) : pas de bruit, on masque simplement les chips.
      if (kDebugMode) debugPrint('[Messages] smartReplies error: $e');
      smartReplies.clear();
    } finally {
      isLoadingSmartReplies.value = false;
    }
  }

  /// Masque les suggestions (ex. pendant la frappe / après usage).
  void dismissSmartReplies() => smartReplies.clear();

  @override
  void onClose() {
    _realtimeSub?.cancel();
    searchCtrl.dispose();
    _peerTypingExpiry?.cancel();
    _typingStopTimer?.cancel();
    super.onClose();
  }

  /// Démarre (ou rouvre) une conversation directe avec [userId] et la place en
  /// tête de liste. Retourne la conversation (à utiliser pour naviguer vers le
  /// fil), ou null en cas d'échec (bloqué, soi-même, réseau…).
  Future<Conversation?> startConversationWith(String userId) async {
    try {
      final conv = await _repository.startConversation(userId);
      conversations.removeWhere((c) => c.id == conv.id);
      conversations.insert(0, conv);
      return conv;
    } catch (e) {
      if (kDebugMode) debugPrint('[Messages] startConversation error: $e');
      AppToast.error('Messagerie', userFacingError(e));
      return null;
    }
  }

  /// Accepte une demande de message (met à jour la conversation en liste).
  Future<void> acceptRequest(String conversationId) async {
    try {
      final conv = await _repository.acceptConversation(conversationId);
      final i = conversations.indexWhere((c) => c.id == conv.id);
      if (i >= 0) {
        conversations[i] = conv;
      } else {
        conversations.insert(0, conv);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Messages] acceptRequest error: $e');
      AppToast.error('Messagerie', userFacingError(e));
    }
  }

  /// Refuse une demande de message : retrait optimiste + rollback si échec.
  Future<void> declineRequest(String conversationId) async {
    final snapshot = List<Conversation>.from(conversations);
    conversations.removeWhere((c) => c.id == conversationId);
    if (activeConversationId.value == conversationId) {
      activeConversationId.value = null;
      activeMessages.clear();
    }
    try {
      await _repository.declineConversation(conversationId);
    } catch (e) {
      if (kDebugMode) debugPrint('[Messages] declineRequest error: $e');
      conversations.assignAll(snapshot);
      AppToast.error('Messagerie', userFacingError(e));
    }
  }

  Future<void> loadConversations() async {
    try {
      isLoadingConversations.value = true;
      _convPage = 1;
      final result =
          await _repository.getConversations(page: 1, perPage: _convPerPage);
      conversations.assignAll(result);
      hasMoreConversations.value = result.length >= _convPerPage;
    } catch (e) {
      if (kDebugMode) debugPrint('[Messages] loadConversations error: $e');
    } finally {
      isLoadingConversations.value = false;
    }
  }

  Future<void> loadMoreConversations() async {
    if (isLoadingMoreConversations.value ||
        isLoadingConversations.value ||
        !hasMoreConversations.value) {
      return;
    }
    try {
      isLoadingMoreConversations.value = true;
      final result = await _repository.getConversations(
        page: _convPage + 1,
        perPage: _convPerPage,
      );
      _convPage += 1;
      conversations.addAll(result);
      hasMoreConversations.value = result.length >= _convPerPage;
    } catch (e) {
      if (kDebugMode) debugPrint('[Messages] loadMoreConversations error: $e');
    } finally {
      isLoadingMoreConversations.value = false;
    }
  }

  Future<void> loadMessages(String conversationId) async {
    try {
      isLoadingMessages.value = true;
      activeConversationId.value = conversationId;
      // Réinitialise l'état temps réel de la conversation précédente.
      peerTyping.value = false;
      _peerTypingExpiry?.cancel();
      final page = await _repository.getMessages(conversationId);
      activeMessages.assignAll(page.messages);
      peerLastReadAt.value = page.peerLastReadAt;
      _syncPeerPresence(conversationId);
      _smartRepliesForMessageId = null;
      maybeLoadSmartReplies();
      await _repository.markAsRead(conversationId);
    } catch (e) {
      if (kDebugMode) debugPrint('[Messages] loadMessages error: $e');
    } finally {
      isLoadingMessages.value = false;
    }
  }

  /// Recopie la présence de l'interlocuteur depuis la conversation chargée.
  void _syncPeerPresence(String conversationId) {
    final conv = conversations.firstWhereOrNull((c) => c.id == conversationId);
    if (conv != null) {
      peerOnline.value = conv.isOnline;
      peerLastSeen.value = conv.lastSeenAt;
    }
  }

  Future<void> sendMessage(String text) async {
    final convId = activeConversationId.value;
    if (convId == null || text.trim().isEmpty) return;

    try {
      isSending.value = true;
      _stopTyping(); // l'envoi vaut arrêt de saisie.
      dismissSmartReplies(); // j'ai répondu : plus de suggestions.
      final msg = await _repository.sendMessage(convId, text);
      activeMessages.add(msg);
    } catch (e) {
      if (kDebugMode) debugPrint('[Messages] sendMessage error: $e');
      AppToast.error('Erreur', "Le message n'a pas pu être envoyé.");
    } finally {
      isSending.value = false;
    }
  }

  // ── Indicateur de saisie (typing) débouncé ─────────────────────────────────
  /// Appelé à chaque frappe dans le composer. Ping `typing:true` au plus
  /// 1 fois / 3 s, et programme un `typing:false` après 3 s d'inactivité.
  void onComposerChanged(String text) {
    final convId = activeConversationId.value;
    if (convId == null) return;
    if (text.trim().isEmpty) {
      _stopTyping();
      // Champ vidé : reproposer des suggestions si pertinent.
      maybeLoadSmartReplies();
      return;
    }
    // Pendant la frappe, on masque les suggestions (sans les recharger ensuite).
    if (smartReplies.isNotEmpty) smartReplies.clear();
    final now = DateTime.now();
    final shouldPing = !_myTyping ||
        _lastTypingPingAt == null ||
        now.difference(_lastTypingPingAt!) >= const Duration(seconds: 3);
    if (shouldPing) {
      _myTyping = true;
      _lastTypingPingAt = now;
      _pingTyping(convId, true);
    }
    // Replanifie l'arrêt automatique après 3 s sans nouvelle frappe.
    _typingStopTimer?.cancel();
    _typingStopTimer = Timer(const Duration(seconds: 3), _stopTyping);
  }

  void _stopTyping() {
    _typingStopTimer?.cancel();
    final convId = activeConversationId.value;
    if (_myTyping && convId != null) {
      _pingTyping(convId, false);
    }
    _myTyping = false;
    _lastTypingPingAt = null;
  }

  Future<void> _pingTyping(String convId, bool typing) async {
    try {
      await _repository.sendTyping(convId, typing);
    } catch (e) {
      // Silencieux : le typing ne doit jamais bloquer l'UX.
      if (kDebugMode) debugPrint('[Messages] typing ping error: $e');
    }
  }

  // ── Réactions (optimiste + rollback) ───────────────────────────────────────
  Future<void> reactToMessage(String messageId, String emoji) async {
    final index = activeMessages.indexWhere((m) => m.id == messageId);
    if (index < 0) return;
    final original = activeMessages[index];

    // Calcul optimiste : on retire l'ancienne réaction et applique la nouvelle.
    final removed = original.myEmoji == emoji;
    final optimistic = _applyReaction(
      original,
      previousEmoji: original.myEmoji,
      newEmoji: removed ? null : emoji,
    );
    activeMessages[index] = optimistic;

    try {
      final result = await _repository.reactToMessage(messageId, emoji);
      // Réaligne sur la vérité serveur (my_emoji) si elle diffère.
      final idx = activeMessages.indexWhere((m) => m.id == messageId);
      if (idx >= 0 && result.myEmoji != optimistic.myEmoji) {
        activeMessages[idx] = _applyReaction(
          original,
          previousEmoji: original.myEmoji,
          newEmoji: result.myEmoji,
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Messages] reactToMessage error: $e');
      final idx = activeMessages.indexWhere((m) => m.id == messageId);
      if (idx >= 0) activeMessages[idx] = original; // rollback
      AppToast.error('Réaction', userFacingError(e));
    }
  }

  /// Recalcule `reactionsSummary`/`myEmoji` pour un changement de MA réaction.
  Message _applyReaction(
    Message msg, {
    required String? previousEmoji,
    required String? newEmoji,
  }) {
    final summary = Map<String, int>.from(msg.reactionsSummary);
    if (previousEmoji != null) {
      final c = (summary[previousEmoji] ?? 1) - 1;
      if (c > 0) {
        summary[previousEmoji] = c;
      } else {
        summary.remove(previousEmoji);
      }
    }
    if (newEmoji != null) {
      summary[newEmoji] = (summary[newEmoji] ?? 0) + 1;
    }
    return msg.copyWith(
      reactionsSummary: summary,
      myEmoji: newEmoji,
      clearMyEmoji: newEmoji == null,
    );
  }

  // ── Application des events temps réel (appelés par RealtimeService) ─────────
  /// L'interlocuteur tape (ou s'arrête). Auto-expire après 5 s.
  void onPeerTyping(String conversationId, String userId, bool typing) {
    if (conversationId != activeConversationId.value) return;
    peerTyping.value = typing;
    _peerTypingExpiry?.cancel();
    if (typing) {
      _peerTypingExpiry = Timer(
        const Duration(seconds: 5),
        () => peerTyping.value = false,
      );
    }
  }

  /// Le pair a lu jusqu'à [readAt] : marque MES messages antérieurs comme lus.
  void onMessagesRead(String conversationId, DateTime readAt) {
    if (conversationId != activeConversationId.value) return;
    if (peerLastReadAt.value == null || readAt.isAfter(peerLastReadAt.value!)) {
      peerLastReadAt.value = readAt;
    }
    for (var i = 0; i < activeMessages.length; i++) {
      final m = activeMessages[i];
      if (m.isMine && !m.isRead && !m.sentAt.isAfter(readAt)) {
        activeMessages[i] = m.copyWith(readAt: readAt);
      }
    }
  }

  /// Réaction reçue en temps réel sur un message (ajout/retrait).
  void onMessageReaction(
    String messageId,
    String userId,
    String emoji,
    bool removed,
  ) {
    final index = activeMessages.indexWhere((m) => m.id == messageId);
    if (index < 0) return;
    final msg = activeMessages[index];
    final summary = Map<String, int>.from(msg.reactionsSummary);
    if (removed) {
      final c = (summary[emoji] ?? 1) - 1;
      if (c > 0) {
        summary[emoji] = c;
      } else {
        summary.remove(emoji);
      }
    } else {
      summary[emoji] = (summary[emoji] ?? 0) + 1;
    }
    activeMessages[index] = msg.copyWith(reactionsSummary: summary);
  }

  Future<void> sendImageMessage(String imagePath) async {
    final convId = activeConversationId.value;
    if (convId == null) return;
    try {
      isSending.value = true;
      final msg = await _repository.sendMediaMessage(
        convId,
        'image',
        filePath: imagePath,
      );
      activeMessages.add(msg);
    } catch (e) {
      if (kDebugMode) debugPrint('[Messages] sendImageMessage error: $e');
      AppToast.error('Message non envoyé', userFacingError(e));
    } finally {
      isSending.value = false;
    }
  }

  Future<void> sendFileMessage(String filePath, String fileName) async {
    final convId = activeConversationId.value;
    if (convId == null) return;
    try {
      isSending.value = true;
      final msg = await _repository.sendMediaMessage(
        convId,
        'file',
        filePath: filePath,
        text: fileName,
      );
      activeMessages.add(msg);
    } catch (e) {
      if (kDebugMode) debugPrint('[Messages] sendFileMessage error: $e');
      AppToast.error('Message non envoyé', userFacingError(e));
    } finally {
      isSending.value = false;
    }
  }

  Future<void> sendVoiceMessage(String voicePath) async {
    final convId = activeConversationId.value;
    if (convId == null) return;
    try {
      isSending.value = true;
      final msg = await _repository.sendMediaMessage(
        convId,
        'voice',
        filePath: voicePath,
      );
      activeMessages.add(msg);
    } catch (e) {
      if (kDebugMode) debugPrint('[Messages] sendVoiceMessage error: $e');
      AppToast.error('Message non envoyé', userFacingError(e));
    } finally {
      isSending.value = false;
    }
  }

  Future<void> sendLocationMessage(
      double lat, double lng, String address) async {
    final convId = activeConversationId.value;
    if (convId == null) return;
    final locationJson =
        jsonEncode({'lat': lat, 'lng': lng, 'address': address});
    try {
      isSending.value = true;
      final msg = await _repository.sendMediaMessage(
        convId,
        'location',
        text: locationJson,
      );
      activeMessages.add(msg);
    } catch (e) {
      if (kDebugMode) debugPrint('[Messages] sendLocationMessage error: $e');
      AppToast.error('Message non envoyé', userFacingError(e));
    } finally {
      isSending.value = false;
    }
  }

  Future<void> pickAndSendImage() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      AppToast.error(
          'Permission', 'Autorisez l\'accès à la caméra dans les réglages.');
      return;
    }
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (file != null) {
      await sendImageMessage(file.path);
    }
  }

  Future<void> pickAndSendGalleryImage() async {
    final status = await Permission.photos.request();
    if (!status.isGranted && !status.isLimited) {
      AppToast.error(
          'Permission', 'Autorisez l\'accès à la galerie dans les réglages.');
      return;
    }
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) {
      await sendImageMessage(file.path);
    }
  }

  Future<void> pickAndSendFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'ppt',
        'pptx',
        'txt',
        'zip',
        'rar'
      ],
    );
    if (result != null && result.files.single.path != null) {
      final file = result.files.single;
      await sendFileMessage(file.path!, file.name);
    }
  }

  Future<void> sendCurrentLocation() async {
    final result = await const LocationService().getCurrentLocation();
    if (!result.ok) {
      AppToast.error('Localisation', _locationErrorMessage(result.failure!));
      return;
    }
    final pos = result.position!;
    final address = result.address ??
        '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
    await sendLocationMessage(pos.latitude, pos.longitude, address);
  }

  String _locationErrorMessage(LocationFailure failure) {
    switch (failure) {
      case LocationFailure.serviceDisabled:
        return 'Activez la localisation (GPS) de votre téléphone.';
      case LocationFailure.permissionDenied:
        return 'Autorisez l\'accès à la localisation pour partager votre position.';
      case LocationFailure.permissionDeniedForever:
        return 'Localisation bloquée. Activez-la dans les réglages de l\'app.';
      case LocationFailure.timeout:
        return 'Position non obtenue à temps. Réessayez en extérieur.';
      case LocationFailure.unknown:
        return 'Impossible d\'obtenir la position.';
    }
  }
}
