import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_routes.dart';
import 'package:opportune_bf/app/features/errors/presentation/pages/error_404_screen.dart';

// ── Startup ──
import 'package:opportune_bf/app/features/startup/presentation/bindings/splash_binding.dart';
import 'package:opportune_bf/app/features/startup/presentation/pages/splash_screen.dart';
import 'package:opportune_bf/app/features/startup/presentation/bindings/landing_binding.dart';
import 'package:opportune_bf/app/features/startup/presentation/pages/landing_screen.dart';
import 'package:opportune_bf/app/features/startup/presentation/bindings/profile_selection_binding.dart';
import 'package:opportune_bf/app/features/startup/presentation/pages/profile_selection_screen.dart';

// ── Auth ──
import 'package:opportune_bf/app/features/auth/presentation/bindings/candidate_login_binding.dart';
import 'package:opportune_bf/app/features/auth/presentation/pages/candidate_login_screen.dart';
import 'package:opportune_bf/app/features/auth/presentation/bindings/recruiter_login_binding.dart';
import 'package:opportune_bf/app/features/auth/presentation/pages/recruiter_login_screen.dart';
import 'package:opportune_bf/app/features/auth/presentation/bindings/register_binding.dart';
import 'package:opportune_bf/app/features/auth/presentation/pages/register_screen.dart';
import 'package:opportune_bf/app/features/auth/presentation/bindings/register_profile_binding.dart';
import 'package:opportune_bf/app/features/auth/presentation/pages/register_profile_screen.dart';
import 'package:opportune_bf/app/features/auth/presentation/bindings/otp_verification_binding.dart';
import 'package:opportune_bf/app/features/auth/presentation/pages/otp_verification_screen.dart';
import 'package:opportune_bf/app/features/auth/presentation/bindings/forgot_password_binding.dart';
import 'package:opportune_bf/app/features/auth/presentation/pages/forgot_password_screen.dart';

// ── Home ──
import 'package:opportune_bf/app/features/home/presentation/bindings/home_binding.dart';
import 'package:opportune_bf/app/features/home/presentation/pages/home_screen.dart';

// ── Offres ──
import 'package:opportune_bf/app/features/offers/presentation/bindings/offer_binding.dart';
import 'package:opportune_bf/app/features/offers/presentation/pages/offer_list_screen.dart';
import 'package:opportune_bf/app/features/offers/presentation/bindings/offer_detail_binding.dart';
import 'package:opportune_bf/app/features/offers/presentation/pages/offer_detail_screen.dart';
import 'package:opportune_bf/app/features/offers/presentation/pages/my_applications_screen.dart';

// ── Formations ──
import 'package:opportune_bf/app/features/trainings/presentation/bindings/training_binding.dart';
import 'package:opportune_bf/app/features/trainings/presentation/pages/trainings_screen.dart';
import 'package:opportune_bf/app/features/trainings/presentation/bindings/training_detail_binding.dart';
import 'package:opportune_bf/app/features/trainings/presentation/pages/training_detail_screen.dart';
import 'package:opportune_bf/app/features/trainings/presentation/bindings/training_player_binding.dart';
import 'package:opportune_bf/app/features/trainings/presentation/pages/training_player_screen.dart';

// ── Messaging ──
import 'package:opportune_bf/app/features/messaging/presentation/bindings/messaging_binding.dart';
import 'package:opportune_bf/app/features/messaging/presentation/pages/messages_screen.dart';
import 'package:opportune_bf/app/features/messaging/presentation/pages/chat_thread_screen.dart';
import 'package:opportune_bf/app/features/community/presentation/bindings/community_binding.dart';
import 'package:opportune_bf/app/features/community/presentation/pages/community_feed_screen.dart';
import 'package:opportune_bf/app/features/community/presentation/pages/community_profile_screen.dart';
import 'package:opportune_bf/app/features/community/presentation/pages/community_search_screen.dart';
import 'package:opportune_bf/app/features/community/presentation/pages/community_connections_screen.dart';

// ── Notifications ──
import 'package:opportune_bf/app/features/notifications/presentation/bindings/notifications_binding.dart';
import 'package:opportune_bf/app/features/notifications/presentation/pages/notifications_screen.dart';

