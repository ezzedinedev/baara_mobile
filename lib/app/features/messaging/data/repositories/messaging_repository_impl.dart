import 'package:http/http.dart' as http;

import 'package:baara/app/core/network/api_provider.dart';
import 'package:baara/app/core/network/api_response.dart';
import 'package:baara/app/core/constants/api_constants.dart';
import 'package:baara/app/core/services/auth_token_store.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/i_messaging_repository.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class MessagingRepositoryImpl implements IMessagingRepository {
  final ApiProvider _apiProvider;
  final AuthTokenStore _tokenStore;

  MessagingRepositoryImpl({
    required ApiProvider apiProvider,
    AuthTokenStore tokenStore = const AuthTokenStore(),
  })  : _apiProvider = apiProvider,
        _tokenStore = tokenStore;

  @override
  Future<List<Conversation>> getConversations(
      {int page = 1, int perPage = 20}) async {
    final viewerType = await _tokenStore.readUserType();
    final response = await _apiProvider.getJson(
      '${ApiConstants.conversations}?page=$page&per_page=$perPage',
    );
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de charger vos conversations.');
    final data = response['data'];
    if (data == null) return [];
    final List<dynamic> items =
        data is List ? data : (data['data'] as List<dynamic>? ?? []);
    return items
        .map((json) => ConversationModel.fromJson(
              json as Map<String, dynamic>,
              viewerType: viewerType,
            ))
        .toList();
  }

  @override
  Future<Conversation> startConversation(String userId) async {
    final viewerType = await _tokenStore.readUserType();
    final response = await _apiProvider.postJson(
      ApiConstants.messagesStart,
      {'user_id': userId},
    );
    if (response['success'] == true && response['data'] != null) {
      return ConversationModel.fromJson(
        response['data'] as Map<String, dynamic>,
        viewerType: viewerType,
      );
    }
    throw Exception(response['message']?.toString() ??
        'Impossible de démarrer la conversation.');
  }

  @override
  Future<Conversation> acceptConversation(String conversationId) async {
    final viewerType = await _tokenStore.readUserType();
    final response = await _apiProvider.postJson(
      ApiConstants.conversationAccept(conversationId),
      const {},
    );
    if (response['success'] == true && response['data'] != null) {
      return ConversationModel.fromJson(
        response['data'] as Map<String, dynamic>,
        viewerType: viewerType,
      );
    }
    throw Exception(response['message']?.toString() ?? 'Action impossible.');
  }

  @override
  Future<void> declineConversation(String conversationId) async {
    await _apiProvider.postJson(
      ApiConstants.conversationDecline(conversationId),
      const {},
    );
  }

  @override
  Future<MessagesPage> getMessages(String conversationId,
      {int page = 1, int perPage = 50}) async {
    final response = await _apiProvider.getJson(
      '${ApiConstants.conversation(conversationId)}?page=$page&per_page=$perPage',
    );
    if (response['success'] == true) {
      final data = response['data'];
      if (data == null) return const MessagesPage(messages: []);

      // Nouvelle forme : data = { messages: {paginator…, data:[…]}, peer_last_read_at }.
      // Ancienne forme (compat) : data = paginator direct, ou data = liste brute.
      List<dynamic> items;
      DateTime? peerLastReadAt;
      if (data is List) {
        items = data;
      } else if (data is Map<String, dynamic>) {
        final messagesNode = data['messages'];
        if (messagesNode is Map<String, dynamic>) {
          items = messagesNode['data'] as List<dynamic>? ?? const [];
        } else if (messagesNode is List) {
          items = messagesNode;
        } else {
          items = data['data'] as List<dynamic>? ?? const [];
        }
        peerLastReadAt =
            DateTime.tryParse(data['peer_last_read_at']?.toString() ?? '');
      } else {
        items = const [];
      }

      final messages = items
          .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return MessagesPage(messages: messages, peerLastReadAt: peerLastReadAt);
    }
    return const MessagesPage(messages: []);
  }

  @override
  Future<Message> sendMessage(String conversationId, String text) async {
    final response = await _apiProvider.postJson(
      ApiConstants.conversationSend(conversationId),
      {'content': text},
    );
    if (response['success'] == true && response['data'] != null) {
      return MessageModel.fromJson(response['data']);
    }
    throw Exception('Failed to send message');
  }

  @override
  Future<Message> sendMediaMessage(
    String conversationId,
    String messageType, {
    String? text,
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    final fields = <String, String>{
      'message_type': messageType,
    };
    if (text != null && text.isNotEmpty) {
      fields['content'] = text;
    }

    final files = <http.MultipartFile>[];
    if (filePath != null) {
      files.add(await http.MultipartFile.fromPath('file', filePath));
    } else if (fileBytes != null) {
      files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName ?? 'file',
      ));
    }

    final response = await _apiProvider.multipartPost(
      ApiConstants.conversationUpload(conversationId),
      fields: fields,
      files: files,
    );
    if (response['success'] == true && response['data'] != null) {
      return MessageModel.fromJson(response['data']);
    }
    // Remonte le motif réel du backend (403 règle, validation, taille…) au lieu
    // d'un message générique — sinon l'utilisateur ne sait jamais pourquoi.
    throw Exception(
        response['message']?.toString() ?? 'Le média n\'a pas pu être envoyé.');
  }

  @override
  Future<void> markAsRead(String conversationId) async {
    await _apiProvider
        .postJson(ApiConstants.conversationRead(conversationId), {});
  }

  @override
  Future<void> sendTyping(String conversationId, bool typing) async {
    await _apiProvider.postJson(
      ApiConstants.messageTyping(conversationId),
      {'typing': typing},
    );
  }

  @override
  Future<SmartReplies> smartReplies(String conversationId) async {
    final response = await _apiProvider.postJson(
      ApiConstants.messageSuggestions(conversationId),
      const {},
    );
    final data = response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final list = data['suggestions'] as List? ?? const [];
    return SmartReplies(
      suggestions: list
          .map((e) => e?.toString() ?? '')
          .where((s) => s.trim().isNotEmpty)
          .toList(),
      fallback: data['fallback'] == true,
    );
  }

  @override
  Future<ReactionResult> reactToMessage(String messageId, String emoji) async {
    final response = await _apiProvider.postJson(
      ApiConstants.messageReact(messageId),
      {'emoji': emoji},
    );
    final data = response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : response;
    return ReactionResult(
      messageId: data['message_id']?.toString() ?? messageId,
      emoji: data['emoji']?.toString() ?? emoji,
      removed: data['removed'] == true,
      myEmoji: (data['my_emoji'] as String?)?.isEmpty == true
          ? null
          : data['my_emoji'] as String?,
    );
  }
}
