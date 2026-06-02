import 'package:get/get.dart';
import 'package:opportune_bf/app/core/network/api_provider.dart';

import 'package:opportune_bf/app/features/offers/data/repositories/offer_repository_impl.dart';
import 'package:opportune_bf/app/features/offers/domain/repositories/i_offer_repository.dart';
import 'package:opportune_bf/app/features/offers/presentation/controllers/offer_controller.dart';

import 'package:opportune_bf/app/features/trainings/data/repositories/training_repository_impl.dart';
import 'package:opportune_bf/app/features/trainings/domain/repositories/i_training_repository.dart';
import 'package:opportune_bf/app/features/trainings/presentation/controllers/trainings_controller.dart';

import 'package:opportune_bf/app/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:opportune_bf/app/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:opportune_bf/app/features/profile/presentation/controllers/profile_controller.dart';

import 'package:opportune_bf/app/features/messaging/data/repositories/messaging_repository_impl.dart';
import 'package:opportune_bf/app/features/messaging/domain/repositories/i_messaging_repository.dart';
import 'package:opportune_bf/app/features/messaging/presentation/controllers/messages_controller.dart';

import 'package:opportune_bf/app/features/home/presentation/controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HomeController());
    
    // TAB: Offers
    Get.lazyPut<IOfferRepository>(() => OfferRepositoryImpl(apiProvider: Get.find<ApiProvider>()));
    Get.lazyPut(() => OfferController(Get.find<IOfferRepository>()));

    // TAB: Trainings
    Get.lazyPut<ITrainingRepository>(() => TrainingRepositoryImpl(apiProvider: Get.find<ApiProvider>()));
    Get.lazyPut(() => TrainingsController(Get.find<ITrainingRepository>()));

    // TAB: Profile
    Get.lazyPut<IProfileRepository>(() => ProfileRepositoryImpl(apiProvider: Get.find<ApiProvider>()));
    Get.lazyPut(() => ProfileController(Get.find<IProfileRepository>()));

    // TAB: Messaging
    Get.lazyPut<IMessagingRepository>(() => MessagingRepositoryImpl(apiProvider: Get.find<ApiProvider>()));
    Get.lazyPut(() => MessagesController(Get.find<IMessagingRepository>()));
  }
}
