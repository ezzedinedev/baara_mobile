import '../entities/saved_search.dart';

/// Dépôt des recherches sauvegardées / alertes emploi (API /saved-searches).
abstract class IAlertsRepository {
  /// Liste des alertes du candidat connecté.
  Future<List<SavedSearch>> getSavedSearches();

  /// Crée une alerte à partir d'un libellé et d'un jeu de filtres. Retourne
  /// l'alerte créée, ou null en cas d'échec.
  Future<SavedSearch?> createSavedSearch({
    required String label,
    required Map<String, dynamic> filters,
    bool notify = true,
  });

  /// Active/désactive les notifications d'une alerte. Retourne true si OK.
  Future<bool> setNotify(String id, bool notify);

  /// Supprime une alerte. Retourne true si OK.
  Future<bool> deleteSavedSearch(String id);
}
