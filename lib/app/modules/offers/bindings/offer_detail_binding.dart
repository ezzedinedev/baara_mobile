import 'package:get/get.dart';

import '../controllers/offer_detail_controller.dart';
import '../controllers/offers_controller.dart';

/// Binding du detail d'offre : injecte un [OfferDetailController] frais
/// pour chaque navigation, et garantit la presence du [OffersController]
/// (utilise pour l'action Postuler + la liste partagee de saved/applied
/// offers entre l'ecran liste et le detail).
class OfferDetailBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<OffersController>()) {
      Get.lazyPut<OffersController>(() => OffersController());
    }
    Get.lazyPut<OfferDetailController>(() => OfferDetailController());
  }
}
