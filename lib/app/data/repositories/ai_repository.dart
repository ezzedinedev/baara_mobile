import '../../core/constants/api_constants.dart';
import '../../core/network/api_provider.dart';
import '../models/ai_models.dart';




class AiRepository {
  const AiRepository({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  final ApiProvider _apiProvider;

  /// Feed "Pour vous" — top N offres pertinentes.
  Future<AiMatchFeedResponse> matchFeed({int limit = 20, bool rerank = true}) async {
    final response = await _apiProvider.getJson(
      '${ApiConstants.aiMatchFeed}?limit=$limit&rerank=$rerank',
    );
    return AiMatchFeedResponse.fromJson(_unwrapMap(response));
  }

  /// Génère une lettre de motivation personnalisée pour une offre.
  Future<AiCoverLetter> coverLetter({
    required String offerId,
    String tone = 'formal',
    String length = 'medium',
  }) async {
    final response = await _apiProvider.postJson(
      ApiConstants.aiCoverLetter,
      {
        'offer_id': offerId,
        'tone': tone,
        'length': length,
      },
    );
    return AiCoverLetter.fromJson(_unwrapMap(response));
  }

  /// Adapte le CV courant pour une offre spécifique (preview — non persisté).
  Future<Map<String, dynamic>> cvAdapt(String offerId) async {
    final response = await _apiProvider.postJson(
      ApiConstants.aiCvAdapt,
      {'offer_id': offerId},
    );
    return _unwrapMap(response);
  }

  /// Persiste l'adaptation IA du CV pour une offre (applique le preview de
  /// [cvAdapt]). À appeler une fois que l'utilisateur valide les changements.
  Future<Map<String, dynamic>> cvAdaptApply(String offerId) async {
    final response = await _apiProvider.postJson(
      ApiConstants.aiCvAdaptApply,
      {'offer_id': offerId},
    );
    return _unwrapMap(response);
  }

  /// Réécrit via l'IA une section du CV (ou l'ensemble si [section] est nul).
  /// [content] = texte source à reformuler ; [tone] ajuste le registre.
  Future<Map<String, dynamic>> cvRewrite({
    String? section,
    String? content,
    String tone = 'professional',
  }) async {
    final response = await _apiProvider.postJson(
      ApiConstants.aiCvRewrite,
      {
        if (section != null) 'section': section,
        if (content != null) 'content': content,
        'tone': tone,
      },
    );
    return _unwrapMap(response);
  }


  /// Audit qualité du CV courant.
  Future<AiCvAudit> cvAudit() async {
    final response = await _apiProvider.postJson(
      ApiConstants.aiCvAudit,
      const {},
    );
    return AiCvAudit.fromJson(_unwrapMap(response));
  }


  /// Score décomposé du profil candidat.
  Future<AiProfileScore> profileScore() async {
    final response = await _apiProvider.postJson(
      ApiConstants.aiProfileScore,
      const {},
    );
    return AiProfileScore.fromJson(_unwrapMap(response));
  }



  /// Envoie un message au chatbot.
  Future<AiChatResponse> chatSend({
    required String message,
    String? sessionId,
  }) async {
    final response = await _apiProvider.postJson(
      ApiConstants.aiChatSend,
      {
        'message': message,
        if (sessionId != null) 'session_id': sessionId,
      },
    );
    return AiChatResponse.fromJson(_unwrapMap(response));
  }

  /// Liste des 20 dernières sessions de chat.
  Future<List<Map<String, dynamic>>> chatSessions() async {
    final response = await _apiProvider.getJson(ApiConstants.aiChatSessions);
    final data = _unwrap(response);
    return List<Map<String, dynamic>>.from(data is List ? data : []);
  }

  /// Historique complet d'une session.
  Future<List<Map<String, dynamic>>> chatSession(String sessionId) async {
    final response =
        await _apiProvider.getJson(ApiConstants.aiChatSession(sessionId));
    final data = _unwrap(response);
    return List<Map<String, dynamic>>.from(data is List ? data : []);
  }

  // ──────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────

  /// Désencapsule le champ 'data' de la réponse API.
  /// Gère les échecs via [ApiException] pour une remontée d'erreur propre.
  dynamic _unwrap(Map<String, dynamic> response) {
    final statusCode = response['statusCode'] as int?;
    final success = response['success'] as bool? ?? (statusCode != null && statusCode < 400);

    if (!success) {
      throw ApiException(
        message: response['message']?.toString() ?? 'Réponse API IA invalide.',
        statusCode: statusCode,
      );
    }

    return response['data'];
  }

  /// Helper spécifique pour s'assurer que les données sont un Map.
  Map<String, dynamic> _unwrapMap(Map<String, dynamic> response) {
    final data = _unwrap(response);
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw ApiException(
      message: 'Format de données invalide (attendu: Map).',
      statusCode: response['statusCode'] as int?,
    );
  }
}
