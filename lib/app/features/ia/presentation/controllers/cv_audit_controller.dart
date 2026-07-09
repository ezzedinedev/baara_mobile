import 'package:get/get.dart';

import '../../../../data/models/ai_models.dart';
import '../../domain/repositories/i_ia_repository.dart';
import '../../../../core/utils/user_facing_error.dart';

/// Charge l'audit qualité du CV (POST /ai/cv/audit) et permet de demander une
/// réécriture IA section par section (POST /ai/cv/rewrite).
class CvAuditController extends GetxController {
  CvAuditController(this._repository);

  final IIaRepository _repository;

  final isLoading = true.obs;
  final errorMessage = RxnString();
  final Rxn<AiCvAudit> audit = Rxn<AiCvAudit>();

  /// Section en cours de réécriture (clé), pour afficher un loader localisé.
  final rewritingSection = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      audit.value = await _repository.cvAudit();
    } catch (e) {
      errorMessage.value = userFacingError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Demande une réécriture IA d'une section. Retourne le texte proposé
  /// (ou null en cas d'échec) — l'écran l'affiche dans un bottom sheet.
  Future<String?> rewriteSection(String section) async {
    if (rewritingSection.value != null) return null;
    rewritingSection.value = section;
    try {
      final data = await _repository.cvRewrite(section: section);
      return (data['rewritten'] ?? data['content'] ?? data['text'] ?? '')
          .toString();
    } catch (_) {
      return null;
    } finally {
      rewritingSection.value = null;
    }
  }
}
