import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../ia/domain/entities/chat_message.dart';
import '../../data/repositories/cv_assistant_repository.dart';

/// Contrôleur du chat assistant CV. Pilote l'échange utilisateur ↔ IA et
/// conserve le dernier patch de CV proposé ([latestCvDraft]) pour que l'écran
/// d'édition puisse l'appliquer.
class CvAssistantController extends GetxController {
  CvAssistantController(this._repository);

  final CvAssistantRepository _repository;

  final messages = <ChatMessage>[].obs;
  final isSending = false.obs;
  final errorMessage = RxnString();

  /// Dernier état du CV renvoyé par l'IA (champ `cv` de la réponse).
  final Rxn<Map<String, dynamic>> latestCvDraft = Rxn<Map<String, dynamic>>();

  /// Champs déjà validés, renvoyés par le backend et réémis à chaque tour pour
  /// préserver le contexte de l'assistant (`confirmed_fields`).
  final Set<String> _confirmedFields = <String>{};

  final ScrollController scrollController = ScrollController();

  /// Suggestions d'amorce affichées tant que la conversation est vide.
  static const List<String> starterPrompts = [
    'Aide-moi à rédiger mon accroche professionnelle',
    'Reformule mon expérience pour la rendre plus percutante',
    'Quelles compétences ajouter pour un poste de développeur ?',
    'Corrige les fautes de mon CV',
  ];

  @override
  void onInit() {
    super.onInit();
    _seedWelcome();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  void _seedWelcome() {
    messages.add(
      ChatMessage(
        role: 'assistant',
        content:
            "Bonjour 👋 Je suis votre assistant CV. Décrivez-moi votre parcours, "
            "vos compétences ou un poste visé, et je rédige et améliore votre CV "
            "avec vous.",
        at: DateTime.now(),
      ),
    );
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || isSending.value) return;

    // Historique = tours déjà échangés, AVANT d'ajouter le message courant.
    // Plafonné aux 30 derniers (limite backend).
    final history =
        messages.map((m) => {'role': m.role, 'content': m.content}).toList();
    final recentHistory =
        history.length > 30 ? history.sublist(history.length - 30) : history;

    messages
        .add(ChatMessage(role: 'user', content: trimmed, at: DateTime.now()));
    isSending.value = true;
    errorMessage.value = null;
    _scrollToBottom();

    try {
      final data = await _repository.sendMessage(
        trimmed,
        history: recentHistory,
        confirmedFields: _confirmedFields.toList(),
      );

      final cv = data['cv'];
      if (cv is Map<String, dynamic>) {
        latestCvDraft.value = cv;
      }

      final confirmed = data['confirmed_fields'];
      if (confirmed is List) {
        _confirmedFields
          ..clear()
          ..addAll(confirmed.map((e) => e.toString()));
      }

      final reply = (data['reply'] ?? data['message'] ?? '').toString();
      messages.add(
        ChatMessage(
          role: 'assistant',
          content: reply.isNotEmpty
              ? reply
              : "C'est noté, j'ai mis à jour votre CV.",
          at: DateTime.now(),
        ),
      );
      _scrollToBottom();
    } catch (_) {
      errorMessage.value = "Erreur d'envoi";
      messages.add(
        ChatMessage(
          role: 'assistant',
          content:
              "Désolé, je n'ai pas pu traiter votre demande. Réessayez dans un instant.",
          at: DateTime.now(),
          isError: true,
        ),
      );
      _scrollToBottom();
    } finally {
      isSending.value = false;
    }
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
