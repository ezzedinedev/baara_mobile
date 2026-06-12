import 'package:get/get.dart';
import 'package:opportune_bf/app/core/network/api_provider.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../data/repositories/portfolio_repository.dart';
import '../../data/repositories/document_repository_impl.dart';
import '../../domain/repositories/i_profile_repository.dart';
import '../../domain/repositories/i_document_repository.dart';
import '../controllers/profile_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/documents_controller.dart';
import '../controllers/portfolio_controller.dart';
import '../controllers/portfolio_edit_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<IProfileRepository>(
      () => ProfileRepositoryImpl(apiProvider: Get.find<ApiProvider>()),
    );
    Get.lazyPut(() => ProfileController(Get.find<IProfileRepository>()));
    Get.lazyPut(() => SettingsController(Get.find<ProfileController>()));
    Get.lazyPut<IDocumentRepository>(
        () => DocumentRepositoryImpl(apiProvider: Get.find<ApiProvider>()));
    Get.lazyPut(() => DocumentsController(Get.find<IDocumentRepository>()));

    Get.lazyPut<PortfolioRepository>(
      () => PortfolioRepository(apiProvider: Get.find<ApiProvider>()),
    );
    Get.lazyPut(() => PortfolioController(Get.find<PortfolioRepository>()));
    Get.lazyPut(() => PortfolioEditController(Get.find<PortfolioRepository>()));
  }
}
