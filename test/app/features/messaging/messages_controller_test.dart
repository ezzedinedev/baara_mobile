import 'package:flutter_test/flutter_test.dart';
import 'package:jobaway/app/features/messaging/domain/entities/conversation.dart';
import 'package:jobaway/app/features/messaging/domain/entities/message.dart';
import 'package:jobaway/app/features/messaging/domain/repositories/i_messaging_repository.dart';
import 'package:jobaway/app/features/messaging/presentation/controllers/messages_controller.dart';

import '../../../support/fake_offer_repository.dart';

class _FakeMessagingRepository implements IMessagingRepository {
  List<Conversation> conversations = [];
  List<Message> messages = [];
  Message? messageToSend;
  String? lastMarkedConversationId;

  @override
  Future<List<Conversation>> getConversations(
      {int page = 1, int perPage = 20}) async {
    return conversations;
  }

  @override
  Future<Conversation> startConversation(String userId) async {
    final conv = Conversation(
      id: 'conv-$userId',
      title: 'New',
      lastMessage: '',
      lastMessageTime: DateTime.now(),
      unreadCount: 0,
      isOnline: false,
    );
    conversations.insert(0, conv);
    return conv;
  }

  @override
  Future<Conversation> acceptConversation(String conversationId) async {
    return conversations.firstWhere((c) => c.id == conversationId);
  }

  @override
  Future<void> declineConversation(String conversationId) async {
    conversations.removeWhere((c) => c.id == conversationId);
  }

  @override
  Future<bool> setVoiceNotesAllowed(
          String conversationId, bool allowed) async =>
      true;

  @override
  Future<MessagesPage> getMessages(
    String conversationId, {
    int page = 1,
    int perPage = 50,
  }) async {
    return MessagesPage(messages: messages);
  }

  @override
  Future<Message> sendMessage(String conversationId, String text) async {
    return messageToSend ??
        Message(
          id: 'new',
          text: text,
          sentAt: DateTime.now(),
          isMine: true,
          senderName: 'Me',
        );
  }

  @override
  Future<void> markAsRead(String conversationId) async {
    lastMarkedConversationId = conversationId;
  }

  @override
  Future<void> sendTyping(String conversationId, bool typing) async {}

  @override
  Future<SmartReplies> smartReplies(String conversationId) async {
    return SmartReplies.empty;
  }

  @override
  Future<ReactionResult> reactToMessage(String messageId, String emoji) async {
    return ReactionResult(
      messageId: messageId,
      emoji: emoji,
      removed: false,
      myEmoji: emoji,
    );
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
    return messageToSend ??
        Message(
          id: 'media-msg',
          text: text ?? '',
          sentAt: DateTime.now(),
          isMine: true,
          senderName: 'Me',
          messageType: messageType,
        );
  }
}

void main() {
  late MessagesController controller;
  late _FakeMessagingRepository fakeRepo;

  setUp(() {
    fakeRepo = _FakeMessagingRepository();
    controller = MessagesController(fakeRepo, FakeOfferRepository());
  });

  group('MessagesController', () {
    test('loadConversations updates list', () async {
      fakeRepo.conversations = [
        Conversation(
          id: '1',
          title: 'Test',
          lastMessage: 'Hi',
          lastMessageTime: DateTime.now(),
          unreadCount: 0,
          isOnline: false,
        ),
      ];

      await controller.loadConversations();

      expect(controller.conversations.length, 1);
      expect(controller.conversations.first.id, '1');
    });

    test('loadMessages updates active messages and marks as read', () async {
      fakeRepo.messages = [
        Message(
          id: 'm1',
          text: 'Hello',
          sentAt: DateTime.now(),
          isMine: false,
          senderName: 'User',
        ),
      ];

      await controller.loadMessages('1');

      expect(controller.activeMessages.length, 1);
      expect(controller.activeConversationId.value, '1');
      expect(fakeRepo.lastMarkedConversationId, '1');
    });

    test('sendMessage adds message to list', () async {
      controller.activeConversationId.value = '1';
      fakeRepo.messageToSend = Message(
        id: 'm2',
        text: 'Reply',
        sentAt: DateTime.now(),
        isMine: true,
        senderName: 'Me',
      );

      await controller.sendMessage('Reply');

      expect(controller.activeMessages.last.text, 'Reply');
      expect(controller.activeMessages.last.isMine, true);
    });
  });
}
