import 'dart:async';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'app/bindings/initial_binding.dart';
import 'app/core/services/deep_link_service.dart';
import 'app/core/services/fcm_service.dart';
import 'app/core/theme/app_theme.dart';
import 'app/core/theme/app_theme_controller.dart';
import 'app/core/theme/app_motion.dart';
import 'app/core/theme/app_transitions.dart';
import 'app/features/errors/presentation/pages/error_404_screen.dart';
import 'app/translations/app_translations.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(_bootstrap, (error, stack) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('auth_token') || msg.contains('bearer')) {
      debugPrint(
          '[Crash] Error with potential credentials suppressed from Crashlytics');
      return;
    }
    if (Firebase.apps.isNotEmpty) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } else {
      debugPrint('[Crash unhandled async] $error\n$stack');
    }
  });
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    _wireCrashlytics();
  } catch (e) {
    debugPrint('[Firebase] init failed: $e');
  }

  await InitialBinding().dependencies();


  if (Firebase.apps.isNotEmpty) {
    final fcm = Get.put<FcmService>(FcmService(), permanent: true);
    unawaited(fcm.init());
  }

  runApp(const JobAwayBFApp());
}

void _wireCrashlytics() {
  final crashlytics = FirebaseCrashlytics.instance;
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    crashlytics.recordFlutterFatalError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    crashlytics.recordError(error, stack, fatal: true);
    return true;
  };
}

class JobAwayBFApp extends StatefulWidget {
  const JobAwayBFApp({super.key});

  @override
  State<JobAwayBFApp> createState() => _JobAwayBFAppState();
}

class _JobAwayBFAppState extends State<JobAwayBFApp> {
  @override
  void initState() {
    super.initState();
    // Liens entrants (partage / deep links) : init après le premier frame pour
    // que le GetMaterialApp et la route initiale soient prêts à recevoir un push.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkService.instance.init();
    });
  }

  @override
  void dispose() {
    DeepLinkService.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<AppThemeController>();

    return Obx(
      () {
        // Observe explicitement les préférences d'apparence : changer l'accent
        // ou l'AMOLED ne modifie pas le ThemeMode, mais doit reconstruire l'app
        // (les ThemeData/AppColors sont des getters relus ici). Lire ces Rx
        // dans l'Obx suffit à déclencher le rebuild live.
        themeController.amoled.value;
        themeController.accentSeed.value;
        return GetMaterialApp(
          title: 'JobAway',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeController.themeMode,
          initialRoute: AppRoutes.splash,
          getPages: AppPages.routes,
          // Transition « signature » maison (fade-through + slide/scale
          // subtils), appliquée par défaut via le `customTransition` global.
          // Les GetPage qui définissent leur propre `customTransition` (la
          // plupart, cf. app_pages) ou des transitions spéciales (composer
          // downToUp, viewers fadeIn…) la conservent.
          customTransition: AppPageTransition(),
          defaultTransition: Transition.fadeIn,
          transitionDuration: AppMotion.medium,
          // i18n : FR par defaut, EN disponible via la pref `language` du profil.
          translations: AppTranslations(),
          locale: const Locale('fr', 'FR'),
          fallbackLocale: const Locale('fr', 'FR'),
          unknownRoute: GetPage(
            name: AppRoutes.error404,
            page: () => const Error404Screen(),
          ),
        );
      },
    );
  }
}
