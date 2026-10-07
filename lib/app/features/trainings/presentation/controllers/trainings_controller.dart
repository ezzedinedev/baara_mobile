import 'package:baara/app/core/constants/app_features.dart';
import 'package:get/get.dart';
import '../../domain/entities/enrolled_training.dart';
import '../../domain/entities/training.dart';
import '../../domain/repositories/i_training_repository.dart';
import '../../../../core/utils/user_facing_error.dart';

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

  /// Formations proposées dans l'app : sans achat intégré (version stores),
  /// les payantes n'apparaissent que si elles sont déjà acquises.
  /// Même définition de « payante » que le bouton d'inscription : un prix
  /// strictement positif (un prix inconnu n'est pas un achat).
  bool isOffered(Training t) {
    final isPaid = t.price != null && t.price! > 0;
    return AppFeatures.inAppPurchases || !isPaid || t.isEnrolled;
  }

  List<Training> get visibleTrainings => trainings.where(isOffered).toList();

  List<Training> get filteredTrainings {
    final query = searchQuery.value.trim().toLowerCase();
    return trainings.where((t) {
      if (!isOffered(t)) return false;
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

  // ── Mes formations ─────────────────────────────────────────────────────
  // Les formations suivies vivaient uniquement dans le repository : l'app ne
  // les affichait nulle part. L'apprenant ne pouvait donc pas retrouver un
  // parcours commencé, ni voir sa progression, sans refouiller le catalogue.
  final enrolled = <EnrolledTraining>[].obs;
  final isLoadingEnrolled = false.obs;

  /// Parcours commencés mais pas terminés — ceux qu'on propose de reprendre.
  List<EnrolledTraining> get inProgress =>
      enrolled.where((e) => !e.isCompleted).toList();

  @override
  void onInit() {
    super.onInit();
    loadTrainings();
    loadEnrolled();
  }

  Future<void> loadEnrolled() async {
    if (isLoadingEnrolled.value) return;
    isLoadingEnrolled.value = true;
    try {
      enrolled.assignAll(await _repository.getEnrolledTrainings());
    } catch (_) {
      // Section secondaire : son échec ne doit pas masquer le catalogue.
      enrolled.clear();
    } finally {
      isLoadingEnrolled.value = false;
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      loadTrainings(refresh: true),
      loadEnrolled(),
    ]);
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
      errorMessage.value = userFacingError(e);
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
