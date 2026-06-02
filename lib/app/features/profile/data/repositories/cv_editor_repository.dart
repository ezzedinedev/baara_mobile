import 'package:opportune_bf/app/core/constants/api_constants.dart';
import 'package:opportune_bf/app/core/network/api_provider.dart';

/// Édition manuelle du CV : chargement (GET cv-builder) et sauvegarde groupée
/// des champs (PUT cv-builder avec `{fields: {...}}`).
/// cf. CvBuilderApiController (show / update).
class CvEditorRepository {
  const CvEditorRepository({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  final ApiProvider _apiProvider;

  Future<Map<String, dynamic>> load() async {
    final response = await _apiProvider.getJson(ApiConstants.profileCvBuilder);
    return _unwrap(response);
  }

  /// Sauvegarde plusieurs champs en une requête. Le backend normalise et
  /// rejette tout champ non autorisé.
  Future<Map<String, dynamic>> saveFields(Map<String, dynamic> fields) async {
    final response = await _apiProvider.putJson(
      ApiConstants.profileCvBuilder,
      {'fields': fields},
    );
    return _unwrap(response);
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic> response) {
    final statusCode = response['statusCode'] as int?;
    final success =
        response['success'] as bool? ?? (statusCode != null && statusCode < 400);
    if (!success) {
      throw ApiException(
        message: response['message']?.toString() ?? 'Sauvegarde impossible.',
        statusCode: statusCode,
      );
    }
    final data = response['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }
}
