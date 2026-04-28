import 'dart:typed_data';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_provider.dart';

/// Repository CV Builder structuré — miroir de l'API `/api/v1/profile/cv-builder/*`.
///
/// Couvre :
///  - GET /cv-builder                 → [show]
///  - PUT /cv-builder                 → [update] (1 champ ou N champs)
///  - GET /cv-builder/preview         → [preview] (HTML)
///  - POST /cv-builder/assistant      → [assistant] (chat IA)
///  - POST /cv-builder/import/analyze → [importAnalyze] (upload PDF/DOCX)
///  - POST /cv-builder/import/improve → [importImprove]
///  - POST /cv-builder/import/apply   → [importApply]
///
/// Les endpoints qui retournent un PDF binaire ([download], [importDownload])
/// sont appelés via une URL construite côté client (on passe par `launchUrl`
/// ou une requête multipart dédiée — voir les méthodes en bas).
class CvBuilderRepository {
  const CvBuilderRepository({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  final ApiProvider _apiProvider;

  /// Retourne le CV courant + métriques (completion_pct, xp_points, level, badges).
  Future<Map<String, dynamic>> show() async {
    final response = await _apiProvider.getJson(ApiConstants.profileCvBuilder);
    return _unwrap(response);
  }

  /// Met à jour un seul champ ou plusieurs en une passe.
  /// Si [fields] est non-null, il prime sur [field]/[value].
  Future<Map<String, dynamic>> update({
    String? field,
    dynamic value,
    Map<String, dynamic>? fields,
  }) async {
    final payload = <String, dynamic>{
      if (field != null) 'field': field,
      if (field != null) 'value': value,
      if (fields != null) 'fields': fields,
    };
    final response =
        await _apiProvider.putJson(ApiConstants.profileCvBuilder, payload);
    return _unwrap(response);
  }

  /// HTML rendu du CV (pour WebView).
  Future<Map<String, dynamic>> preview({String template = 'classic'}) async {
    final response = await _apiProvider.getJson(
      '${ApiConstants.profileCvBuilderPreview}?template=${Uri.encodeComponent(template)}',
    );
    return _unwrap(response);
  }

  /// Message assistant IA.
  /// Le client DOIT renvoyer le [confirmedFields] reçu à l'itération précédente
  /// (l'API est stateless — pas de session serveur).
  Future<Map<String, dynamic>> assistant({
    required String message,
    List<Map<String, String>> history = const [],
    List<String> confirmedFields = const [],
    bool freeEditMode = false,
  }) async {
    final response = await _apiProvider.postJson(
      '${ApiConstants.profileCvBuilder}/assistant',
      {
        'message': message,
        if (history.isNotEmpty) 'history': history,
        'confirmed_fields': confirmedFields,
        'free_edit_mode': freeEditMode,
      },
    );
    return _unwrap(response);
  }

  /// Marque un template comme "le CV principal" de l'utilisateur côté
  /// backend. Pilote le filename de download par défaut et la vue
  /// recruteur. [template] doit être l'un de classic | modern | minimal.
  Future<Map<String, dynamic>> selectTemplate(String template) async {
    final response = await _apiProvider.postJson(
      ApiConstants.profileCvBuilderSelectTemplate,
      {'template': template},
    );
    return _unwrap(response);
  }

  /// Upload + analyse d'un CV existant (PDF/DOCX/TXT/RTF, max 10 Mo).
  /// Retourne `{analysis, extracted_text, filename, extracted_preview}`.
  /// Le client stocke `extracted_text` + `analysis` pour les renvoyer
  /// à [importImprove] à l'étape suivante.
  Future<Map<String, dynamic>> importAnalyze({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final response = await _apiProvider.sendMultipart(
      '${ApiConstants.profileCvBuilder}/import/analyze',
      method: 'POST',
      files: [
        ApiMultipartFile(field: 'cv_file', bytes: bytes, filename: fileName),
      ],
    );
    return _unwrap(response);
  }

  /// Version améliorée du CV importé.
  /// [extractedText] et [analysis] viennent du retour de [importAnalyze].
  Future<Map<String, dynamic>> importImprove({
    required String extractedText,
    required Map<String, dynamic> analysis,
  }) async {
    final response = await _apiProvider.postJson(
      '${ApiConstants.profileCvBuilder}/import/improve',
      {
        'extracted_text': extractedText,
        'analysis': analysis,
      },
    );
    return _unwrap(response);
  }

  /// Applique les champs extraits par l'IA (issus de `analysis.extracted_fields`)
  /// au UserCv de l'utilisateur connecté.
  Future<Map<String, dynamic>> importApply({
    required Map<String, dynamic> extractedFields,
  }) async {
    final response = await _apiProvider.postJson(
      '${ApiConstants.profileCvBuilder}/import/apply',
      {'extracted_fields': extractedFields},
    );
    return _unwrap(response);
  }

  // ──────────────────────────────────────────────────────
  // Téléchargements PDF — pour l'instant exposés via URL signée côté client.
  // Les contrôleurs retournent un binaire ; si tu veux les consommer en Flutter
  // (sauvegarde locale, partage), utilise un client HTTP dédié avec le header
  // Authorization Bearer — c'est hors du scope de ce repository JSON.
  // ──────────────────────────────────────────────────────

  /// URL absolue du download PDF du CV builder (à ouvrir via `url_launcher`
  /// avec un header Authorization, ou à fetch manuellement en bytes).
  String downloadUrl({String template = 'classic'}) =>
      '${ApiConstants.baseUrl}${ApiConstants.profileCvBuilderDownload}?template=${Uri.encodeComponent(template)}';

  /// URL absolue du download PDF du CV amélioré (requête POST avec body
  /// `{improved}` — à traiter côté app via un client HTTP direct).
  String importDownloadUrl() =>
      '${ApiConstants.baseUrl}${ApiConstants.profileCvBuilder}/import/download';

  // ──────────────────────────────────────────────────────
  // Helper
  // ──────────────────────────────────────────────────────

  Map<String, dynamic> _unwrap(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw Exception(
      response['message']?.toString() ??
          'Réponse API invalide pour CV Builder.',
    );
  }
}
