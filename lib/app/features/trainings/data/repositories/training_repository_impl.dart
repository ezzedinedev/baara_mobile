import 'package:opportune_bf/app/core/network/api_provider.dart';
import 'package:opportune_bf/app/core/constants/api_constants.dart';
import '../../domain/entities/training.dart';
import '../../domain/repositories/i_training_repository.dart';
import '../models/training_model.dart';

class TrainingRepositoryImpl implements ITrainingRepository {
  final ApiProvider _apiProvider;

  TrainingRepositoryImpl({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  @override
  Future<List<Training>> getTrainings({int page = 1}) async {
    final response = await _apiProvider.getJson('${ApiConstants.trainings}?page=$page');
    if (response['success'] == true) {
      final data = response['data'];
      final List<dynamic> items = data is List ? data : (data['data'] ?? []);
      return items.map((json) => TrainingModel.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<Training?> getTrainingById(String id) async {
    final response = await _apiProvider.getJson('${ApiConstants.trainings}/$id');
    if (response['success'] == true && response['data'] != null) {
      return TrainingModel.fromJson(response['data']);
    }
    return null;
  }

  @override
  Future<bool> enrollInTraining(String trainingId) async {
    final response = await _apiProvider.postJson(ApiConstants.trainingEnroll(trainingId), {});
    return response['success'] == true;
  }

  @override
  Future<bool> updateProgress(
    String trainingId, {
    required Set<String> completedModuleIds,
  }) async {
    final response = await _apiProvider.postJson(
      ApiConstants.trainingProgress(trainingId),
      {
        'modules_completed': completedModuleIds.toList(),
      },
    );
    return response['success'] == true;
  }
}