// ── Profile ──
import 'package:opportune_bf/app/features/profile/presentation/bindings/profile_binding.dart';
import 'package:opportune_bf/app/features/profile/presentation/bindings/documents_binding.dart';
import 'package:opportune_bf/app/features/profile/presentation/bindings/parcours_editor_binding.dart';
import 'package:opportune_bf/app/features/profile/presentation/pages/profile_screen.dart';
import 'package:opportune_bf/app/features/profile/presentation/pages/profile_edit_screen.dart';
import 'package:opportune_bf/app/features/profile/presentation/pages/documents_screen.dart';
import 'package:opportune_bf/app/features/profile/presentation/pages/parcours_editor_screen.dart';
import 'package:opportune_bf/app/features/profile/presentation/pages/settings_screen.dart';
import 'package:opportune_bf/app/features/profile/presentation/bindings/cv_builder_binding.dart';
import 'package:opportune_bf/app/features/profile/presentation/pages/cv/cv_screen.dart';
import 'package:opportune_bf/app/features/profile/presentation/pages/cv/cv_builder_landing_screen.dart';
import 'package:opportune_bf/app/features/profile/presentation/pages/cv/cv_assistant_chat_screen.dart';
import 'package:opportune_bf/app/features/profile/presentation/pages/cv/cv_import_screen.dart';
import 'package:opportune_bf/app/features/profile/presentation/pages/cv/cv_manual_editor_screen.dart';
import 'package:opportune_bf/app/features/profile/presentation/pages/cv/cv_preview_screen.dart';
import 'package:opportune_bf/app/features/profile/presentation/pages/portfolio/portfolio_screen.dart';
import 'package:opportune_bf/app/features/profile/presentation/pages/portfolio/portfolio_edit_screen.dart';

// ── IA ──
import 'package:opportune_bf/app/features/ia/presentation/bindings/ia_binding.dart';
import 'package:opportune_bf/app/features/ia/presentation/pages/score_profil_screen.dart';
import 'package:opportune_bf/app/features/ia/presentation/pages/chatbot_screen.dart';
import 'package:opportune_bf/app/features/ia/presentation/pages/cv_audit_screen.dart';

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
      transitionDuration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
    ),
    GetPage(
      name: AppRoutes.landing,
      page: () => const LandingScreen(),
      binding: LandingBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
    ),
    GetPage(
      name: AppRoutes.candidateLogin,
      page: () => const CandidateLoginScreen(),
      binding: CandidateLoginBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
    ),
    GetPage(
      name: AppRoutes.registerProfile,
      page: () => const RegisterProfileScreen(),
      binding: RegisterProfileBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterScreen(),
      binding: RegisterBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
    ),
    GetPage(
      name: AppRoutes.recruiterLogin,
      page: () => const RecruiterLoginScreen(),
      binding: RecruiterLoginBinding(),
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
    ),
    GetPage(
      name: AppRoutes.otpVerification,
      page: () => const OtpVerificationScreen(),
      binding: OtpVerificationBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordScreen(),
      binding: ForgotPasswordBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
    ),
    GetPage(
      name: AppRoutes.forgotPasswordReset,
      page: () => const ForgotPasswordScreen(), 
      binding: ForgotPasswordBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
    ),
    GetPage(
      name: AppRoutes.offers,
      page: () => const OfferListScreen(),
      binding: OfferBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
    ),
    GetPage(
      name: AppRoutes.myApplications,
      page: () => const MyApplicationsScreen(),
      binding: OfferBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.offerDetail,
      page: () => const OfferDetailScreen(),
      binding: OfferDetailBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.trainings,
      page: () => const TrainingsScreen(),
      binding: TrainingBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.trainingDetail,
      page: () => const TrainingDetailScreen(),
      binding: TrainingDetailBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.trainingPlayer,
      page: () => const TrainingPlayerScreen(),
      binding: TrainingPlayerBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.messages,
      page: () => const MessagesScreen(),
      binding: MessagingBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.conversation,
      page: () => const ChatThreadScreen(),
      binding: MessagingBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.community,
      page: () => const CommunityFeedScreen(),
      binding: CommunityBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.communityProfile,
      page: () => const CommunityProfileScreen(),
      binding: CommunityBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.communitySearch,
      page: () => const CommunitySearchScreen(),
      binding: CommunityBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.communityConnections,
      page: () => const CommunityConnectionsScreen(),
      binding: CommunityBinding(),
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
      transitionDuration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
    ),
    GetPage(
      name: AppRoutes.profileDocuments,
      page: () => const DocumentsScreen(),
      binding: DocumentsBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.profileParcours,
      page: () => const ParcoursEditorScreen(),
      binding: ParcoursEditorBinding(),
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
      binding: NotificationsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsScreen(),
      binding: ProfileBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
    ),
    GetPage(
      name: AppRoutes.iaScoreProfil,
      page: () => const ScoreProfilScreen(),
      binding: IaBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.iaChatbot,
      page: () => const ChatbotScreen(),
      binding: IaBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.iaAuditCv,
      page: () => const CvAuditScreen(),
      binding: IaBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.error404,
      page: () => const Error404Screen(),
      transition: Transition.fadeIn,
    ),
  ];
}
