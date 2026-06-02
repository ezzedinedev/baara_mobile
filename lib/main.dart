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
import 'app/core/constants/api_constants.dart';
import 'app/core/services/fcm_service.dart';
import 'app/core/theme/app_theme.dart';
import 'app/core/theme/app_theme_controller.dart';
import 'app/features/errors/presentation/pages/error_404_screen.dart';
// import 'app/fonctionnalites/erreurs/vue/error_404_screen.dart';
import 'app/translations/app_translations.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(_bootstrap, (error, stack) {
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

  if (kDebugMode) {
    debugPrint('[API] baseUrl = ${ApiConstants.baseUrl}');
    debugPrint(
      '[API] candidats = ${ApiConstants.baseUrlCandidates.join(' | ')}',
    );
  }

  if (Firebase.apps.isNotEmpty) {
    final fcm = Get.put<FcmService>(FcmService(), permanent: true);
    unawaited(fcm.init());
  }

  runApp(const OpportuneBFApp());
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

class OpportuneBFApp extends StatelessWidget {
  const OpportuneBFApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<AppThemeController>();

    return Obx(
      () => GetMaterialApp(
        title: 'OpporTune BF',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeController.themeMode,
        initialRoute: AppRoutes.splash,
        getPages: AppPages.routes,
        defaultTransition: Transition.rightToLeft,
        transitionDuration: const Duration(milliseconds: 260),
        // i18n : FR par defaut, EN disponible via la pref `language` du profil.
        translations: AppTranslations(),
        locale: const Locale('fr', 'FR'),
        fallbackLocale: const Locale('fr', 'FR'),
        unknownRoute: GetPage(
          name: AppRoutes.error404,
          page: () => const Error404Screen(),
        ),
      ),
    );
  }
}
