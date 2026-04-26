import '../../../data/providers/api_provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/security/auth_token_store.dart';
import '../models/training_model.dart';

class TrainingRepository {
  const TrainingRepository({
    required ApiProvider apiProvider,
    AuthTokenStore tokenStore = const AuthTokenStore(),
  })  : _apiProvider = apiProvider,
        _tokenStore = tokenStore;

  final ApiProvider _apiProvider;
  final AuthTokenStore _tokenStore;

  Future<PaginatedTrainingResult> getTrainings({
    int page = 1,
    int perPage = 20,
    TrainingFilter? filter,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (filter != null) ...filter.toQueryParams(),
    };

    final query = _buildQuery(queryParams);
    final response =
        await _apiProvider.getJson('${ApiConstants.trainings}$query');

    return _parsePaginatedResponse(response);
  }

  Future<TrainingModel?> getTrainingById(String id) async {
    final response =
        await _apiProvider.getJson('${ApiConstants.trainings}/$id');
    if (response['success'] == true && response['data'] != null) {
      return TrainingModel.fromJson(response['data']);
    }
    return null;
  }

  Future<List<TrainingModel>> getEnrolledTrainings(
      {int page = 1, int perPage = 20}) async {
    final token = await _tokenStore.readToken();
    final response = await _apiProvider.getJson(
      '${ApiConstants.trainings}/enrolled?page=$page&per_page=$perPage',
      headers: ApiConstants.authHeadersWithoutContentType(token),
    );
    return _parseListResponse(response);
  }

  Future<bool> enrollToTraining(String trainingId) async {
    final token = await _tokenStore.readToken();
    final response = await _apiProvider.postJson(
      '${ApiConstants.trainings}/$trainingId/enroll',
      {},
      headers: ApiConstants.authHeaders(token),
    );
    return response['success'] == true;
  }

  Future<bool> completeModule(String trainingId, String moduleId) async {
    final token = await _tokenStore.readToken();
    final response = await _apiProvider.postJson(
      '${ApiConstants.trainings}/$trainingId/progress',
      {'module_id': moduleId},
      headers: ApiConstants.authHeaders(token),
    );
    return response['success'] == true;
  }

  String _buildQuery(Map<String, dynamic> params) {
    if (params.isEmpty) return '';
    final query = params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
    return '?$query';
  }

  PaginatedTrainingResult _parsePaginatedResponse(
      Map<String, dynamic> response) {
    final data = response['data'];
    List<TrainingModel> items = [];
    int currentPage = 1;
    int totalPages = 1;
    int total = 0;

    if (data is List) {
      items = data.map((e) => TrainingModel.fromJson(e)).toList();
    } else if (data is Map) {
      if (data['data'] is List) {
        items = (data['data'] as List)
            .map((e) => TrainingModel.fromJson(e))
            .toList();
      }
      currentPage = data['current_page'] ?? 1;
      totalPages = data['last_page'] ?? 1;
      total = data['total'] ?? 0;
    }

    return PaginatedTrainingResult(
      items: items,
      currentPage: currentPage,
      totalPages: totalPages,
      total: total,
    );
  }

  List<TrainingModel> _parseListResponse(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is List) {
      return data.map((e) => TrainingModel.fromJson(e)).toList();
    }
    return [];
  }
}

class PaginatedTrainingResult {
  const PaginatedTrainingResult({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.total,
  });

  final List<TrainingModel> items;
  final int currentPage;
  final int totalPages;
  final int total;

  bool get hasNextPage => currentPage < totalPages;
  bool get hasPreviousPage => currentPage > 1;
}
