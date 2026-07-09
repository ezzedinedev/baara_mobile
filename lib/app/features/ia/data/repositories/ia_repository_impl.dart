import 'package:opportune_bf/app/core/constants/api_constants.dart';
import 'package:opportune_bf/app/core/network/api_provider.dart';
import 'package:opportune_bf/app/data/models/ai_models.dart';
import '../../domain/repositories/i_ia_repository.dart';

class IaRepositoryImpl implements IIaRepository {
  IaRepositoryImpl({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  final ApiProvider _apiProvider;

  @override
  Future<AiMatchFeedResponse> matchFeed(
      {int limit = 20, bool rerank = true}) async {
    final response = await _apiProvider.getJson(
      '${ApiConstants.aiMatchFeed}?limit=$limit&rerank=$rerank',
    );
    return AiMatchFeedResponse.fromJson(_unwrapMap(response));
  }

  @override
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

  @override
  Future<Map<String, dynamic>> cvAdapt(String offerId) async {
    final response = await _apiProvider.postJson(
      ApiConstants.aiCvAdapt,
      {'offer_id': offerId},
    );
    return _unwrapMap(response);
  }

  @override
  Future<Map<String, dynamic>> cvAdaptApply(String offerId) async {
    final response = await _apiProvider.postJson(
      ApiConstants.aiCvAdaptApply,
      {'offer_id': offerId},
    );
    return _unwrapMap(response);
  }

  @override
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

  @override
  Future<AiCvAudit> cvAudit() async {
    final response =
        await _apiProvider.postJson(ApiConstants.aiCvAudit, const {});
    return AiCvAudit.fromJson(_unwrapMap(response));
  }

  @override
  Future<AiProfileScore> profileScore() async {
    final response =
        await _apiProvider.postJson(ApiConstants.aiProfileScore, const {});
    return AiProfileScore.fromJson(_unwrapMap(response));
  }

  @override
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

  @override
  Future<List<Map<String, dynamic>>> chatSessions() async {
    final response = await _apiProvider.getJson(ApiConstants.aiChatSessions);
    final data = _unwrap(response);
    return List<Map<String, dynamic>>.from(data is List ? data : []);
  }

  @override
  Future<List<Map<String, dynamic>>> chatSession(String sessionId) async {
    final response =
        await _apiProvider.getJson(ApiConstants.aiChatSession(sessionId));
    final data = _unwrap(response);
    return List<Map<String, dynamic>>.from(data is List ? data : []);
  }

  @override
  Future<bool> sendChatFeedback({
    required String sessionId,
    required int rating,
    int? assistantMessageIndex,
    String? comment,
    String? correction,
  }) async {
    try {
      final response = await _apiProvider.postJson(
        ApiConstants.aiChatFeedback,
        {
          'session_id': sessionId,
          'rating': rating,
          if (assistantMessageIndex != null)
            'assistant_message_index': assistantMessageIndex,
          if (comment != null && comment.trim().isNotEmpty)
            'comment': comment.trim(),
          if (correction != null && correction.trim().isNotEmpty)
            'correction': correction.trim(),
        },
      );
      return response['success'] == true || response['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  dynamic _unwrap(Map<String, dynamic> response) {
    final statusCode = response['statusCode'] as int?;
    final success = response['success'] as bool? ??
        (statusCode != null && statusCode < 400);

    if (!success) {
      throw ApiException(
        message: response['message']?.toString() ?? 'Réponse API IA invalide.',
        statusCode: statusCode,
      );
    }

    return response['data'];
  }

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
