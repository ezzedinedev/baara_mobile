import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:baara/app/core/widgets/app_lock_screen.dart';
import 'package:baara/routes/app_routes.dart';

import 'auth_token_store.dart';

/// Verrou de l'app par empreinte, visage ou code du téléphone.
///
/// Demandé au démarrage (splash) et au retour dans l'app après
/// [_relockAfter] en arrière-plan. Un échec ou une annulation n'ouvre jamais
/// la session : l'écran [AppLockScreen] reste affiché jusqu'au déverrouillage
/// ou jusqu'à ce que l'utilisateur choisisse de se déconnecter.
class BiometricService extends GetxService with WidgetsBindingObserver {
  static const _prefKey = 'pref_biometric_lock';
  static const _relockAfter = Duration(seconds: 30);

  final LocalAuthentication _auth = LocalAuthentication();
  final isEnabled = false.obs;
  final canUseBiometrics = false.obs;

  /// Préférences lues : le splash attend ce futur, sinon il verrait le verrou
  /// désactivé simplement parce que la lecture n'est pas finie.
  late final Future<void> ready = _hydrate();

  /// Code de la dernière erreur d'authentification (ex. PasscodeNotSet).
  String? lastErrorCode;

  /// Le téléphone n'a ni code, ni schéma, ni empreinte : rien à vérifier.
  bool get deviceHasNoLock => const {
        'PasscodeNotSet',
        'NotEnrolled',
        'NotAvailable',
      }.contains(lastErrorCode);

  DateTime? _backgroundedAt;
  bool _authInProgress = false;
  bool _lockShown = false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    unawaited(ready);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
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

  bool get _active => isEnabled.value && canUseBiometrics.value;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // La fenêtre d'empreinte met elle-même l'app en pause : on l'ignore.
    if (_authInProgress) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _backgroundedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final since = _backgroundedAt;
      _backgroundedAt = null;
      if (since == null || !_active) return;
      if (DateTime.now().difference(since) < _relockAfter) return;
      unawaited(_lockOnResume());
    }
  }

  Future<void> _lockOnResume() async {
    // Pas de session (landing, connexion) : rien à protéger.
    final token = await const AuthTokenStore().readTokenOrNull();
    if (token == null) return;
    if (Get.currentRoute == AppRoutes.splash) return;
    final unlocked = await requireUnlock();
    if (!unlocked) await _logout();
  }

  Future<void> _logout() async {
    await const AuthTokenStore().clearSession();
    Get.offAllNamed(AppRoutes.landing);
  }

  Future<void> setEnabled(bool value) async {
    isEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
  }

  /// Active le verrou seulement si l'utilisateur réussit à s'authentifier :
  /// on ne doit pas pouvoir activer un verrou qu'on ne saurait pas ouvrir.
  Future<bool> enableWithConfirmation() async {
    final ok = await authenticate(
      reason: 'Confirmez votre identité pour activer le verrou',
    );
    if (ok) await setEnabled(true);
    return ok;
  }

  /// Fenêtre système d'authentification. `false` si annulée ou en échec.
  Future<bool> authenticate({String reason = 'Déverrouillez Baara'}) async {
    _authInProgress = true;
    lastErrorCode = null;
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (e) {
      lastErrorCode = e.code;
      if (kDebugMode) debugPrint('[Biometric] auth error: ${e.code} ${e.message}');
      return false;
    } finally {
      _authInProgress = false;
      _backgroundedAt = null;
    }
  }

  /// Affiche l'écran verrouillé si le verrou est actif. `true` une fois
  /// déverrouillé, `false` si l'utilisateur choisit de se déconnecter.
  Future<bool> requireUnlock() async {
    await ready;
    if (!_active) return true;
    if (_lockShown) return true;
    _lockShown = true;
    try {
      final result = await Get.to<bool>(
        () => const AppLockScreen(),
        fullscreenDialog: true,
        popGesture: false,
        transition: Transition.fadeIn,
      );
      return result ?? false;
    } finally {
      _lockShown = false;
    }
  }
}
