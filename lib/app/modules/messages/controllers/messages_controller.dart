import 'package:get/get.dart';

import '../../../data/providers/api_provider.dart';
import '../repositories/messages_repository.dart';
import '../models/message_model.dart';

class MessagesController extends GetxController {
  MessagesController({ApiProvider? apiProvider}) {
    _repository = MessagesRepository(apiProvider: apiProvider ?? Get.find());
  }

  late final MessagesRepository _repository;

  final conversations = <ConversationModel>[].obs;
  final activeMessages = <MessageModel>[].obs;
  final isLoadingConversations = false.obs;
  final isLoadingMessages = false.obs;
  final isSending = false.obs;
  final errorMessage = ''.obs;

  final currentConversationPage = 1.obs;
  final hasMoreConversations = false.obs;
  final totalConversations = 0.obs;

  final currentMessagesPage = 1.obs;
  final hasMoreMessages = false.obs;

  final activeConversationId = RxnString();
  final unreadCount = 0.obs;

  static const int perPage = 20;
  static const int messagesPerPage = 50;

  @override
  void onInit() {
    super.onInit();
    loadConversations();
    loadUnreadCount();
  }

  Future<void> loadConversations({bool refresh = false}) async {
    if (refresh) {
      currentConversationPage.value = 1;
      conversations.clear();
    }

    isLoadingConversations.value = true;
    errorMessage.value = '';

    try {
      final result = await _repository.getConversations(
        page: currentConversationPage.value,
        perPage: perPage,
      );

      if (refresh) {
        conversations.value = result.items;
      } else {
        conversations.addAll(result.items);
      }

      hasMoreConversations.value = result.hasNextPage;
      totalConversations.value = result.total;
    } catch (e) {
      errorMessage.value = _friendlyError(e);
    } finally {
      isLoadingConversations.value = false;
    }
  }

  Future<void> loadMoreConversations() async {
    if (isLoadingConversations.value || !hasMoreConversations.value) return;

    isLoadingConversations.value = true;
    currentConversationPage.value++;

    try {
      final result = await _repository.getConversations(
        page: currentConversationPage.value,
        perPage: perPage,
      );

      conversations.addAll(result.items);
      hasMoreConversations.value = result.hasNextPage;
    } catch (e) {
      currentConversationPage.value--;
    } finally {
      isLoadingConversations.value = false;
    }
  }

  Future<void> loadMessages(String conversationId,
      {bool refresh = false}) async {
    if (refresh) {
      currentMessagesPage.value = 1;
      activeMessages.clear();
    }

    isLoadingMessages.value = true;
    activeConversationId.value = conversationId;

    try {
      final result = await _repository.getMessages(
        conversationId,
        page: currentMessagesPage.value,
        perPage: messagesPerPage,
      );

      if (refresh) {
        activeMessages.value = result;
      } else {
        activeMessages.addAll(result);
      }

      hasMoreMessages.value = result.length >= messagesPerPage;
      await _repository.markAsRead(conversationId);
      _updateUnreadCount(conversationId, 0);
    } catch (e) {
      errorMessage.value = _friendlyError(e);
    } finally {
      isLoadingMessages.value = false;
    }
  }

  Future<void> loadMoreMessages() async {
    if (isLoadingMessages.value ||
        !hasMoreMessages.value ||
        activeConversationId.value == null) {
      return;
    }

    isLoadingMessages.value = true;
    currentMessagesPage.value++;

    try {
      final result = await _repository.getMessages(
        activeConversationId.value!,
        page: currentMessagesPage.value,
        perPage: messagesPerPage,
      );

      activeMessages.addAll(result);
      hasMoreMessages.value = result.length >= messagesPerPage;
    } catch (e) {
      currentMessagesPage.value--;
    } finally {
      isLoadingMessages.value = false;
    }
  }

  Future<bool> sendMessage(String text,
      {List<Map<String, dynamic>>? attachments}) async {
    if (activeConversationId.value == null) {
      return false;
    }
    if (text.trim().isEmpty && (attachments == null || attachments.isEmpty)) {
      return false;
    }

    isSending.value = true;

    try {
      final message = await _repository.sendMessage(
        activeConversationId.value!,
        text.trim(),
        attachments: attachments,
      );

      activeMessages.add(message);
      _updateLastMessage(activeConversationId.value!, text);
      return true;
    } catch (e) {
      errorMessage.value = 'Erreur lors de l\'envoi du message.';
      return false;
    } finally {
      isSending.value = false;
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      unreadCount.value = await _repository.getUnreadCount();
    } catch (e) {
      // Silent fail
    }
  }

  void openConversation(ConversationModel conversation) {
    activeConversationId.value = conversation.id;
    loadMessages(conversation.id, refresh: true);
    _updateUnreadCount(conversation.id, 0);
  }

  void closeConversation() {
    activeConversationId.value = null;
    activeMessages.clear();
    currentMessagesPage.value = 1;
    hasMoreMessages.value = false;
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      final success = await _repository.deleteConversation(conversationId);
      if (success) {
        conversations.removeWhere((c) => c.id == conversationId);
        if (activeConversationId.value == conversationId) {
          closeConversation();
        }
      }
    } catch (e) {
      errorMessage.value = 'Erreur lors de la suppression.';
    }
  }

  void _updateUnreadCount(String conversationId, int count) {
    final index = conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      final updated = ConversationModel(
        id: conversations[index].id,
        title: conversations[index].title,
        lastMessage: conversations[index].lastMessage,
        lastMessageTime: conversations[index].lastMessageTime,
        unreadCount: count,
        isOnline: conversations[index].isOnline,
        avatar: conversations[index].avatar,
        type: conversations[index].type,
      );
      conversations[index] = updated;
    }
  }

  void _updateLastMessage(String conversationId, String message) {
    final index = conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      final updated = ConversationModel(
        id: conversations[index].id,
        title: conversations[index].title,
        lastMessage: message,
        lastMessageTime: DateTime.now(),
        unreadCount: 0,
        isOnline: conversations[index].isOnline,
        avatar: conversations[index].avatar,
        type: conversations[index].type,
      );
      conversations.removeAt(index);
      conversations.insert(0, updated);
    }
  }

  @override
  Future<void> refresh() async {
    await Future.wait([
      loadConversations(refresh: true),
      loadUnreadCount(),
    ]);
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('Unable to connect')) {
      return 'Connexion impossible.';
    }
    return 'Erreur de chargement.';
  }
}
