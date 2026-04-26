import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/core/constants/api_constants.dart';
import 'app/core/i18n/app_translations.dart';
import 'app/core/security/auth_token_store.dart';
import 'app/core/theme/app_theme_controller.dart';
import 'app/core/theme/app_theme.dart';
import 'app/data/providers/api_provider.dart';
import 'app/modules/errors/error_404_screen.dart';
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

  final themeController = Get.put(AppThemeController(), permanent: true);
  await themeController.load();
  final tokenStore = Get.put(const AuthTokenStore(), permanent: true);

  // Refresh token via POST /auth/refresh : on poste avec le token courant
  // dans Authorization, le backend renvoie un nouveau token Sanctum qu'on
  // remplace dans le secure storage. En cas d'echec → null → onAuthFailed.
  Future<String?> refreshToken(ApiProvider provider) async {
    String? currentToken;
    try {
      currentToken = await tokenStore.readToken();
    } catch (_) {
      return null;
    }
    if (currentToken.trim().isEmpty) return null;
    try {
      // afterRefresh: true equivalent — on bypass la logique 401 en passant
      // par un endpoint public-style (Authorization en headers seulement).
      final response = await provider.postJson(
        '/auth/refresh',
        const <String, dynamic>{},
        headers: {
          ...ApiConstants.jsonHeaders,
          'Authorization': 'Bearer $currentToken',
        },
      );
      if (response['success'] != true) return null;
      final data = response['data'];
      final newToken = data is Map ? data['token']?.toString() : null;
      if (newToken == null || newToken.trim().isEmpty) return null;
      // saveSession exige un userType — on le relit depuis SharedPreferences
      // pour ne pas perdre l'info entre 2 sessions.
      await _persistRefreshedToken(tokenStore, newToken);
      return newToken;
    } catch (_) {
      return null;
    }
  }

  late final ApiProvider apiProvider;
  apiProvider = ApiProvider(
    tokenProvider: () async {
      try {
        return await tokenStore.readToken();
      } catch (_) {
        return null;
      }
    },
    tokenRefresher: () => refreshToken(apiProvider),
    onAuthFailed: () async {
      // Token revoke ou refresh echoue : on coupe la session et on route
      // vers la landing — l'utilisateur devra se reconnecter.
      await tokenStore.clearSession();
      if (Get.currentRoute != AppRoutes.profileSelection &&
          Get.currentRoute != AppRoutes.landing &&
          Get.currentRoute != AppRoutes.candidateLogin &&
          Get.currentRoute != AppRoutes.recruiterLogin) {
        Get.offAllNamed(AppRoutes.profileSelection);
      }
    },
  );
  Get.put(apiProvider, permanent: true);

  runApp(const OpportuneBFApp());
}

/// Persiste le token rafraichi en gardant le user_type courant.
/// On lit user_type depuis SharedPreferences (ou 'candidate' par defaut)
/// pour ne pas casser l'API publique de AuthTokenStore.saveSession.
Future<void> _persistRefreshedToken(
  AuthTokenStore store,
  String newToken,
) async {
  final prefs = await SharedPreferences.getInstance();
  final userType = prefs.getString('user_type') ?? 'candidate';
  await store.saveSession(token: newToken, userType: userType);
}

class OpportuneBFApp extends StatelessWidget {
  const OpportuneBFApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.isRegistered<AppThemeController>()
        ? Get.find<AppThemeController>()
        : Get.put(AppThemeController(), permanent: true);

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
