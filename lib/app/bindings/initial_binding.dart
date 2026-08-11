import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_provider.dart';
import '../core/services/auth_token_store.dart';
import '../core/services/biometric_service.dart';
import '../core/services/network_status_service.dart';
import '../core/services/offline_apply_queue.dart';
import '../core/services/onboarding_service.dart';
import '../core/services/post_auth_bootstrap.dart';
import '../core/services/realtime_events.dart';
import '../core/services/realtime_service.dart';
import '../core/theme/app_theme_controller.dart';
import '../../routes/app_routes.dart';

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
            Get.currentRoute != AppRoutes.onboarding) {
          Get.offAllNamed(AppRoutes.landing);
        }
      },
    );
    Get.put(apiProvider, permanent: true);

    // File d'attente des candidatures hors-ligne : renvoi auto au retour du
    // reseau. Permanent (survit aux changements de page), depend d'ApiProvider.
    Get.put(OfflineApplyQueue(apiProvider), permanent: true);
    Get.put(NetworkStatusService(), permanent: true);
    Get.put(BiometricService(), permanent: true);
    Get.put(OnboardingService(), permanent: true);

    Get.put(RealtimeEventBus(), permanent: true);

    // Service temps réel (Reverb). Enregistré ici pour toujours être
    // trouvable (start au home, stop au logout) ; ne se connecte qu'une
    // fois une session présente.
    Get.put(RealtimeService(), permanent: true);
  }

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
        ApiConstants.authRefresh,
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
    await PostAuthBootstrap.syncPushToken();
  }
}
