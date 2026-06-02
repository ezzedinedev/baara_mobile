import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../core/utils/user_facing_error.dart';
import '../../data/repositories/cv_editor_repository.dart';

/// Édite manuellement le CV : charge les valeurs courantes, expose des
/// contrôleurs de champ + listes (compétences, langues), et sauvegarde tout
/// d'un coup via [CvEditorRepository.saveFields].
class CvEditorController extends GetxController {
  CvEditorController(this._repository);

  final CvEditorRepository _repository;

  final isLoading = true.obs;
  final isSaving = false.obs;
  final errorMessage = RxnString();

  // Identité (lecture seule — gérée au niveau du profil utilisateur)
  final candidateName = ''.obs;

  // Champs texte éditables
  final roleCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final linkedinCtrl = TextEditingController();
  final portfolioCtrl = TextEditingController();
  final bioCtrl = TextEditingController();
  final objectiveCtrl = TextEditingController();

  // Listes éditables
  final hardSkills = <String>[].obs;
  final softSkills = <String>[].obs;
  final languages = <Map<String, String>>[].obs;

  // Sections complexes (gérées via l'assistant) — comptes informatifs
  final experiencesCount = 0.obs;
  final educationsCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    roleCtrl.dispose();
    locationCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    linkedinCtrl.dispose();
    portfolioCtrl.dispose();
    bioCtrl.dispose();
    objectiveCtrl.dispose();
    super.onClose();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final data = await _repository.load();
      final cv = data['cv'] is Map<String, dynamic>
          ? data['cv'] as Map<String, dynamic>
          : <String, dynamic>{};
      final user = data['user'] is Map ? data['user'] as Map : const {};

      candidateName.value = [
        user['first_name']?.toString() ?? '',
        user['last_name']?.toString() ?? '',
      ].where((s) => s.trim().isNotEmpty).join(' ').trim();

      roleCtrl.text = _str(cv['desired_role'] ?? cv['headline']);
      locationCtrl.text = _str(cv['location']);
      phoneCtrl.text = _str(cv['phone'] ?? user['phone']);
      emailCtrl.text = _str(cv['email'] ?? user['email']);
      linkedinCtrl.text = _str(cv['linkedin_url']);
      portfolioCtrl.text = _str(cv['portfolio_url']);
      bioCtrl.text = _str(cv['bio']);
      objectiveCtrl.text = _str(cv['objective']);

      hardSkills.assignAll(_strList(cv['hard_skills']));
      softSkills.assignAll(_strList(cv['soft_skills']));
      languages.assignAll(_langList(cv['languages']));

      experiencesCount.value = _len(cv['experiences']);
      educationsCount.value = _len(cv['educations']);
    } catch (e) {
      errorMessage.value = userFacingError(e);
    } finally {
      isLoading.value = false;
    }
  }

  void addHardSkill(String v) => _addTo(hardSkills, v);
  void addSoftSkill(String v) => _addTo(softSkills, v);
  void removeHardSkill(String v) => hardSkills.remove(v);
  void removeSoftSkill(String v) => softSkills.remove(v);

  void addLanguage(String name, String level) {
    final n = name.trim();
    if (n.isEmpty) return;
    languages.add({'name': n, 'level': level.trim()});
  }

  void removeLanguage(int index) {
    if (index >= 0 && index < languages.length) languages.removeAt(index);
  }

  Future<bool> save() async {
    if (isSaving.value) return false;
    isSaving.value = true;
    errorMessage.value = null;
    try {
      await _repository.saveFields({
        'desired_role': roleCtrl.text.trim(),
        'location': locationCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'linkedin_url': linkedinCtrl.text.trim(),
        'portfolio_url': portfolioCtrl.text.trim(),
        'bio': bioCtrl.text.trim(),
        'objective': objectiveCtrl.text.trim(),
        'hard_skills': hardSkills.toList(),
        'soft_skills': softSkills.toList(),
        'languages': languages
            .map((e) => {'name': e['name'] ?? '', 'level': e['level'] ?? ''})
            .toList(),
      });
      return true;
    } catch (e) {
      errorMessage.value = userFacingError(e);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  void _addTo(RxList<String> list, String v) {
    final t = v.trim();
    if (t.isEmpty || list.contains(t)) return;
    list.add(t);
  }

  String _str(dynamic v) => v?.toString() ?? '';

  List<String> _strList(dynamic v) {
    if (v is List) {
      return v.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }

  List<Map<String, String>> _langList(dynamic v) {
    if (v is! List) return [];
    return v.map<Map<String, String>>((e) {
      if (e is Map) {
        return {
          'name': (e['name'] ?? e['language'] ?? '').toString(),
          'level': (e['level'] ?? '').toString(),
        };
      }
      return {'name': e.toString(), 'level': ''};
    }).where((m) => (m['name'] ?? '').isNotEmpty).toList();
  }

  int _len(dynamic v) => v is List ? v.length : 0;
}
