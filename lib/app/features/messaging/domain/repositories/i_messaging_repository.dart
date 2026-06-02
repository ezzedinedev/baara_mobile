import '../entities/conversation.dart';
import '../entities/message.dart';

abstract class IMessagingRepository {
  Future<List<Conversation>> getConversations({int page = 1, int perPage = 20});
  Future<List<Message>> getMessages(String conversationId, {int page = 1, int perPage = 50});
  Future<Message> sendMessage(String conversationId, String text);
  Future<void> markAsRead(String conversationId);
}
