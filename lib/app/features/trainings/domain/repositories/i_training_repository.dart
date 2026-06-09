import '../entities/training.dart';

abstract class ITrainingRepository {
  Future<List<Training>> getTrainings({int page = 1});
  Future<Training?> getTrainingById(String id);
  Future<bool> enrollInTraining(String trainingId);
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
  });
}
