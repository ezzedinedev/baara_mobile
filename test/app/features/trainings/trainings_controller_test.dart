import 'package:flutter_test/flutter_test.dart';
import 'package:opportune_bf/app/features/trainings/domain/entities/training.dart';
import 'package:opportune_bf/app/features/trainings/domain/repositories/i_training_repository.dart';
import 'package:opportune_bf/app/features/trainings/presentation/controllers/trainings_controller.dart';

class _FakeTrainingRepository implements ITrainingRepository {
  Object? errorOnLoad;
  List<Training> trainings = [];

  @override
  Future<List<Training>> getTrainings({int page = 1}) async {
    if (errorOnLoad != null) throw errorOnLoad!;
    return trainings;
  }

  @override
  Future<Training?> getTrainingById(String id) async => null;

  @override
  Future<bool> enrollInTraining(String trainingId) async => true;

  @override
  Future<bool> updateProgress(
    String trainingId, {
    required Set<String> completedModuleIds,
  }) async =>
      true;

  @override
  Future<({bool success, String? message})> payTraining(
    String trainingId, {
    required String provider,
    required String phone,
  }) async =>
      (success: true, message: null);

  @override
  Future<bool> reviewTraining(
    String trainingId, {
    required int rating,
    String? comment,
  }) async =>
      true;
}

Training _training(String id, String title) {
  return Training(
    id: id,
    title: title,
    providerName: 'Google',
    location: '',
    format: '',
    level: '',
    lessons: 0,
    rating: 0,
    enrolledCount: 0,
    status: '',
    priceLabel: '',
    sector: 'IT',
    description: '',
    durationLabel: '',
    startDateLabel: '',
    deadlineLabel: '',
    certificationLabel: '',
    languageLabel: '',
    objectives: const [],
    requirements: const [],
    modules: const [],
    contactLabel: '',
    isBookmarked: false,
    isEnrolled: false,
    coverUrl: '',
  );
}

void main() {
  late TrainingsController controller;
  late _FakeTrainingRepository fakeRepo;

  setUp(() {
    fakeRepo = _FakeTrainingRepository();
    controller = TrainingsController(fakeRepo);
  });

  group('TrainingsController', () {
    test('filteredTrainings returns only matches', () {
      controller.trainings.addAll([
        _training('1', 'Flutter Basic'),
        _training('2', 'Java Expert'),
      ]);

      controller.updateSearch('Flutter');
      expect(controller.filteredTrainings.length, 1);
      expect(controller.filteredTrainings.first.id, '1');
    });

    test('loadTrainings handles error correctly', () async {
      fakeRepo.errorOnLoad = Exception('API Error');

      await controller.loadTrainings(refresh: true);

      expect(controller.errorMessage.value, isNotNull);
      expect(controller.isLoading.value, false);
    });
  });
}
