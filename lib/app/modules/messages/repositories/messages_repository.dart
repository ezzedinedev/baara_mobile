import '../../../data/providers/api_provider.dart';
import '../../../core/constants/api_constants.dart';
import '../models/message_model.dart';

class MessagesRepository {
  const MessagesRepository({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  final ApiProvider _apiProvider;

  Future<PaginatedConversationsResult> getConversations({
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _apiProvider.getJson(
      '${ApiConstants.conversations}?page=$page&per_page=$perPage',
    );

    return _parsePaginatedResponse(response);
  }

  Future<List<MessageModel>> getMessages(
    String conversationId, {
    int page = 1,
    int perPage = 50,
  }) async {
    // Backend : GET /api/v1/messages/{conversation}
    final response = await _apiProvider.getJson(
      '${ApiConstants.conversations}/$conversationId?page=$page&per_page=$perPage',
    );

    return _parseMessagesResponse(response);
  }

  Future<MessageModel> sendMessage(
    String conversationId,
    String text,
  ) async {
    // Backend : POST /api/v1/messages/{conversation}/send avec champ "content".
    final response = await _apiProvider.postJson(
      '${ApiConstants.conversations}/$conversationId/send',
      {'content': text},
    );

    if (response['success'] == true && response['data'] != null) {
      return MessageModel.fromJson(response['data'], isMine: true);
    }
    throw Exception(
      response['message']?.toString() ?? 'Echec de l\'envoi du message.',
    );
  }

  Future<bool> markAsRead(String conversationId) async {
    // Backend : POST /api/v1/messages/{conversation}/read
    final response = await _apiProvider.postJson(
      '${ApiConstants.conversations}/$conversationId/read',
      {},
    );
    return response['success'] == true;
  }

  PaginatedConversationsResult _parsePaginatedResponse(
      Map<String, dynamic> response) {
    final data = response['data'];
    List<ConversationModel> items = [];
    int currentPage = 1;
    int totalPages = 1;
    int total = 0;

    if (data is List) {
      items = data.map((e) => ConversationModel.fromJson(e)).toList();
    } else if (data is Map) {
      if (data['data'] is List) {
        items = (data['data'] as List)
            .map((e) => ConversationModel.fromJson(e))
            .toList();
      }
      currentPage = data['current_page'] ?? 1;
      totalPages = data['last_page'] ?? 1;
      total = data['total'] ?? 0;
    }

    return PaginatedConversationsResult(
      items: items,
      currentPage: currentPage,
      totalPages: totalPages,
      total: total,
    );
  }

  List<MessageModel> _parseMessagesResponse(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is List) {
      return data.map((e) => MessageModel.fromJson(e)).toList();
    }
    if (data is Map && data['messages'] is List) {
      return (data['messages'] as List)
          .map((e) => MessageModel.fromJson(e))
          .toList();
    }
    return [];
  }
}

class PaginatedConversationsResult {
  const PaginatedConversationsResult({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.total,
  });

  final List<ConversationModel> items;
  final int currentPage;
  final int totalPages;
  final int total;

  bool get hasNextPage => currentPage < totalPages;
  bool get hasPreviousPage => currentPage > 1;
}
