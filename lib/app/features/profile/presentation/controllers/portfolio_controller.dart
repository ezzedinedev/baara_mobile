import 'package:get/get.dart';

import '../../../../core/utils/user_facing_error.dart';
import '../../data/repositories/portfolio_repository.dart';
import '../../domain/entities/portfolio_item.dart';

/// Liste du portfolio + suppression. L'ajout/édition est piloté par
/// [PortfolioEditController], qui demande un [load] après sauvegarde.
class PortfolioController extends GetxController {
  PortfolioController(this._repository);

  final PortfolioRepository _repository;

  final items = <PortfolioItem>[].obs;
  final isLoading = true.obs;
  final errorMessage = RxnString();
  final deletingId = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      items.assignAll(await _repository.list());
    } catch (e) {
      errorMessage.value = userFacingError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> delete(PortfolioItem item) async {
    if (deletingId.value != null) return false;
    final index = items.indexWhere((e) => e.id == item.id);
    if (index == -1) return false;

    // Optimiste : on retire la carte tout de suite (feedback instantané) et on
    // la réinsère à sa place si l'appel réseau échoue.
    deletingId.value = item.id;
    items.removeAt(index);
    try {
      await _repository.delete(item.id);
      return true;
    } catch (_) {
      items.insert(index > items.length ? items.length : index, item);
      return false;
    } finally {
      deletingId.value = null;
    }
  }
}
