import 'package:jobaway/app/core/network/api_provider.dart';
import 'package:jobaway/app/core/constants/api_constants.dart';
import '../../domain/repositories/i_dashboard_repository.dart';

class DashboardRepositoryImpl implements IDashboardRepository {
  final ApiProvider _apiProvider;

  DashboardRepositoryImpl({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  @override
  Future<Map<String, dynamic>> getCandidateDashboard() async {
    final response =
        await _apiProvider.getJson(ApiConstants.candidateDashboard);
    return response['data'] ?? {};
  }

  @override
  Future<Map<String, dynamic>> getPublicStats() async {
    final response = await _apiProvider.getJson(ApiConstants.statsPublic);
    return response['data'] ?? {};
  }
}
