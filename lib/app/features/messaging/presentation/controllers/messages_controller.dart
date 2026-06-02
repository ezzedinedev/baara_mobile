import 'package:get/get.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/i_messaging_repository.dart';

class MessagesController extends GetxController {
  final IMessagingRepository _repository;
  MessagesController(this._repository);

  static const int _convPerPage = 20;

  final conversations = <Conversation>[].obs;
  final activeMessages = <Message>[].obs;
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
    } catch (_) {
      // Gérer l'erreur
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
    } catch (_) {
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
    } catch (_) {
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
    } catch (_) {
    } finally {
      isSending.value = false;
    }
  }
}
