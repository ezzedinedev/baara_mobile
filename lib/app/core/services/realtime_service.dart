import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/api_constants.dart';
import '../network/api_provider.dart';
import 'auth_token_store.dart';
import '../../features/messaging/domain/entities/message.dart';
import '../../features/messaging/presentation/controllers/messages_controller.dart';
import '../../features/notifications/presentation/controllers/notifications_controller.dart';
import '../../features/community/presentation/controllers/story_controller.dart';

/// Temps réel via Laravel Reverb — client pur-Dart du protocole Pusher
/// (sur [WebSocketChannel]).
class RealtimeService extends GetxService {
  RealtimeService({ApiProvider? apiProvider, AuthTokenStore? tokenStore})
      : _apiProvider = apiProvider ?? Get.find<ApiProvider>(),
        _tokenStore = tokenStore ?? const AuthTokenStore();

  final ApiProvider _apiProvider;
  final AuthTokenStore _tokenStore;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  bool _started = false; // intention de rester connecté (gère la reconnexion)
  String? _token;
  String? _userId;
  String? _socketId;
  int _reconnectAttempts = 0;

  final Set<String> _channels = <String>{}; // canaux à (ré)abonner
  String? _conversationChannel;

  bool get isConnected => _socketId != null;

  /// Démarre le temps réel si une session existe. Idempotent.
  Future<void> start() async {
    if (_started) return;
    final token = await _tokenStore.readTokenOrNull();
    if (token == null || token.isEmpty) return; // pas connecté → no-op
    _token = token;
    _userId = await _fetchUserId(token);
    if (_userId == null) return;
    _started = true;
    _channels.add('private-App.Models.User.$_userId');
    _connect();
  }

  /// Abonne le canal de la conversation active (messages live), en se
  /// désabonnant de la précédente. `null` → se désabonne simplement.
  void setActiveConversation(String? conversationId) {
    final next =
        conversationId == null ? null : 'private-conversation.$conversationId';
    if (next == _conversationChannel) return;
    if (_conversationChannel != null) {
      _channels.remove(_conversationChannel);
      _send({
        'event': 'pusher:unsubscribe',
        'data': {'channel': _conversationChannel},
      });
    }
    _conversationChannel = next;
    if (next != null) {
      _channels.add(next);
      _subscribe(next);
    }
  }

  /// Coupe la connexion (à appeler au logout).
  Future<void> stop() async {
    _started = false;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _storyReloadDebounce?.cancel();
    await _sub?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _sub = null;
    _socketId = null;
    _channels.clear();
    _conversationChannel = null;
  }

  // ── Connexion WebSocket ──────────────────────────────────────────────────
  Future<void> _connect() async {
    if (!_started) return;
    final scheme = ApiConstants.reverbUseTls ? 'wss' : 'ws';
    final url =
        '$scheme://${ApiConstants.reverbHost}:${ApiConstants.reverbPort}'
        '/app/${ApiConstants.reverbAppKey}'
        '?protocol=7&client=opportune-flutter&version=1.0.0&flash=false';
    try {
      final channel = WebSocketChannel.connect(Uri.parse(url));
      // IMPORTANT : on attend `ready` pour capter l'échec de connexion ICI.
      // Sinon l'exception (serveur Reverb hors-ligne sur l'émulateur) remonte
      // au runZonedGuarded de main.dart et pollue Crashlytics à chaque essai.
      await channel.ready;
      if (!_started) {
        await channel.sink.close();
        return;
      }
      _channel = channel;
      _sub = channel.stream.listen(
        _onFrame,
        onError: (Object e) => _scheduleReconnect('stream error: $e'),
        onDone: () => _scheduleReconnect('socket closed'),
        cancelOnError: true,
      );
    } catch (e) {
      // Échec attendu si Reverb n'est pas démarré : reconnexion silencieuse
      // (backoff), pas de remontée Crashlytics.
      _scheduleReconnect('connect failed: $e');
    }
  }

  void _scheduleReconnect(String reason) {
    _debug('reconnect ($reason)');
    _socketId = null;
    _pingTimer?.cancel();
    _sub?.cancel();
    _channel = null;
    if (!_started) return;
    _reconnectTimer?.cancel();
    // Backoff exponentiel plafonné (1s → 2s → 4s … max 30s).
    final delay = Duration(
      seconds: (1 << _reconnectAttempts.clamp(0, 5)).clamp(1, 30),
    );
    _reconnectAttempts++;
    _reconnectTimer = Timer(delay, _connect);
  }

