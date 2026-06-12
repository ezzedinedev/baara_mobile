import 'package:opportune_bf/app/core/network/api_provider.dart';
import 'package:opportune_bf/app/core/constants/api_constants.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/i_ia_repository.dart';
import '../models/chat_message_model.dart';

class IaRepositoryImpl implements IIaRepository {
  final ApiProvider _apiProvider;

  IaRepositoryImpl({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  @override
  Future<Map<String, dynamic>> sendChatMessage(
      {required String message, String? sessionId}) async {
    final response = await _apiProvider.postJson(
      ApiConstants.aiChatSend,
      {
        'message': message,
        if (sessionId != null) 'session_id': sessionId,
      },
    );
    return _unwrap(response);
  }

  @override
  Future<List<Map<String, dynamic>>> getChatSessions() async {
    final response = await _apiProvider.getJson(ApiConstants.aiChatSessions);
    final data = _unwrap(response);
    return List<Map<String, dynamic>>.from(data['sessions'] ?? []);
  }

  @override
  Future<List<ChatMessage>> getChatMessages(String sessionId) async {
    final response =
        await _apiProvider.getJson(ApiConstants.aiChatSession(sessionId));
    final data = _unwrap(response);
    final messages = (data['messages'] as List?) ?? [];
    return messages
        .whereType<Map<String, dynamic>>()
        .map((m) => ChatMessageModel.fromJson(m))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> getProfileScore() async {
    final response =
        await _apiProvider.postJson(ApiConstants.aiProfileScore, const {});
    return _unwrap(response);
  }

  @override
  Future<Map<String, dynamic>> auditCv() async {
    final response =
        await _apiProvider.postJson(ApiConstants.aiCvAudit, const {});
    return _unwrap(response);
  }

  @override
  Future<Map<String, dynamic>> generateCoverLetter({
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
    return _unwrap(response);
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw Exception(
        response['message']?.toString() ?? 'Réponse API IA invalide.');
  }
}
