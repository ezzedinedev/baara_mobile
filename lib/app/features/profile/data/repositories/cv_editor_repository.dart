import 'package:baara/app/core/constants/api_constants.dart';
import 'package:baara/app/core/network/api_provider.dart';
import 'package:baara/app/core/network/api_response.dart';

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
    ApiResponse.ensureSuccess(response, fallback: 'Sauvegarde impossible.');
    return ApiResponse.dataMap(response);
  }
}
