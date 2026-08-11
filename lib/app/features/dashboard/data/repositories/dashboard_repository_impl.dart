import 'package:baara/app/core/network/api_provider.dart';
import 'package:baara/app/core/network/api_response.dart';
import 'package:baara/app/core/constants/api_constants.dart';
import '../../domain/repositories/i_dashboard_repository.dart';

class DashboardRepositoryImpl implements IDashboardRepository {
  final ApiProvider _apiProvider;

  DashboardRepositoryImpl({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  @override
  Future<Map<String, dynamic>> getCandidateDashboard() async {
    final response =
        await _apiProvider.getJson(ApiConstants.candidateDashboard);
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de charger votre tableau de bord.');
    return ApiResponse.dataMap(response);
  }

  @override
  Future<Map<String, dynamic>> getPublicStats() async {
    final response = await _apiProvider.getJson(ApiConstants.statsPublic);
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de charger les statistiques.');
    return ApiResponse.dataMap(response);
  }
}
