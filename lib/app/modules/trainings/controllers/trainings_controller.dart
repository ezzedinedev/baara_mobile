import 'package:get/get.dart';

import '../../../data/providers/api_provider.dart';
import '../repositories/training_repository.dart';
import '../models/training_model.dart';

class TrainingsController extends GetxController {
  TrainingsController({ApiProvider? apiProvider}) {
    _repository = TrainingRepository(apiProvider: apiProvider ?? Get.find());
  }

  late final TrainingRepository _repository;

  final trainings = <TrainingModel>[].obs;
  final featuredTrainings = <TrainingModel>[].obs;
  final enrolledTrainings = <TrainingModel>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final errorMessage = ''.obs;

  final currentPage = 1.obs;
  final hasNextPage = false.obs;
  final totalTrainings = 0.obs;

  final filter = Rxn<TrainingFilter>();
  final selectedTraining = Rxn<TrainingModel>();

  static const int perPage = 20;

  @override
  void onInit() {
    super.onInit();
    loadTrainings();
    loadFeaturedTrainings();
  }

  Future<void> loadTrainings({bool refresh = false}) async {
    if (refresh) {
      currentPage.value = 1;
      trainings.clear();
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final result = await _repository.getTrainings(
        page: currentPage.value,
        perPage: perPage,
        filter: filter.value,
      );

      if (refresh) {
        trainings.value = result.items;
      } else {
        trainings.addAll(result.items);
      }

      hasNextPage.value = result.hasNextPage;
      totalTrainings.value = result.total;
    } catch (e) {
      errorMessage.value = _friendlyError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreTrainings() async {
    if (isLoadingMore.value || !hasNextPage.value) return;

    isLoadingMore.value = true;
    currentPage.value++;

    try {
      final result = await _repository.getTrainings(
        page: currentPage.value,
        perPage: perPage,
        filter: filter.value,
      );

      trainings.addAll(result.items);
      hasNextPage.value = result.hasNextPage;
    } catch (e) {
      currentPage.value--;
      errorMessage.value = _friendlyError(e);
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> loadFeaturedTrainings() async {
    try {
      final result = await _repository.getFeaturedTrainings();
      featuredTrainings.value = result;
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> loadEnrolledTrainings({bool refresh = false}) async {
    if (refresh) {
      currentPage.value = 1;
      enrolledTrainings.clear();
    }

    isLoading.value = true;

    try {
      final result = await _repository.getEnrolledTrainings(
        page: currentPage.value,
        perPage: perPage,
      );

      if (refresh) {
        enrolledTrainings.value = result;
      } else {
        enrolledTrainings.addAll(result);
      }
    } catch (e) {
      errorMessage.value = _friendlyError(e);
    } finally {
      isLoading.value = false;
    }
  }

  void applyFilter(TrainingFilter? newFilter) {
    filter.value = newFilter;
    loadTrainings(refresh: true);
  }

  void clearFilter() {
    filter.value = null;
    loadTrainings(refresh: true);
  }

  Future<bool> bookmarkTraining(String trainingId) async {
    try {
      return await _repository.bookmarkTraining(trainingId);
    } catch (e) {
      return false;
    }
  }

  Future<bool> unbookmarkTraining(String trainingId) async {
    try {
      return await _repository.unbookmarkTraining(trainingId);
    } catch (e) {
      return false;
    }
  }

  Future<bool> enrollToTraining(String trainingId) async {
    try {
      final success = await _repository.enrollToTraining(trainingId);
      if (success) {
        final index = trainings.indexWhere((t) => t.id == trainingId);
        if (index != -1) {
          enrolledTrainings.add(trainings[index]);
        }
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<void> loadTrainingDetail(String trainingId) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final training = await _repository.getTrainingById(trainingId);
      selectedTraining.value = training;
    } catch (e) {
      errorMessage.value = _friendlyError(e);
    } finally {
      isLoading.value = false;
    }
  }

  bool isTrainingEnrolled(String trainingId) {
    return enrolledTrainings.any((t) => t.id == trainingId);
  }

  @override
  Future<void> refresh() async {
    await Future.wait([
      loadTrainings(refresh: true),
      loadEnrolledTrainings(refresh: true),
    ]);
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('Unable to connect')) {
      return 'Connexion impossible. Verifiez votre reseau.';
    }
    return 'Erreur lors du chargement des formations.';
  }
}
