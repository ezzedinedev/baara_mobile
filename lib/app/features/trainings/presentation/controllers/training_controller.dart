import 'package:get/get.dart';
import '../../domain/entities/training.dart';
import '../../domain/repositories/i_training_repository.dart';

class TrainingController extends GetxController {
  final ITrainingRepository _repository;
  TrainingController(this._repository);

  final trainings = <Training>[].obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();
  final currentPage = 1.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTrainings();
  }

  Future<void> fetchTrainings({bool refresh = false}) async {
    if (refresh) {
      currentPage.value = 1;
      trainings.clear();
    }

    try {
      isLoading.value = true;
      errorMessage.value = null;
      final result = await _repository.getTrainings(page: currentPage.value);
      if (result.isNotEmpty) {
        trainings.addAll(result);
        currentPage.value++;
      }
    } catch (e) {
      errorMessage.value = "Erreur de chargement des formations";
    } finally {
      isLoading.value = false;
    }
  }
}
