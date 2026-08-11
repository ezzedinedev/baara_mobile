import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'fcm_service.dart';

/// Actions post-authentification (push, etc.) — point d'entrée unique après
/// login, restauration de session ou fin d'onboarding.
class PostAuthBootstrap {
  PostAuthBootstrap._();

  static FcmService? get _fcm =>
      Get.isRegistered<FcmService>() ? Get.find<FcmService>() : null;

  /// Après login / fin d'onboarding : demande la permission push (si besoin)
  /// puis enregistre le token FCM côté backend.
  static Future<void> activatePushAfterLogin() async {
    if (Firebase.apps.isEmpty) return;
    try {
      await _fcm?.activateAfterLogin();
    } catch (e) {
      if (kDebugMode) debugPrint('[PostAuthBootstrap] activate push: $e');
    }
  }

  /// Session déjà active (splash, refresh token, retour app) : sync token
  /// sans re-demander la permission système.
  static Future<void> syncPushToken() async {
    if (Firebase.apps.isEmpty) return;
    try {
      await _fcm?.syncTokenToBackend();
      await _fcm?.refreshPermissionStatus();
    } catch (e) {
      if (kDebugMode) debugPrint('[PostAuthBootstrap] sync push: $e');
    }
  }
}
