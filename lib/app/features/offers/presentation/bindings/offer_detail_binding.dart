import 'package:get/get.dart';
import 'package:opportune_bf/app/core/network/api_provider.dart';
import '../../data/repositories/offer_repository_impl.dart';
import '../../domain/repositories/i_offer_repository.dart';
import '../controllers/offer_detail_controller.dart';

class OfferDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<IOfferRepository>(
      () => OfferRepositoryImpl(apiProvider: Get.find<ApiProvider>()),
    );
    Get.lazyPut(() => OfferDetailController(
          Get.find<IOfferRepository>(),
        ));
  }
}
