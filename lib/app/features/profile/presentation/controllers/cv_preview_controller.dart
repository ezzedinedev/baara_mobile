import 'dart:typed_data';

import 'package:get/get.dart';

import '../../../../core/utils/user_facing_error.dart';
import '../../data/repositories/cv_preview_repository.dart';

/// Aperçu du CV : charge les données, gère le modèle sélectionné et fournit
/// les octets PDF (consommés par le widget d'aperçu/partage `printing`).
class CvPreviewController extends GetxController {
  CvPreviewController(this._repository);

  final CvPreviewRepository _repository;

  static const List<({String id, String label})> templates = [
    (id: 'classic', label: 'Classique'),
    (id: 'modern', label: 'Moderne'),
    (id: 'minimal', label: 'Minimal'),
  ];

  final isLoading = true.obs;
  final errorMessage = RxnString();
  final selectedTemplate = 'classic'.obs;
  final completionPct = 0.obs;
  final hasCvData = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final data = await _repository.loadCv();
      final assistant = data['assistant_state'];
      if (assistant is Map && assistant['selected_template'] is String) {
        selectedTemplate.value = assistant['selected_template'] as String;
      }
      completionPct.value = _asInt(data['completion_pct']);
      hasCvData.value = data['cv'] is Map && (data['cv'] as Map).isNotEmpty;
    } catch (e) {
      errorMessage.value = userFacingError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Change le modèle et le persiste côté serveur (best-effort).
  Future<void> changeTemplate(String template) async {
    if (selectedTemplate.value == template) return;
    selectedTemplate.value = template;
    try {
      await _repository.selectTemplate(template);
    } catch (_) {
      // Non bloquant : l'aperçu PDF se régénère même si la persistance échoue.
    }
  }

  /// Octets PDF du modèle courant (pour l'aperçu / le partage).
  Future<Uint8List> pdfBytes() =>
      _repository.downloadPdf(selectedTemplate.value);

  int _asInt(dynamic v) {
    if (v is num) return v.round();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}
