import '../entities/enrolled_training.dart';
import '../entities/training.dart';

abstract class ITrainingRepository {
  Future<List<Training>> getTrainings({int page = 1});
  Future<Training?> getTrainingById(String id);
  /// Inscription à une formation gratuite.
  ///
  /// [applicationData] = le dossier d'inscription, obligatoire quand la
  /// formation l'exige (`enrollment_form_required`) : motivation, niveau,
  /// disponibilité et réponses au questionnaire du formateur. Le backend refuse
  /// l'inscription (422) s'il manque.
  Future<bool> enrollInTraining(
    String trainingId, {
    Map<String, dynamic>? applicationData,
  });

  /// Formations suivies par le candidat connecté (« Mes formations »).
  ///
  /// Renvoie des inscriptions — progression et certificat inclus — car la
  /// formation seule ne dit pas où en est l'apprenant. La formation imbriquée
  /// n'est qu'un résumé : pour la fiche complète, appeler [getTrainingById].
  Future<List<EnrolledTraining>> getEnrolledTrainings({int page = 1});

  /// Met à jour la progression d'une formation.
  ///
  /// [completedModuleIds] = l'ENSEMBLE complet des modules terminés. Le backend
  /// remplace `modules_completed` par cette liste (il ne fusionne pas) et en
  /// déduit `progress_pct` — envoyer un seul id écraserait les précédents.
  Future<bool> updateProgress(
    String trainingId, {
    required Set<String> completedModuleIds,
  });

  /// Paiement (mobile money) d'une formation payante.
  /// [provider] ∈ {orange, moov, wave}. Retourne le succès + message backend.
  Future<({bool success, String? message})> payTraining(
    String trainingId, {
    required String provider,
    required String phone,
    Map<String, dynamic>? applicationData,
  });

  Future<bool> reviewTraining(
    String trainingId, {
    required int rating,
    String? comment,
  });
}
