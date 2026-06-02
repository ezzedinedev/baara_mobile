import 'package:get/get.dart';
import '../../domain/repositories/i_dashboard_repository.dart';

class DashboardController extends GetxController {
  final IDashboardRepository _repository;
  DashboardController(this._repository);

  final stats = <String, dynamic>{}.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {
      isLoading.value = true;
      final result = await _repository.getCandidateDashboard();
      stats.assignAll(result);
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }
}
