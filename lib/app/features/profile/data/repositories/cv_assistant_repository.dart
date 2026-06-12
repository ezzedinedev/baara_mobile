import 'package:opportune_bf/app/core/constants/api_constants.dart';
import 'package:opportune_bf/app/core/network/api_provider.dart';

/// Repository de l'assistant conversationnel CV-builder.
///
/// Miroir mobile du flux web `/mon-cv/assistant/message` : l'utilisateur
/// décrit son parcours en langage naturel, l'IA renvoie une réponse + un
/// éventuel patch du CV structuré (champ `cv`). cf.
/// `CvBuilderApiController@assistant` côté backend.
class CvAssistantRepository {
  const CvAssistantRepository({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  final ApiProvider _apiProvider;

  /// Envoie un message à l'assistant.
  ///
  /// [history] = tours précédents `[{role, content}]` (rôle `user`/`assistant`)
  /// et [confirmedFields] = champs déjà validés : le backend en a besoin pour
  /// conserver le contexte d'un tour à l'autre. Le champ `cv` n'est PAS envoyé —
  /// le backend l'ignore et le renvoie reconstruit dans la réponse.
  Future<Map<String, dynamic>> sendMessage(
    String message, {
    List<Map<String, String>> history = const [],
    List<String> confirmedFields = const [],
  }) async {
    final response = await _apiProvider.postJson(
      ApiConstants.profileCvBuilderAssistant,
      {
        'message': message,
        if (history.isNotEmpty) 'history': history,
        if (confirmedFields.isNotEmpty) 'confirmed_fields': confirmedFields,
      },
    );
    return _unwrap(response);
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic> response) {
    final statusCode = response['statusCode'] as int?;
    final success = response['success'] as bool? ??
        (statusCode != null && statusCode < 400);
    if (!success) {
      throw ApiException(
        message:
            response['message']?.toString() ?? 'Réponse assistant CV invalide.',
        statusCode: statusCode,
      );
    }
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    return <String, dynamic>{};
  }
}
