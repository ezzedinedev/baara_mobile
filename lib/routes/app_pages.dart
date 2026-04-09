import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/modules/auth/candidate/candidate_login_binding.dart';
import '../app/modules/auth/candidate/candidate_login_screen.dart';
import '../app/modules/auth/recruiter/recruiter_login_binding.dart';
import '../app/modules/auth/recruiter/recruiter_login_screen.dart';
import '../app/modules/home/home_screen.dart';
import '../app/modules/landing/landing_binding.dart';
import '../app/modules/landing/landing_screen.dart';
import '../app/modules/profile_selection/profile_selection_binding.dart';
import '../app/modules/profile_selection/profile_selection_screen.dart';
import '../app/modules/splash/splash_binding.dart';
import '../app/modules/splash/splash_screen.dart';
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
      name: AppRoutes.recruiterLogin,
      page: () => const RecruiterLoginScreen(),
      binding: RecruiterLoginBinding(),
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 450),
      curve: Curves.easeOutQuart,
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
      transition: Transition.fadeIn,
    ),
  ];
}
