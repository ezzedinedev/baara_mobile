import 'package:get/get.dart';

import '../../../../core/utils/user_facing_error.dart';
import '../../data/repositories/cv_preview_repository.dart';

/// Écran « Mes CVs » : état réel du CV du candidat.
///
/// Attention au piège côté serveur : `GET /profile/cv-builder` fait un
/// `firstOrCreate` puis pré-remplit nom/email/téléphone depuis le compte. La
/// charge `cv` n'est donc **jamais** vide, même pour quelqu'un qui n'a jamais
/// touché au CV — se fier à « la map est non vide » revient à dire que tout le
/// monde a un CV. On regarde donc le contenu réellement rédigé.
class MyCvController extends GetxController {
  MyCvController(this._repository);

  final CvPreviewRepository _repository;

  /// Sections qui font qu'un CV existe vraiment (au-delà de l'identité
  /// recopiée du compte).
  static const _contentFields = <String>[
    'experiences',
    'educations',
    'hard_skills',
    'soft_skills',
    'languages',
    'certifications',
    'projects',
    'headline',
    'desired_role',
    'bio',
    'objective',
  ];

  final isLoading = true.obs;
  final errorMessage = RxnString();

  final hasCv = false.obs;
  final completionPct = 0.obs;
  final selectedTemplate = 'classic'.obs;
  final experienceCount = 0.obs;
  final educationCount = 0.obs;
  final skillCount = 0.obs;
  final headline = ''.obs;
  final lastActivityAt = Rxn<DateTime>();

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
      final cv = data['cv'] is Map
          ? Map<String, dynamic>.from(data['cv'] as Map)
          : <String, dynamic>{};

      hasCv.value = _contentFields.any((f) => _isFilled(cv[f]));
      completionPct.value = _asInt(data['completion_pct']);
      experienceCount.value = _countOf(cv['experiences']);
      educationCount.value = _countOf(cv['educations']);
      skillCount.value =
          _countOf(cv['hard_skills']) + _countOf(cv['soft_skills']);
      headline.value = (cv['headline'] ?? cv['desired_role'] ?? '').toString();
      lastActivityAt.value =
          DateTime.tryParse(cv['last_activity_at']?.toString() ?? '');

      final assistant = data['assistant_state'];
      if (assistant is Map && assistant['selected_template'] is String) {
        selectedTemplate.value = assistant['selected_template'] as String;
      }
    } catch (e) {
      errorMessage.value = userFacingError(e);
    } finally {
      isLoading.value = false;
    }
  }

  bool _isFilled(dynamic value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is Iterable) return value.isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    return true;
  }

  int _countOf(dynamic value) => value is Iterable ? value.length : 0;

  int _asInt(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
