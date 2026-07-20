import 'dart:typed_data';

import 'package:jobaway/app/core/constants/api_constants.dart';
import 'package:jobaway/app/core/network/api_provider.dart';

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
    await _apiProvider.postJson(
      ApiConstants.profileCvBuilderSelectTemplate,
      {'template': template},
    );
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
    final statusCode = response['statusCode'] as int?;
    final success = response['success'] as bool? ??
        (statusCode != null && statusCode < 400);
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
