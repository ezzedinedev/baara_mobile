import 'package:baara/app/core/network/api_provider.dart';
import 'package:baara/app/core/network/api_response.dart';
import 'package:baara/app/core/constants/api_constants.dart';
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
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de charger les formations.');
    return ApiResponse.extractList(response['data'])
        .map((json) => TrainingModel.fromJson(json))
        .toList();
  }

  @override
  Future<Training?> getTrainingById(String id) async {
    final response =
        await _apiProvider.getJson('${ApiConstants.trainings}/$id');
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de charger cette formation.');
    final item = ApiResponse.extractItem(response['data']);
    if (item != null) return TrainingModel.fromJson(item);
    return null;
  }

  @override
  Future<List<EnrolledTraining>> getEnrolledTrainings({int page = 1}) async {
    final response = await _apiProvider
        .getJson('${ApiConstants.trainingsEnrolled}?page=$page');
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de charger vos formations suivies.');

    // Paginator Laravel : les lignes sont sous data.data.
    return ApiResponse.extractList(response['data'])
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
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de vous inscrire à cette formation.');
    return true;
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
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible d\'enregistrer votre progression.');
    return true;
  }

  /// Paiement : `success: false` + `message` est un résultat métier légitime
  /// (solde insuffisant, opérateur qui refuse…), pas une erreur technique — on
  /// ne lève donc pas ici, le message backend est remonté tel quel à l'appelant.
  /// Les échecs réseau/serveur, eux, remontent déjà en exception d'ApiProvider.
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
    if (response['ok'] == true) return true;
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible d\'envoyer votre avis.');
    return true;
  }
}
