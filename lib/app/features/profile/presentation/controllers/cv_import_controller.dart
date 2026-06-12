import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

import '../../../../core/utils/user_facing_error.dart';
import '../../data/repositories/cv_import_repository.dart';

/// Étapes du flux d'import.
enum CvImportStep {
  pick,
  analyzing,
  review,
  improving,
  improved,
  applying,
  done
}

/// Orchestration de l'import de CV : sélection fichier → analyse → revue →
/// amélioration IA → application au CV. État observable pour [CvImportScreen].
class CvImportController extends GetxController {
  CvImportController(this._repository);

  final CvImportRepository _repository;

  final step = CvImportStep.pick.obs;
  final errorMessage = RxnString();
  final filename = RxnString();

  // Données issues de l'analyse
  String _extractedText = '';
  Map<String, dynamic> _analysis = const {};
  final cvScore = 0.obs;
  final profileScore = 0.obs;
  final summary = RxnString();

  // Champs améliorés (à appliquer)
  Map<String, dynamic> _improvedFields = const {};

  bool get isBusy =>
      step.value == CvImportStep.analyzing ||
      step.value == CvImportStep.improving ||
      step.value == CvImportStep.applying;

  /// Étape 1 — sélectionne un fichier puis lance l'analyse.
  Future<void> pickAndAnalyze() async {
    if (isBusy) return;
    errorMessage.value = null;

    final FilePickerResult? result;
    try {
      result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'docx', 'doc', 'txt', 'rtf'],
        withData: true,
      );
    } catch (_) {
      errorMessage.value = 'Impossible d\'ouvrir le sélecteur de fichiers.';
      return;
    }

    if (result == null || result.files.isEmpty) return; // annulé
    final picked = result.files.first;
    final bytes = picked.bytes;
    if (bytes == null) {
      errorMessage.value =
          'Fichier illisible. Réessayez avec un autre fichier.';
      return;
    }

    filename.value = picked.name;
    step.value = CvImportStep.analyzing;
    try {
      final data =
          await _repository.analyze(bytes: bytes, filename: picked.name);
      _extractedText = (data['extracted_text'] ?? '').toString();
      _analysis = data['analysis'] is Map<String, dynamic>
          ? data['analysis'] as Map<String, dynamic>
          : <String, dynamic>{};
      cvScore.value =
          _asInt(_analysis['cv_score'] ?? _analysis['overall_score']);
      profileScore.value = _asInt(_analysis['profile_score']);
      summary.value = (_analysis['summary'] ?? _analysis['feedback'] ?? '')
          .toString()
          .trim();
      step.value = CvImportStep.review;
    } catch (e) {
      step.value = CvImportStep.pick;
      errorMessage.value = userFacingError(e);
    }
  }

  /// Étape 2 — réécriture IA.
  Future<void> improve() async {
    if (isBusy || _extractedText.isEmpty) return;
    errorMessage.value = null;
    step.value = CvImportStep.improving;
    try {
      final data = await _repository.improve(
        extractedText: _extractedText,
        analysis: _analysis,
      );
      final improved = data['improved'];
      _improvedFields =
          improved is Map<String, dynamic> ? improved : <String, dynamic>{};
      step.value = CvImportStep.improved;
    } catch (e) {
      step.value = CvImportStep.review;
      errorMessage.value = userFacingError(e);
    }
  }

  /// Étape 3 — applique au CV de l'utilisateur.
  Future<bool> apply() async {
    if (isBusy || _improvedFields.isEmpty) return false;
    errorMessage.value = null;
    step.value = CvImportStep.applying;
    try {
      await _repository.apply(_improvedFields);
      step.value = CvImportStep.done;
      return true;
    } catch (e) {
      step.value = CvImportStep.improved;
      errorMessage.value = userFacingError(e);
      return false;
    }
  }

  void reset() {
    step.value = CvImportStep.pick;
    errorMessage.value = null;
    filename.value = null;
    _extractedText = '';
    _analysis = const {};
    _improvedFields = const {};
    cvScore.value = 0;
    profileScore.value = 0;
    summary.value = null;
  }

  int _asInt(dynamic v) {
    if (v is num) return v.round();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}
