import 'dart:async';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:baara/app/core/services/post_auth_bootstrap.dart';
import 'package:baara/routes/app_routes.dart';

/// Persiste l'état de l'onboarding post-inscription (3 étapes guidées).
class OnboardingService extends GetxService {
  static const _completedKey = 'onboarding_completed_v1';
  static const _pendingRouteKey = 'onboarding_pending_route_v1';

  String? _pendingRouteMemory;

  Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey) ?? false;
  }

  Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
  }

  /// Route interne à ouvrir une fois l'onboarding terminé (deep link intercepté).
  Future<void> stashPendingRoute(String route) async {
    _pendingRouteMemory = route;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingRouteKey, route);
  }

  Future<String?> consumePendingRoute() async {
    if (_pendingRouteMemory != null) {
      final route = _pendingRouteMemory;
      _pendingRouteMemory = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingRouteKey);
      return route;
    }
    final prefs = await SharedPreferences.getInstance();
    final route = prefs.getString(_pendingRouteKey);
    if (route != null && route.isNotEmpty) {
      await prefs.remove(_pendingRouteKey);
      return route;
    }
    return null;
  }

  /// Après connexion ou inscription : directement l'accueil, sans écran
  /// de présentation. L'autorisation des notifications est demandée une
  /// fois l'accueil affiché, pour ne pas bloquer l'arrivée.
  Future<void> navigateAfterAuth() async {
    await markCompleted();
    final pending = await consumePendingRoute();
    Get.offAllNamed(AppRoutes.home);
    if (pending != null && pending.isNotEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      Get.toNamed<void>(pending);
    }
    unawaited(Future<void>.delayed(
      const Duration(milliseconds: 900),
      PostAuthBootstrap.activatePushAfterLogin,
    ));
  }
}
