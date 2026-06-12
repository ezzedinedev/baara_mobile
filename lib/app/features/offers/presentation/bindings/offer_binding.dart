import 'package:get/get.dart';
import 'package:opportune_bf/app/core/network/api_provider.dart';
import '../../data/repositories/offer_repository_impl.dart';
import '../../domain/repositories/i_offer_repository.dart';
import '../controllers/offer_controller.dart';
import '../controllers/applications_controller.dart';

/// Gère l'injection des dépendances pour le module des offres.
class OfferBinding extends Bindings {
  @override
  void dependencies() {
    // 1. Data Source / ApiProvider est normalement déjà injecté par InitialBinding

    // 2. Repository implementation
    Get.lazyPut<IOfferRepository>(
      () => OfferRepositoryImpl(apiProvider: Get.find<ApiProvider>()),
    );

    // 3. Controllers
    Get.lazyPut(() => OfferController(Get.find<IOfferRepository>()));
    Get.lazyPut(() => ApplicationsController(Get.find<IOfferRepository>()));
  }
}
