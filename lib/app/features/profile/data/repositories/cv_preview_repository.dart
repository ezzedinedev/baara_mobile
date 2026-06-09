import 'dart:typed_data';

import 'package:opportune_bf/app/core/constants/api_constants.dart';
import 'package:opportune_bf/app/core/network/api_provider.dart';

/// Accès au CV structuré pour l'aperçu : chargement des données, choix du
/// modèle, et téléchargement du PDF généré côté serveur.
/// cf. CvBuilderApiController (show / selectTemplate / download).
class CvPreviewRepository {
  const CvPreviewRepository({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  final ApiProvider _apiProvider;

  /// Charge le CV courant (+ template sélectionné, complétion). Le backend
  /// crée la ligne si absente (firstOrCreate), donc le download qui suit ne 404 pas.
  Future<Map<String, dynamic>> loadCv() async {
    final response = await _apiProvider.getJson(ApiConstants.profileCvBuilder);
    return _unwrap(response);
  }

  /// Marque un modèle comme "le CV" de l'utilisateur (classic | modern | minimal).
  Future<void> selectTemplate(String template) async {
    await _apiProvider.postJson(
      ApiConstants.profileCvBuilderSelectTemplate,
      {'template': template},
    );
  }

  /// Récupère le PDF (octets bruts) pour un modèle donné.
  Future<Uint8List> downloadPdf(String template) {
    return _apiProvider.getBytes(
      '${ApiConstants.profileCvBuilderDownload}?template=$template',
    );
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic> response) {
    final statusCode = response['statusCode'] as int?;
    final success =
        response['success'] as bool? ?? (statusCode != null && statusCode < 400);
    if (!success) {
      throw ApiException(
        message: response['message']?.toString() ?? 'Aperçu indisponible.',
        statusCode: statusCode,
      );
    }
    final data = response['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }
}
