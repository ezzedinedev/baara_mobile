import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'app/bindings/initial_binding.dart';
import 'app/core/theme/app_theme.dart';
import 'app/core/theme/app_theme_controller.dart';
import 'app/modules/errors/error_404_screen.dart';
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

  // Tous les services partagés (theme, token store, ApiProvider avec refresh)
  // sont enregistrés dans InitialBinding pour rester organisés.
  await InitialBinding().dependencies();

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
