import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
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

  // Recherche locale dans l'inbox (titre + dernier message).
  final searchQuery = ''.obs;

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
  final activeConversationId = RxnString();
  int _convPage = 1;

  @override
  void onInit() {
    super.onInit();
    loadConversations();

    final id = Get.parameters['id'];
    if (id != null) {
      loadMessages(id);
    }
  }

  Future<void> loadConversations() async {
    try {
      isLoadingConversations.value = true;
      _convPage = 1;
      final result =
          await _repository.getConversations(page: 1, perPage: _convPerPage);
      conversations.assignAll(result);
      // Pas de méta de pagination renvoyée : si on reçoit une page pleine, on
      // suppose qu'il peut y en avoir d'autres.
      hasMoreConversations.value = result.length >= _convPerPage;
    } catch (e) {
      if (kDebugMode) debugPrint('[Messages] loadConversations error: $e');
    } finally {
      isLoadingConversations.value = false;
    }
  }

  /// Charge la page suivante de conversations (scroll infini).
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
      final result = await _repository.getMessages(conversationId);
      activeMessages.assignAll(result);
      await _repository.markAsRead(conversationId);
    } catch (e) {
      if (kDebugMode) debugPrint('[Messages] loadMessages error: $e');
    } finally {
      isLoadingMessages.value = false;
    }
  }

  Future<void> sendMessage(String text) async {
    final convId = activeConversationId.value;
    if (convId == null || text.trim().isEmpty) return;

    try {
      isSending.value = true;
      final msg = await _repository.sendMessage(convId, text);
      activeMessages.add(msg);
    } catch (e) {
      if (kDebugMode) debugPrint('[Messages] sendMessage error: $e');
      AppToast.error('Erreur', "Le message n'a pas pu être envoyé.");
    } finally {
      isSending.value = false;
    }
  }
}
