import 'dart:async';

import 'package:get/get.dart';

import 'package:baara/app/core/utils/user_facing_error.dart';
import 'package:baara/app/core/widgets/common/app_toast.dart';

import '../../data/repositories/cv_editor_repository.dart';
import 'profile_controller.dart';

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
      // GET /cv-builder renvoie { cv: {...}, user: {...} } : les listes sont
      // sous `cv`. Les lire à la racine les vidait, et l'ajout suivant
      // écrasait alors tout le parcours déjà enregistré.
      final data = await _repository.load();
      final cv = data['cv'] is Map
          ? Map<String, dynamic>.from(data['cv'] as Map)
          : <String, dynamic>{};
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

  /// Clés remplacées par le formulaire (anciennes clés de l'app comprises),
  /// retirées avant fusion pour ne pas laisser deux valeurs différentes.
  static const _experienceKeys = [
    'title',
    'company',
    'location',
    'from',
    'to',
    'description',
    'job_title',
    'company_name',
    'start_date',
    'end_date',
    'start',
    'end',
  ];
  static const _educationKeys = [
    'diploma',
    'school',
    'location',
    'from',
    'year',
    'description',
    'to',
    'degree',
    'institution',
    'university',
    'field_of_study',
    'start_date',
    'end_date',
    'start',
    'end',
  ];

  /// Garde les champs que le formulaire ne connaît pas (ex. mention saisie
  /// sur le site) et remplace ceux qu'il édite.
  Map<String, dynamic> _merge(
    Map<String, dynamic> original,
    Map<String, dynamic> edited,
    List<String> formKeys,
  ) =>
      Map<String, dynamic>.from(original)
        ..removeWhere((k, _) => formKeys.contains(k))
        ..addAll(edited);

  Future<bool> updateExperience(int index, Map<String, dynamic> exp) async {
    if (index < 0 || index >= experiences.length) return false;
    final old = experiences[index];
    experiences[index] = _merge(old, exp, _experienceKeys);
    final ok = await _save();
    if (!ok) experiences[index] = old;
    return ok;
  }

  Future<bool> updateEducation(int index, Map<String, dynamic> edu) async {
    if (index < 0 || index >= educations.length) return false;
    final old = educations[index];
    educations[index] = _merge(old, edu, _educationKeys);
    final ok = await _save();
    if (!ok) educations[index] = old;
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
      // Le profil (pourcentage, « Sections à compléter ») lit les mêmes
      // données : on le recharge pour qu'il soit à jour au retour.
      if (Get.isRegistered<ProfileController>()) {
        unawaited(Get.find<ProfileController>().fetchProfile());
      }
      return true;
    } catch (e) {
      AppToast.error('Enregistrement impossible', userFacingError(e));
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
