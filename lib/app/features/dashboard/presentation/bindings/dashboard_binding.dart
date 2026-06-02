import 'package:get/get.dart';
import 'package:opportune_bf/app/core/network/api_provider.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/repositories/i_dashboard_repository.dart';
import '../controllers/dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<IDashboardRepository>(
      () => DashboardRepositoryImpl(apiProvider: Get.find<ApiProvider>()),
    );
    Get.lazyPut(() => DashboardController(Get.find<IDashboardRepository>()));
  }
}
