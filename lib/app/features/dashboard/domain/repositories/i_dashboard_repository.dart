abstract class IDashboardRepository {
  Future<Map<String, dynamic>> getCandidateDashboard();
  Future<Map<String, dynamic>> getPublicStats();
}
