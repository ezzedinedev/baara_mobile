import 'dart:typed_data';

import 'package:baara/app/core/constants/api_constants.dart';
import 'package:baara/app/core/network/api_provider.dart';
import 'package:baara/app/core/network/api_response.dart';

/// Pilote le flux d'import de CV (miroir mobile du web /creer-mon-cv/importer) :
/// analyze (upload PDF→texte+analyse) → improve (réécriture IA) → apply (persist).
/// cf. CvBuilderApiController (importAnalyze / importImprove / importApply).
class CvImportRepository {
  const CvImportRepository({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  final ApiProvider _apiProvider;

  /// Étape 1 — envoie le fichier (PDF/DOCX/TXT…) et récupère le texte extrait
  /// + l'analyse (score CV, suggestions). Champ multipart attendu : `cv_file`.
  Future<Map<String, dynamic>> analyze({
    required Uint8List bytes,
    required String filename,
  }) async {
    final response = await _apiProvider.sendMultipart(
      ApiConstants.profileCvImportAnalyze,
      method: 'POST',
      files: [
        ApiMultipartFile(field: 'cv_file', bytes: bytes, filename: filename),
      ],
    );
    return _unwrap(response);
  }

  /// Étape 2 — réécriture IA à partir du texte extrait + de l'analyse.
  /// Retourne la version améliorée (champs structurés sous `improved`).
  Future<Map<String, dynamic>> improve({
    required String extractedText,
    required Map<String, dynamic> analysis,
  }) async {
    final response = await _apiProvider.postJson(
      ApiConstants.profileCvImportImprove,
      {
        'extracted_text': extractedText,
        'analysis': analysis,
      },
    );
    return _unwrap(response);
  }

  /// Étape 3 — applique les champs au CV de l'utilisateur connecté (persist).
  Future<Map<String, dynamic>> apply(
      Map<String, dynamic> extractedFields) async {
    final response = await _apiProvider.postJson(
      ApiConstants.profileCvImportApply,
      {'extracted_fields': extractedFields},
    );
    return _unwrap(response);
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic> response) {
    ApiResponse.ensureSuccess(response,
        fallback: 'Le service d\'import a renvoyé une erreur.');
    return ApiResponse.dataMap(response);
  }
}
