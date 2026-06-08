import 'package:get/get.dart';
import '../../domain/entities/training.dart';
import '../../domain/repositories/i_training_repository.dart';

class TrainingsController extends GetxController {
  final ITrainingRepository _repository;
  TrainingsController(this._repository);

  final trainings = <Training>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final errorMessage = RxnString();
  final currentPage = 1.obs;
  final hasNextPage = true.obs;

  final searchQuery = ''.obs;

  // ── Filtres (client-side) ──────────────────────────────────────────────
  final activeFormat = RxnString();
  final activeLevel = RxnString();
  final freeOnly = false.obs;

  bool get hasActiveFilter =>
      activeFormat.value != null || activeLevel.value != null || freeOnly.value;

  void clearFilters() {
    activeFormat.value = null;
    activeLevel.value = null;
    freeOnly.value = false;
  }

  bool _isFree(Training t) =>
      (t.price != null && t.price! <= 0) ||
      t.priceLabel.toLowerCase().contains('gratuit');

  List<Training> get filteredTrainings {
    final query = searchQuery.value.trim().toLowerCase();
    return trainings.where((t) {
      if (activeFormat.value != null && t.format != activeFormat.value) {
        return false;
      }
      if (activeLevel.value != null && t.level != activeLevel.value) {
        return false;
      }
      if (freeOnly.value && !_isFree(t)) return false;
      if (query.isNotEmpty) {
        final match = t.title.toLowerCase().contains(query) ||
            t.providerName.toLowerCase().contains(query) ||
            t.sector.toLowerCase().contains(query);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadTrainings();
  }

  void updateSearch(String query) {
    searchQuery.value = query;
  }

  Future<void> loadTrainings({bool refresh = false}) async {
    if (refresh) {
      currentPage.value = 1;
      trainings.clear();
      hasNextPage.value = true;
    }

    try {
      isLoading.value = trainings.isEmpty;
      errorMessage.value = null;
      final result = await _repository.getTrainings(page: currentPage.value);
      if (result.isNotEmpty) {
        trainings.addAll(result);
        currentPage.value++;
      } else {
        hasNextPage.value = false;
      }
    } catch (e) {
      errorMessage.value = "Erreur de chargement des formations";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreTrainings() async {
    if (isLoadingMore.value || !hasNextPage.value) return;
    isLoadingMore.value = true;
    await loadTrainings();
    isLoadingMore.value = false;
  }
}
