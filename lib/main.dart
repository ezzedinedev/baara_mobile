import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'app/bindings/initial_binding.dart';
import 'app/core/services/fcm_service.dart';
import 'app/core/theme/app_theme.dart';
import 'app/core/theme/app_theme_controller.dart';
import 'app/modules/errors/views/error_404_screen.dart';
import 'app/translations/app_translations.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

Future<void> main() async {
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

  // Firebase d'abord — un crash silencieux ici signifie que les fichiers
  // google-services.json / GoogleService-Info.plist sont absents ou que
  // le bundle ID ne correspond pas. On ne bloque pas le boot de l'app
  // (mode degrade : pas de push notifs, mais le polling continue).
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
  } catch (e) {
    debugPrint('[Firebase] init failed: $e');
  }

  // Tous les services partagés (theme, token store, ApiProvider avec refresh)
  // sont enregistrés dans InitialBinding pour rester organisés.
  await InitialBinding().dependencies();

  // FcmService demande la permission, recupere le token, le pousse au
  // backend et cable les handlers de messages. Doit etre apres
  // InitialBinding (a besoin de ApiProvider) et apres Firebase.init.
  if (Firebase.apps.isNotEmpty) {
    final fcm = Get.put<FcmService>(FcmService(), permanent: true);
    unawaited(fcm.init());
  }

  runApp(const OpportuneBFApp());
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
