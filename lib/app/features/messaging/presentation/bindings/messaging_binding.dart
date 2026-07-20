import 'package:get/get.dart';
import 'package:jobaway/app/core/network/api_provider.dart';
import 'package:jobaway/app/features/offers/data/repositories/offer_repository_impl.dart';
import 'package:jobaway/app/features/offers/domain/repositories/i_offer_repository.dart';
import '../../data/repositories/messaging_repository_impl.dart';
import '../../domain/repositories/i_messaging_repository.dart';
import '../controllers/messages_controller.dart';

class MessagingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<IMessagingRepository>(
      () => MessagingRepositoryImpl(apiProvider: Get.find<ApiProvider>()),
    );
    // Les boutons des messages structurés (entretien, offre d'emploi) rejouent
    // les endpoints de la feature `offers`. Un autre binding a pu déjà
    // enregistrer le repository : on ne l'écrase pas.
    if (!Get.isRegistered<IOfferRepository>()) {
      Get.lazyPut<IOfferRepository>(
        () => OfferRepositoryImpl(apiProvider: Get.find<ApiProvider>()),
      );
    }
    Get.lazyPut(() => MessagesController(
          Get.find<IMessagingRepository>(),
          Get.find<IOfferRepository>(),
        ));
  }
}
