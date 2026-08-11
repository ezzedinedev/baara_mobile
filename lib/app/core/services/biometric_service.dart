import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Verrou biométrique optionnel au retour sur l'app (splash / reprise session).
class BiometricService extends GetxService {
  static const _prefKey = 'pref_biometric_lock';

  final LocalAuthentication _auth = LocalAuthentication();
  final isEnabled = false.obs;
  final canUseBiometrics = false.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_hydrate());
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    isEnabled.value = prefs.getBool(_prefKey) ?? false;
    try {
      canUseBiometrics.value =
          await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      canUseBiometrics.value = false;
    }
  }

  Future<void> setEnabled(bool value) async {
    isEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
  }

  /// Demande l'authentification biométrique. Retourne `true` si OK ou si
  /// le verrou est désactivé / indisponible.
  Future<bool> authenticateIfRequired({String reason = 'Déverrouillez Baara'}) async {
    if (!isEnabled.value) return true;
    if (!canUseBiometrics.value) return true;
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
        ),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[Biometric] auth error: $e');
      return false;
    }
  }
}
