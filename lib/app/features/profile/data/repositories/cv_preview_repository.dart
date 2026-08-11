import 'dart:typed_data';

import 'package:baara/app/core/constants/api_constants.dart';
import 'package:baara/app/core/network/api_provider.dart';
import 'package:baara/app/core/network/api_response.dart';

import '../../domain/entities/cv_template.dart';

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

  /// Catalogue complet des modèles (identique au web), avec le statut d'achat
  /// des modèles premium pour l'utilisateur courant.
  Future<List<CvTemplate>> loadTemplates() async {
    final response =
        await _apiProvider.getJson(ApiConstants.profileCvBuilderTemplates);
    final data = _unwrap(response);
    final raw = data['templates'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => CvTemplate.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  /// Débloque un modèle premium (mobile money). Le backend facture, trace
  /// l'achat et crédite le wallet — exactement comme le parcours web.
  Future<void> purchaseTemplate(
    String template, {
    required String provider,
    required String phone,
  }) async {
    final response = await _apiProvider.postJson(
      ApiConstants.profileCvBuilderPurchaseTemplate(template),
      {'provider': provider, 'phone': phone},
    );
    _unwrap(response);
  }

  /// Marque un modèle comme "le CV" de l'utilisateur.
  Future<void> selectTemplate(String template) async {
    final response = await _apiProvider.postJson(
      ApiConstants.profileCvBuilderSelectTemplate,
      {'template': template},
    );
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de sélectionner ce modèle.');
  }

  /// PDF d'aperçu : toujours disponible, filigrané côté serveur si le modèle
  /// premium n'est pas débloqué.
  Future<Uint8List> previewPdf(String template) {
    return _apiProvider.getBytes(
      '${ApiConstants.profileCvBuilderPreviewPdf}?template=$template',
    );
  }

  /// PDF propre, destiné au téléchargement. Le serveur répond 402 si le modèle
  /// premium n'a pas été acheté.
  Future<Uint8List> downloadPdf(String template) {
    return _apiProvider.getBytes(
      '${ApiConstants.profileCvBuilderDownload}?template=$template',
    );
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic> response) {
    ApiResponse.ensureSuccess(response, fallback: 'Aperçu indisponible.');
    return ApiResponse.dataMap(response);
  }
}
