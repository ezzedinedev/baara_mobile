import '../../../../data/models/ai_models.dart';

abstract class IIaRepository {
  Future<AiMatchFeedResponse> matchFeed({int limit = 20, bool rerank = true});

  Future<AiCoverLetter> coverLetter({
    required String offerId,
    String tone = 'formal',
    String length = 'medium',
  });

  Future<Map<String, dynamic>> cvAdapt(String offerId);

  /// Écrit les suggestions d'adaptation dans le CV de l'utilisateur.
  ///
  /// ATTENTION au nom : « apply » = appliquer les suggestions **au CV**, pas
  /// postuler à l'offre. Le backend (`AiApiController@cvAdaptApply`) attend le
  /// bloc `suggestions` renvoyé par [cvAdapt] et ne crée aucune candidature.
  /// Pour postuler, enchaîner ensuite sur `IOfferRepository.applyToOffer`.
  Future<Map<String, dynamic>> cvAdaptApply(Map<String, dynamic> suggestions);

  Future<Map<String, dynamic>> cvRewrite({
    String? section,
    String? content,
    String tone = 'professional',
  });

  Future<AiCvAudit> cvAudit();

  Future<AiProfileScore> profileScore();

  Future<AiChatResponse> chatSend({
    required String message,
    String? sessionId,
  });

  Future<List<Map<String, dynamic>>> chatSessions();

  Future<List<Map<String, dynamic>>> chatSession(String sessionId);

  Future<bool> sendChatFeedback({
    required String sessionId,
    required int rating,
    int? assistantMessageIndex,
    String? comment,
    String? correction,
  });
}
