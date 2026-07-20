import 'package:get/get.dart';
import 'package:jobaway/app/core/network/api_provider.dart';

import '../../data/repositories/alerts_repository_impl.dart';
import '../../domain/repositories/i_alerts_repository.dart';
import '../controllers/alerts_controller.dart';

/// Injection de dépendances du module Alertes emploi.
class AlertsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<IAlertsRepository>(
      () => AlertsRepositoryImpl(apiProvider: Get.find<ApiProvider>()),
    );
    Get.lazyPut(() => AlertsController(Get.find<IAlertsRepository>()));
  }
}
