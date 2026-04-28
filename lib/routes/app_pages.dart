import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/modules/auth/bindings/candidate_login_binding.dart';
import '../app/modules/auth/views/candidate_login_screen.dart';
import '../app/modules/auth/bindings/recruiter_login_binding.dart';
import '../app/modules/auth/views/recruiter_login_screen.dart';
import '../app/modules/auth/bindings/register_profile_binding.dart';
import '../app/modules/auth/views/register_profile_screen.dart';
import '../app/modules/auth/controllers/otp_verification_controller.dart';
import '../app/modules/auth/views/otp_verification_screen.dart';
import '../app/modules/auth/bindings/register_binding.dart';
import '../app/modules/auth/views/register_screen.dart';
import '../app/modules/errors/views/error_404_screen.dart';
import '../app/modules/home/bindings/home_binding.dart';
import '../app/modules/home/views/home_screen.dart';
import '../app/modules/landing/bindings/landing_binding.dart';
import '../app/modules/landing/views/landing_screen.dart';
import '../app/modules/notifications/views/notifications_screen.dart';
import '../app/modules/profile_selection/bindings/profile_selection_binding.dart';
import '../app/modules/profile_selection/views/profile_selection_screen.dart';
import '../app/modules/splash/bindings/splash_binding.dart';
import '../app/modules/splash/views/splash_screen.dart';
import '../app/modules/offers/bindings/offer_detail_binding.dart';
import '../app/modules/offers/bindings/offers_binding.dart';
import '../app/modules/offers/views/my_applications_screen.dart';
import '../app/modules/offers/views/offer_detail_screen.dart';
import '../app/modules/offers/views/offers_screen.dart';
import '../app/modules/trainings/bindings/training_detail_binding.dart';
import '../app/modules/trainings/bindings/trainings_binding.dart';
import '../app/modules/trainings/views/training_detail_screen.dart';
import '../app/modules/trainings/views/trainings_screen.dart';
import '../app/modules/messages/bindings/messages_binding.dart';
import '../app/modules/messages/views/messages_screen.dart';
import '../app/modules/profile/bindings/profile_binding.dart';
import '../app/modules/profile/controllers/cv_builder_controller.dart';
import '../app/modules/profile/views/cv_assistant_chat_screen.dart';
import '../app/modules/profile/views/cv_builder_landing_screen.dart';
import '../app/modules/profile/views/cv_import_screen.dart';
import '../app/modules/profile/views/cv_manual_editor_screen.dart';
import '../app/modules/profile/views/cv_preview_screen.dart';
import '../app/modules/profile/views/cv_screen.dart';
import '../app/modules/profile/views/portfolio_edit_screen.dart';
import '../app/modules/profile/views/portfolio_screen.dart';
import '../app/modules/profile/views/profile_edit_screen.dart';
import '../app/modules/profile/views/profile_screen.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = AppRoutes.splash;

  static final routes = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.profileSelection,
      page: () => const ProfileSelectionScreen(),
      binding: ProfileSelectionBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: AppRoutes.landing,
      page: () => const LandingScreen(),
      binding: LandingBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: AppRoutes.candidateLogin,
      page: () => const CandidateLoginScreen(),
      binding: CandidateLoginBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: AppRoutes.registerProfile,
      page: () => const RegisterProfileScreen(),
      binding: RegisterProfileBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterScreen(),
      binding: RegisterBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: AppRoutes.recruiterLogin,
      page: () => const RecruiterLoginScreen(),
      binding: RecruiterLoginBinding(),
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 450),
      curve: Curves.easeOutQuart,
    ),
    GetPage(
      name: AppRoutes.otpVerification,
      page: () => const OtpVerificationScreen(),
      binding: OtpVerificationBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.offers,
      page: () => const OffersScreen(),
      binding: OffersBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.offerDetail,
      page: () => const OfferDetailScreen(),
      binding: OfferDetailBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.myApplications,
      page: () => const MyApplicationsScreen(),
      binding: OffersBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.trainings,
      page: () => const TrainingsScreen(),
      binding: TrainingsBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.trainingDetail,
      page: () => const TrainingDetailScreen(),
      binding: TrainingDetailBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.messages,
      page: () => const MessagesScreen(),
      binding: MessagesBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.conversation,
      page: () => const MessagesScreen(),
      binding: MessagesBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileScreen(),
      binding: ProfileBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.profileEdit,
      page: () => const ProfileEditScreen(),
      binding: ProfileBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.profilePreferences,
      page: () => const SizedBox(),
      binding: ProfileBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.profileCv,
      page: () => const CvScreen(),
      binding: ProfileBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.profileCvBuilder,
      page: () => const CvBuilderLandingScreen(),
      binding: CvBuilderBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.profileCvAssistant,
      page: () => const CvAssistantChatScreen(),
      binding: CvBuilderBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.profileCvManual,
      page: () => const CvManualEditorScreen(),
      binding: CvBuilderBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.profileCvImport,
      page: () => const CvImportScreen(),
      binding: CvBuilderBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.profileCvPreview,
      page: () => const CvPreviewScreen(),
      binding: CvBuilderBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.profilePortfolio,
      page: () => const PortfolioScreen(),
      binding: ProfileBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.profilePortfolioEdit,
      page: () => const PortfolioEditScreen(),
      binding: ProfileBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsScreen(),
      binding: HomeBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SizedBox(),
      binding: ProfileBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.error404,
      page: () => const Error404Screen(),
      transition: Transition.fadeIn,
    ),
  ];
}
