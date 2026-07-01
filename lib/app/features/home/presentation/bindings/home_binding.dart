import 'package:get/get.dart';
import 'package:opportune_bf/app/core/network/api_provider.dart';

import 'package:opportune_bf/app/features/offers/data/repositories/offer_repository_impl.dart';
import 'package:opportune_bf/app/features/offers/domain/repositories/i_offer_repository.dart';
import 'package:opportune_bf/app/features/offers/presentation/controllers/offer_controller.dart';
import 'package:opportune_bf/app/features/offers/presentation/controllers/applications_controller.dart';

import 'package:opportune_bf/app/features/trainings/data/repositories/training_repository_impl.dart';
import 'package:opportune_bf/app/features/trainings/domain/repositories/i_training_repository.dart';
import 'package:opportune_bf/app/features/trainings/presentation/controllers/trainings_controller.dart';

import 'package:opportune_bf/app/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:opportune_bf/app/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:opportune_bf/app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:opportune_bf/app/features/profile/presentation/controllers/settings_controller.dart';
import 'package:opportune_bf/app/features/profile/data/repositories/document_repository_impl.dart';
import 'package:opportune_bf/app/features/profile/domain/repositories/i_document_repository.dart';
import 'package:opportune_bf/app/features/profile/presentation/controllers/documents_controller.dart';

import 'package:opportune_bf/app/features/messaging/data/repositories/messaging_repository_impl.dart';
import 'package:opportune_bf/app/features/messaging/domain/repositories/i_messaging_repository.dart';
import 'package:opportune_bf/app/features/messaging/presentation/controllers/messages_controller.dart';

import 'package:opportune_bf/app/features/community/data/repositories/community_repository_impl.dart';
import 'package:opportune_bf/app/features/community/domain/repositories/i_community_repository.dart';
import 'package:opportune_bf/app/features/community/presentation/controllers/community_controller.dart';
import 'package:opportune_bf/app/features/community/presentation/controllers/story_controller.dart';

import 'package:opportune_bf/app/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:opportune_bf/app/features/notifications/domain/repositories/i_notification_repository.dart';
import 'package:opportune_bf/app/features/notifications/presentation/controllers/notifications_controller.dart';

import 'package:opportune_bf/app/features/suivi/presentation/controllers/suivi_controller.dart';
import 'package:opportune_bf/app/features/streak/presentation/controllers/streak_controller.dart';

import 'package:opportune_bf/app/features/home/presentation/controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HomeController());

    // TAB: Offers
    Get.lazyPut<IOfferRepository>(
        () => OfferRepositoryImpl(apiProvider: Get.find<ApiProvider>()));
    Get.lazyPut(() => OfferController(Get.find<IOfferRepository>()));
    // Candidatures + entretiens à venir (onglet Candidatures/Entretiens du hub
    // Suivi, et écran « Mes candidatures »).
    Get.lazyPut(() => ApplicationsController(Get.find<IOfferRepository>()));

    // TAB: Trainings
    Get.lazyPut<ITrainingRepository>(
        () => TrainingRepositoryImpl(apiProvider: Get.find<ApiProvider>()));
    Get.lazyPut(() => TrainingsController(Get.find<ITrainingRepository>()));

    // TAB: Profile
    Get.lazyPut<IProfileRepository>(
        () => ProfileRepositoryImpl(apiProvider: Get.find<ApiProvider>()));
    Get.lazyPut(() => ProfileController(Get.find<IProfileRepository>()));
    Get.lazyPut(() => SettingsController(Get.find<ProfileController>()));
    Get.lazyPut<IDocumentRepository>(
        () => DocumentRepositoryImpl(apiProvider: Get.find<ApiProvider>()));
    Get.lazyPut(() => DocumentsController(Get.find<IDocumentRepository>()));

    // TAB: Messaging
    Get.lazyPut<IMessagingRepository>(
        () => MessagingRepositoryImpl(apiProvider: Get.find<ApiProvider>()));
    Get.lazyPut(() => MessagesController(Get.find<IMessagingRepository>()));

    // SECTION: Communauté (aperçu sur l'accueil + écran dédié /communaute)
    Get.lazyPut<ICommunityRepository>(
        () => CommunityRepositoryImpl(apiProvider: Get.find<ApiProvider>()));
    Get.lazyPut(() => CommunityController(Get.find<ICommunityRepository>()));
    // Eager (pas lazy) : précharge les stories dès l'accueil → la barre est
    // déjà prête quand on ouvre l'onglet Communauté (plus de chargement tardif).
    Get.put(StoryController(Get.find<ICommunityRepository>()));

    // Série quotidienne : eager → le check-in du jour est enregistré dès
    // l'arrivée sur l'accueil (gamification de rétention).
    Get.put(StreakController());

    // TAB: Suivi (façade agrégeant offres + candidatures + communauté).
    Get.lazyPut(() => SuiviController(
          offers: Get.find<OfferController>(),
          applications: Get.find<ApplicationsController>(),
          community: Get.find<CommunityController>(),
        ));

    // Notifications : badge non-lus sur la cloche de l'accueil (controller
    // partagé avec l'écran /notifications).
    Get.lazyPut<INotificationRepository>(
        () => NotificationRepositoryImpl(apiProvider: Get.find<ApiProvider>()));
    Get.lazyPut(
        () => NotificationsController(Get.find<INotificationRepository>()));
  }
}
