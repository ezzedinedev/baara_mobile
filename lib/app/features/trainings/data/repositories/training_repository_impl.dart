import 'package:jobaway/app/core/network/api_provider.dart';
import 'package:jobaway/app/core/constants/api_constants.dart';
import '../../domain/entities/enrolled_training.dart';
import '../../domain/entities/training.dart';
import '../../domain/repositories/i_training_repository.dart';
import '../models/enrolled_training_model.dart';
import '../models/training_model.dart';

class TrainingRepositoryImpl implements ITrainingRepository {
  final ApiProvider _apiProvider;

  TrainingRepositoryImpl({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  @override
  Future<List<Training>> getTrainings({int page = 1}) async {
    final response =
        await _apiProvider.getJson('${ApiConstants.trainings}?page=$page');
    if (response['success'] == true) {
      final data = response['data'];
      final List<dynamic> items = data is List ? data : (data['data'] ?? []);
      return items.map((json) => TrainingModel.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<Training?> getTrainingById(String id) async {
    final response =
        await _apiProvider.getJson('${ApiConstants.trainings}/$id');
    if (response['success'] == true && response['data'] != null) {
      return TrainingModel.fromJson(response['data']);
    }
    return null;
  }

  @override
  Future<List<EnrolledTraining>> getEnrolledTrainings({int page = 1}) async {
    final response = await _apiProvider
        .getJson('${ApiConstants.trainingsEnrolled}?page=$page');
    if (response['success'] != true) return [];

    // Paginator Laravel : les lignes sont sous data.data.
    final data = response['data'];
    final items = data is List ? data : (data is Map ? data['data'] : null);
    if (items is! List) return [];

    return items
        .whereType<Map<String, dynamic>>()
        .map(EnrolledTrainingModel.fromJson)
        .toList();
  }

  @override
  Future<bool> enrollInTraining(
    String trainingId, {
    Map<String, dynamic>? applicationData,
  }) async {
    final response = await _apiProvider.postJson(
      ApiConstants.trainingEnroll(trainingId),
      {...?applicationData},
    );
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

  @override
  Future<({bool success, String? message})> payTraining(
    String trainingId, {
    required String provider,
    required String phone,
    Map<String, dynamic>? applicationData,
  }) async {
    final response = await _apiProvider.postJson(
      ApiConstants.trainingPay(trainingId),
      {'provider': provider, 'phone': phone, ...?applicationData},
    );
    return (
      success: response['success'] == true,
      message: response['message']?.toString(),
    );
  }

  @override
  Future<bool> reviewTraining(
    String trainingId, {
    required int rating,
    String? comment,
  }) async {
    final response = await _apiProvider.postJson(
      ApiConstants.trainingReview(trainingId),
      {
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
      },
    );
    return response['success'] == true || response['ok'] == true;
  }
}
