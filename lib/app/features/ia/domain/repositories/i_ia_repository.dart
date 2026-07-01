import '../entities/chat_message.dart';

abstract class IIaRepository {
  // Chatbot
  Future<Map<String, dynamic>> sendChatMessage(
      {required String message, String? sessionId});
  Future<List<Map<String, dynamic>>> getChatSessions();
  Future<List<ChatMessage>> getChatMessages(String sessionId);

  /// Feedback sur une réponse du chat IA (POST /ai/chat/feedback).
  /// [rating] : -1 (négatif), 0 (neutre), 1 (positif).
  Future<bool> sendChatFeedback({
    required String sessionId,
    required int rating,
    int? assistantMessageIndex,
    String? comment,
    String? correction,
  });

  // Profile Scoring
  Future<Map<String, dynamic>> getProfileScore();

  // CV Audit
  Future<Map<String, dynamic>> auditCv();

  // Cover Letter
  //
  // NB: pas de score par offre ici — `/offers/{id}/match` côté backend est un
  // alias d'`apply` (il crée une candidature). Le scoring se fait en masse via
  // le feed `/ai/match/feed`.
  Future<Map<String, dynamic>> generateCoverLetter({
    required String offerId,
    String tone = 'formal',
    String length = 'medium',
  });
}
