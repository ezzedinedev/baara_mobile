import '../entities/conversation.dart';
import '../entities/message.dart';

/// Page de messages + métadonnées temps réel (accusé de lecture du pair).
class MessagesPage {
  final List<Message> messages;
  final DateTime? peerLastReadAt;

  const MessagesPage({required this.messages, this.peerLastReadAt});
}

/// Résultat d'une réaction (parité backend `POST /messages/{id}/react`).
class ReactionResult {
  final String messageId;
  final String emoji;
  final bool removed;
  final String? myEmoji;

  const ReactionResult({
    required this.messageId,
    required this.emoji,
    required this.removed,
    this.myEmoji,
  });
}

/// Réponses suggérées par l'IA (`POST /messages/{id}/suggestions`).
/// [fallback] indique que ce sont des suggestions de repli (IA indispo) — à
/// gérer silencieusement côté UI (on les affiche quand même).
class SmartReplies {
  final List<String> suggestions;
  final bool fallback;

  const SmartReplies({required this.suggestions, this.fallback = false});

  static const empty = SmartReplies(suggestions: []);
}

abstract class IMessagingRepository {
  Future<List<Conversation>> getConversations({int page = 1, int perPage = 20});

  /// Démarre (ou rouvre) une conversation directe avec [userId].
  /// POST /messages/start. Statut 'accepted' si connectés, sinon 'pending'.
  Future<Conversation> startConversation(String userId);

  /// Accepte une demande de message reçue (destinataire uniquement).
  /// POST /messages/{id}/accept → conversation mise à jour.
  Future<Conversation> acceptConversation(String conversationId);

  /// Refuse une demande de message : supprime la conversation côté serveur.
  /// POST /messages/{id}/decline.
  Future<void> declineConversation(String conversationId);

  Future<MessagesPage> getMessages(String conversationId,
      {int page = 1, int perPage = 50});
  Future<Message> sendMessage(String conversationId, String text);
  Future<Message> sendMediaMessage(
    String conversationId,
    String messageType, {
    String? text,
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
  });
  Future<void> markAsRead(String conversationId);

  /// Notifie le backend que l'utilisateur tape (ou s'arrête).
  Future<void> sendTyping(String conversationId, bool typing);

  /// Bascule une réaction emoji sur un message.
  Future<ReactionResult> reactToMessage(String messageId, String emoji);

  /// Réponses suggérées par l'IA pour la conversation (3 max). Peut lever
  /// (502 → assistant indisponible) — à gérer côté contrôleur.
  Future<SmartReplies> smartReplies(String conversationId);
}