  void _onFrame(dynamic raw) {
    final frame = _decode(raw);
    if (frame == null) return;
    final event = frame['event']?.toString();
    switch (event) {
      case 'pusher:connection_established':
        _onConnected(frame['data']);
        break;
      case 'pusher:ping':
        _send({'event': 'pusher:pong', 'data': {}});
        break;
      case 'pusher:error':
        _debug('pusher error: ${frame['data']}');
        break;
      case 'message.sent':
        _handleMessageEvent(frame['data']);
        break;
      case 'typing':
        _handleTypingEvent(frame['data']);
        break;
      case 'messages.read':
        _handleMessagesReadEvent(frame['data']);
        break;
      case 'message.reaction':
        _handleReactionEvent(frame['data']);
        break;
      case 'notification.created':
        _handleNotificationEvent();
        break;
      case 'story.created':
        _handleStoryEvent();
        break;
    }
  }

  void _onConnected(dynamic data) {
    final payload = _decode(data);
    _socketId = payload?['socket_id']?.toString();
    _reconnectAttempts = 0;
    _debug('connected, socket_id=$_socketId');
    // (Ré)abonne tous les canaux mémorisés.
    for (final ch in _channels) {
      _subscribe(ch);
    }
    // Ping applicatif régulier pour garder la connexion vivante (NAT/proxy).
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _send({'event': 'pusher:ping', 'data': {}}),
    );
  }

  // ── Abonnement aux canaux privés (auth Sanctum) ──────────────────────────
  Future<void> _subscribe(String channel) async {
    final socketId = _socketId;
    if (socketId == null) return; // sera abonné à la (re)connexion
    final auth = await _authorize(channel, socketId);
    if (auth == null) return;
    _send({
      'event': 'pusher:subscribe',
      'data': {'auth': auth, 'channel': channel},
    });
  }

  Future<String?> _authorize(String channel, String socketId) async {
    final token = _token;
    if (token == null) return null;
    try {
      final res = await http.post(
        Uri.parse(ApiConstants.broadcastingAuthUrl),
        headers: ApiConstants.authHeaders(token),
        body: jsonEncode({'socket_id': socketId, 'channel_name': channel}),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map && body['auth'] is String) {
          return body['auth'] as String;
        }
      } else {
        _debug('authorize HTTP ${res.statusCode} for $channel');
      }
    } catch (e) {
      _debug('authorize failed: $e');
    }
    return null;
  }

  void _send(Map<String, dynamic> message) {
    try {
      _channel?.sink.add(jsonEncode(message));
    } catch (e) {
      _debug('send failed: $e');
    }
  }

  // ── Events → rechargement via controllers existants ──────────────────────
  void _handleMessageEvent(dynamic raw) {
    final data = _decode(raw);
    final convId = data?['conversation_id']?.toString();
    _withMessages((ctrl) {
      ctrl.loadConversations();
      if (convId != null && ctrl.activeConversationId.value == convId) {
        // Incrémental : parse le payload broadcast et ajoute localement.
        // Fallback : reload REST complet si le parsing échoue.
        final msg = _parseMessageFromBroadcast(data);
        if (msg != null) {
          final exists = ctrl.activeMessages.any((m) => m.id == msg.id);
          if (!exists) {
            ctrl.activeMessages.add(msg);
            // Nouveau message reçu : propose des réponses suggérées (IA).
            ctrl.maybeLoadSmartReplies();
          }
        } else {
          ctrl.loadMessages(convId);
        }
      }
    });
  }

  Message? _parseMessageFromBroadcast(Map<String, dynamic>? data) {
    if (data == null) return null;
    try {
      final sender = data['sender'] as Map<String, dynamic>?;
      final firstName = sender?['first_name'] as String? ?? '';
      final lastName = sender?['last_name'] as String? ?? '';
      return Message(
        id: data['id']?.toString() ?? '',
        text: data['content']?.toString() ?? '',
        sentAt: DateTime.tryParse(data['sent_at']?.toString() ?? '') ??
            DateTime.now(),
        isMine: _userId != null && data['sender_id']?.toString() == _userId,
        senderName: '$firstName $lastName'.trim(),
        messageType: data['message_type']?.toString() ?? 'text',
        attachmentUrl:
            ApiConstants.resolveMediaUrl(data['attachment_url']?.toString()),
        fileName: data['file_name']?.toString(),
        fileSize: int.tryParse(data['file_size']?.toString() ?? ''),
        replyToStoryId: data['reply_to_story_id']?.toString(),
        storySnapshot: data['story_snapshot'] is Map
            ? StorySnapshot(
                type: (data['story_snapshot']['type'] ?? 'text').toString(),
                url: ApiConstants.resolveMediaUrl(
                    data['story_snapshot']['url']?.toString()),
                caption: data['story_snapshot']['caption']?.toString(),
                backgroundColor:
                    data['story_snapshot']['background_color']?.toString(),
              )
            : null,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Temps réel messagerie (Cluster B) ────────────────────────────────────
  void _handleTypingEvent(dynamic raw) {
    final data = _decode(raw);
    if (data == null) return;
    final userId = data['user_id']?.toString();
    if (userId != null && userId == _userId) return; // mon propre event
    final convId = data['conversation_id']?.toString();
    if (convId == null) return;
    final typing = data['typing'] == true;
    _withMessages((ctrl) => ctrl.onPeerTyping(convId, userId ?? '', typing));
  }

  void _handleMessagesReadEvent(dynamic raw) {
    final data = _decode(raw);
    if (data == null) return;
    final readerId = data['reader_id']?.toString();
    if (readerId != null && readerId == _userId) return; // ma propre lecture
    final convId = data['conversation_id']?.toString();
    final readAt = DateTime.tryParse(data['read_at']?.toString() ?? '');
    if (convId == null || readAt == null) return;
    _withMessages((ctrl) => ctrl.onMessagesRead(convId, readAt));
  }

  void _handleReactionEvent(dynamic raw) {
    final data = _decode(raw);
    if (data == null) return;
    final userId = data['user_id']?.toString();
    // Ma réaction est déjà appliquée en optimiste côté controller.
    if (userId != null && userId == _userId) return;
    final messageId = data['message_id']?.toString();
    final emoji = data['emoji']?.toString();
    if (messageId == null || emoji == null) return;
    final removed = data['removed'] == true;
    _withMessages(
      (ctrl) => ctrl.onMessageReaction(messageId, userId ?? '', emoji, removed),
    );
  }

  Timer? _storyReloadDebounce;

  void _handleStoryEvent() {
    // Plusieurs stories peuvent arriver en rafale : on regroupe les
    // rechargements (un seul appel feed après le calme) pour ne pas marteler
    // le backend ni reconstruire la barre à chaque event.
    if (!Get.isRegistered<StoryController>()) return;
    _storyReloadDebounce?.cancel();
    _storyReloadDebounce = Timer(const Duration(seconds: 2), () {
      if (Get.isRegistered<StoryController>()) {
        Get.find<StoryController>().loadStories();
      }
    });
  }

  void _handleNotificationEvent() {
    _withNotifications((ctrl) => ctrl.fetchNotifications());
    // Une notif new_message met l'inbox à jour même si l'utilisateur a coupé
    // un canal de notif : on rafraîchit aussi la liste des conversations.
    _withMessages((ctrl) => ctrl.loadConversations());
  }

  void _withMessages(void Function(MessagesController) action) {
    if (Get.isRegistered<MessagesController>()) {
      action(Get.find<MessagesController>());
    }
  }

  void _withNotifications(void Function(NotificationsController) action) {
    if (Get.isRegistered<NotificationsController>()) {
      action(Get.find<NotificationsController>());
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  Future<String?> _fetchUserId(String token) async {
    try {
      final res = await _apiProvider.getJson(
        ApiConstants.me,
        headers: ApiConstants.authHeaders(token),
      );
      final data = res['data'];
      final user =
          (data is Map<String, dynamic>) ? (data['user'] ?? data) : null;
      final id = (user is Map<String, dynamic>) ? user['id'] : null;
      return id?.toString();
    } catch (e) {
      _debug('fetchUserId failed: $e');
      return null;
    }
  }

  Map<String, dynamic>? _decode(dynamic raw) {
    try {
      if (raw is Map<String, dynamic>) return raw;
      if (raw is String && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
      }
    } catch (_) {}
    return null;
  }

  void _debug(String msg) {
    if (kDebugMode) debugPrint('[Realtime] $msg');
  }

  @override
  void onClose() {
    stop();
    super.onClose();
  }
}
