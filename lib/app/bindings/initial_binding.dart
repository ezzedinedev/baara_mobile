import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_provider.dart';
import '../core/services/auth_token_store.dart';
import '../core/theme/app_theme_controller.dart';
import '../../routes/app_routes.dart';

/// Initial binding : enregistre les services partagés (theme controller,
/// token store, ApiProvider avec refresh) avant le `runApp`.
///
/// Tous les `Get.put(..., permanent: true)` qui doivent vivre tant que
/// l'app tourne passent par ici. Garde `main.dart` minimal.
class InitialBinding extends Bindings {
  @override
  Future<void> dependencies() async {
    final themeController = Get.put(AppThemeController(), permanent: true);
    await themeController.load();

    final tokenStore = Get.put(const AuthTokenStore(), permanent: true);

    late final ApiProvider apiProvider;
    apiProvider = ApiProvider(
      tokenProvider: () async {
        try {
          return await tokenStore.readToken();
        } catch (_) {
          return null;
        }
      },
      tokenRefresher: () => _refreshToken(apiProvider, tokenStore),
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
  }

  /// Refresh token via POST /auth/refresh : on poste avec le token courant
  /// dans Authorization, le backend renvoie un nouveau token Sanctum qu'on
  /// remplace dans le secure storage. En cas d'echec → null → onAuthFailed.
  Future<String?> _refreshToken(
    ApiProvider provider,
    AuthTokenStore tokenStore,
  ) async {
    String? currentToken;
    try {
      currentToken = await tokenStore.readToken();
    } catch (_) {
      return null;
    }
    if (currentToken.trim().isEmpty) return null;
    try {
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
      await _persistRefreshedToken(tokenStore, newToken);
      return newToken;
    } catch (_) {
      return null;
    }
  }

  /// Persiste le token rafraichi en gardant le user_type courant.
  Future<void> _persistRefreshedToken(
    AuthTokenStore store,
    String newToken,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString('user_type') ?? 'candidate';
    await store.saveSession(token: newToken, userType: userType);
  }
}
