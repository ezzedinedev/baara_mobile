import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../../../data/repositories/ai_repository.dart';
import '../../../../data/models/ai_models.dart';
import '../../domain/entities/chat_message.dart';

class ChatbotController extends GetxController {
  final AiRepository _repository;
  ChatbotController(this._repository);

  final messages = <ChatMessage>[].obs;
  final sessionId = RxnString();
  final isSending = false.obs;
  final isLoadingHistory = false.obs;
  final errorMessage = RxnString();
  
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    _resumeLastSession();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  Future<void> _resumeLastSession() async {
    try {
      isLoadingHistory.value = true;
      final sessions = await _repository.chatSessions();
      if (sessions.isEmpty) return;

      final lastSessionId = sessions.first['id']?.toString();
      if (lastSessionId == null) return;

      final history = await _repository.chatSession(lastSessionId);
      sessionId.value = lastSessionId;
      
      final mappedMessages = history.map((m) {
        return ChatMessage(
          role: m['role']?.toString() ?? 'user',
          content: m['content']?.toString() ?? '',
          at: DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now(),
        );
      }).toList();
      
      messages.assignAll(mappedMessages);
      _scrollToBottom();
    } catch (_) {
      // Ignorer l'échec de reprise
    } finally {
      isLoadingHistory.value = false;
    }
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || isSending.value) return;

    messages.add(ChatMessage(role: 'user', content: trimmed, at: DateTime.now()));
    isSending.value = true;
    errorMessage.value = null;
    _scrollToBottom();

    try {
      final AiChatResponse result = await _repository.chatSend(
        message: trimmed,
        sessionId: sessionId.value,
      );

      sessionId.value = result.sessionId ?? sessionId.value;
      
      messages.add(ChatMessage(
        role: 'assistant',
        content: result.reply,
        at: DateTime.now(),
        ctaActions: result.ctaActions.map((cta) => CtaAction(
          type: cta['type']?.toString() ?? '',
          id: cta['id']?.toString(),
          label: cta['label']?.toString() ?? '',
        )).toList(),
      ));
      _scrollToBottom();
    } catch (e) {
      errorMessage.value = "Erreur d'envoi";
      messages.add(ChatMessage(
        role: 'assistant',
        content: "Désolé, j'ai rencontré un problème technique. Pouvez-vous réessayer ?",
        at: DateTime.now(),
        isError: true,
      ));
      _scrollToBottom();
    } finally {
      isSending.value = false;
    }
  }

  void resetSession() {
    sessionId.value = null;
    messages.clear();
    messages.add(ChatMessage(
      role: 'assistant', 
      content: "Bonjour ! Comment puis-je vous aider aujourd'hui ?", 
      at: DateTime.now()
    ));
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
