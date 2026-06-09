import 'package:opportune_bf/app/core/network/api_provider.dart';
import 'package:opportune_bf/app/core/constants/api_constants.dart';
import 'package:opportune_bf/app/core/services/auth_token_store.dart';
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
  Future<List<Conversation>> getConversations({int page = 1, int perPage = 20}) async {
    final viewerType = await _tokenStore.readUserType();
    final response = await _apiProvider.getJson(
      '${ApiConstants.conversations}?page=$page&per_page=$perPage',
    );
    if (response['success'] == true) {
      final data = response['data'];
      if (data == null) return [];
      final List<dynamic> items = data is List ? data : (data['data'] as List<dynamic>? ?? []);
      return items
          .map((json) => ConversationModel.fromJson(
                json as Map<String, dynamic>,
                viewerType: viewerType,
              ))
          .toList();
    }
    return [];
  }

  @override
  Future<List<Message>> getMessages(String conversationId, {int page = 1, int perPage = 50}) async {
    final response = await _apiProvider.getJson(
      '${ApiConstants.conversation(conversationId)}?page=$page&per_page=$perPage',
    );
    if (response['success'] == true) {
      final data = response['data'];
      if (data == null) return [];
      final List<dynamic> items = data is List ? data : (data['data'] as List<dynamic>? ?? []);
      return items.map((json) => MessageModel.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
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
  Future<void> markAsRead(String conversationId) async {
    await _apiProvider.postJson(ApiConstants.conversationRead(conversationId), {});
  }
}
