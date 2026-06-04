import 'package:get/get.dart';

import 'package:opportune_bf/app/core/utils/user_facing_error.dart';
import 'package:opportune_bf/app/core/widgets/common/app_toast.dart';

import '../../data/repositories/cv_editor_repository.dart';

/// Édite directement les expériences & formations du candidat (stockées dans
/// le CV-builder), sans passer par le flux "Créer mon CV". Charge via
/// GET /cv-builder, ajoute/retire, et persiste via PUT /cv-builder.
class ParcoursEditorController extends GetxController {
  ParcoursEditorController(this._repository);

  final CvEditorRepository _repository;

  final experiences = <Map<String, dynamic>>[].obs;
  final educations = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;
  final isSaving = false.obs;
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final cv = await _repository.load();
      experiences.assignAll(_asMapList(cv['experiences']));
      educations.assignAll(_asMapList(cv['educations']));
    } catch (e) {
      errorMessage.value = userFacingError(e);
    } finally {
      isLoading.value = false;
    }
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<bool> addExperience(Map<String, dynamic> exp) async {
    experiences.add(exp);
    final ok = await _save();
    if (!ok) experiences.removeLast();
    return ok;
  }

  Future<bool> addEducation(Map<String, dynamic> edu) async {
    educations.add(edu);
    final ok = await _save();
    if (!ok) educations.removeLast();
    return ok;
  }

  Future<void> removeExperience(int index) async {
    if (index < 0 || index >= experiences.length) return;
    final old = experiences[index];
    experiences.removeAt(index);
    final ok = await _save();
    if (!ok) experiences.insert(index, old);
  }

  Future<void> removeEducation(int index) async {
    if (index < 0 || index >= educations.length) return;
    final old = educations[index];
    educations.removeAt(index);
    final ok = await _save();
    if (!ok) educations.insert(index, old);
  }

  Future<bool> _save() async {
    try {
      isSaving.value = true;
      await _repository.saveFields({
        'experiences': experiences.toList(),
        'educations': educations.toList(),
      });
      return true;
    } catch (e) {
      AppToast.error('Enregistrement impossible', userFacingError(e));
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
