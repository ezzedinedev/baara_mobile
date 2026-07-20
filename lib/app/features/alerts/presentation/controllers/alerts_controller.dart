import 'package:get/get.dart';

import 'package:jobaway/app/core/utils/user_facing_error.dart';
import 'package:jobaway/app/core/widgets/common/app_toast.dart';

import '../../domain/entities/saved_search.dart';
import '../../domain/repositories/i_alerts_repository.dart';

/// Gère les alertes emploi (recherches sauvegardées) du candidat : liste,
/// création, activation/désactivation des notifications, suppression.
class AlertsController extends GetxController {
  AlertsController(this._repo);

  final IAlertsRepository _repo;

  final alerts = <SavedSearch>[].obs;
  final isLoading = true.obs;
  final errorMessage = RxnString();
  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      alerts.assignAll(await _repo.getSavedSearches());
    } catch (e) {
      errorMessage.value = userFacingError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Crée une alerte depuis un libellé + un jeu de filtres (typiquement
  /// l'instantané des filtres courants de la liste d'offres). Retourne true
  /// si la création a réussi.
  Future<bool> create({
    required String label,
    required Map<String, dynamic> filters,
  }) async {
    if (label.trim().isEmpty) return false;
    isSaving.value = true;
    try {
      final created = await _repo.createSavedSearch(
        label: label.trim(),
        filters: filters,
      );
      if (created == null) {
        AppToast.error('Alerte non créée', 'Réessaie dans un instant.');
        return false;
      }
      alerts.insert(0, created);
      AppToast.success('Alerte créée', 'Tu seras notifié des nouvelles offres.');
      return true;
    } catch (e) {
      AppToast.error('Alerte non créée', userFacingError(e));
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// Bascule les notifications d'une alerte (optimiste + rollback si échec).
  Future<void> toggleNotify(SavedSearch alert) async {
    final next = !alert.notify;
    _replace(alert.id, alert.copyWith(notify: next));
    final ok = await _repo.setNotify(alert.id, next);
    if (!ok) {
      _replace(alert.id, alert.copyWith(notify: alert.notify));
      AppToast.error('Action impossible', 'Réessaie dans un instant.');
    }
  }

  /// Supprime une alerte (retrait optimiste + rollback si l'API échoue).
  Future<void> delete(SavedSearch alert) async {
    final index = alerts.indexWhere((a) => a.id == alert.id);
    if (index == -1) return;
    alerts.removeAt(index);
    final ok = await _repo.deleteSavedSearch(alert.id);
    if (ok) {
      AppToast.info('Alerte supprimée', alert.label);
    } else {
      alerts.insert(index, alert);
      AppToast.error('Suppression impossible', 'Réessaie dans un instant.');
    }
  }

  void _replace(String id, SavedSearch updated) {
    final index = alerts.indexWhere((a) => a.id == id);
    if (index != -1) alerts[index] = updated;
  }
}
