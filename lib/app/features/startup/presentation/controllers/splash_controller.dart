import 'dart:async';
import 'package:get/get.dart';
import 'package:baara/app/core/services/biometric_service.dart';
import 'package:baara/app/core/services/auth_token_store.dart';
import 'package:baara/app/core/services/onboarding_service.dart';
import 'package:baara/app/core/services/post_auth_bootstrap.dart';
import 'package:baara/app/core/utils/candidate_access.dart';
import 'package:baara/app/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:baara/routes/app_routes.dart';

class SplashController extends GetxController {
  SplashController(this._tokenStore, this._authRepository);

  final AuthTokenStore _tokenStore;
  final IAuthRepository _authRepository;
  final progress = 0.obs;
  Timer? _loadingTimer;
  Completer<void>? _delayCompleter;
  bool _isClosed = false;
  bool _routingStarted = false;

  static const _fullSteps = <(int, int)>[
    (15, 400),
    (32, 300),
    (48, 250),
    (65, 350),
    (78, 200),
    (89, 300),
    (95, 200),
    (100, 150),
  ];

  static const _fastSteps = <(int, int)>[
    (35, 120),
    (70, 120),
    (100, 100),
  ];

  String get loadingMessage {
    if (progress.value < 30) return 'Initialisation...';
    if (progress.value < 60) return 'Chargement des données...';
    if (progress.value < 85) return 'Préparation de votre espace...';
    return 'Presque prêt...';
  }

  @override
  void onInit() {
    super.onInit();
    _startLoading();
  }

  Future<void> _startLoading() async {
    final token = await _tokenStore.readTokenOrNull();
    final hasSession = token != null && token.isNotEmpty;

    if (hasSession) {
      // Retour utilisateur : routage en parallèle + animation courte (~340 ms).
      unawaited(_routeAfterSplash());
      await _runCosmeticSteps(_fastSteps);
      await _delay(const Duration(milliseconds: 200));
      return;
    }

    await _runCosmeticSteps(_fullSteps);
    await _delay(const Duration(milliseconds: 600));
    if (_isClosed) return;
    await _routeAfterSplash();
  }

  Future<void> _runCosmeticSteps(List<(int, int)> steps) async {
    for (final step in steps) {
      await _delay(Duration(milliseconds: step.$2));
      if (_isClosed) return;
      for (int i = progress.value; i <= step.$1; i++) {
        progress.value = i;
        await _delay(const Duration(milliseconds: 18));
        if (_isClosed) return;
      }
    }
  }

  Future<void> _delay(Duration duration) {
    _loadingTimer?.cancel();
    final completer = Completer<void>();
    _delayCompleter = completer;
    _loadingTimer = Timer(duration, () {
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }

  void skip() {
    if (_isClosed) return;
    _loadingTimer?.cancel();
    final c = _delayCompleter;
    if (c != null && !c.isCompleted) c.complete();
    progress.value = 100;
    unawaited(_routeAfterSplash());
  }

  Future<void> _routeAfterSplash() async {
    if (_routingStarted) return;
    _routingStarted = true;

    final token = await _tokenStore.readTokenOrNull();
    if (token == null || token.isEmpty) {
      if (_isClosed) return;
      Get.offAllNamed(AppRoutes.landing);
      return;
    }

    final storedType = await _tokenStore.readUserType();
    if (!CandidateAccess.isAllowed(storedType)) {
      await _tokenStore.clearSession();
      if (_isClosed) return;
      Get.offAllNamed(AppRoutes.landing);
      return;
    }

    try {
      await _authRepository.getMe();
      if (_isClosed) return;

      if (Get.isRegistered<BiometricService>()) {
        final ok = await Get.find<BiometricService>().authenticateIfRequired();
        if (!ok) {
          await _tokenStore.clearSession();
          if (_isClosed) return;
          Get.offAllNamed(AppRoutes.landing);
          return;
        }
      }

      await _routeAuthenticatedHome();
    } on CandidateAccessDeniedException {
      await _tokenStore.clearSession();
      if (_isClosed) return;
      Get.offAllNamed(AppRoutes.landing);
    } catch (_) {
      if (_isClosed) return;

      if (Get.isRegistered<BiometricService>()) {
        final ok = await Get.find<BiometricService>().authenticateIfRequired();
        if (!ok) {
          await _tokenStore.clearSession();
          if (_isClosed) return;
          Get.offAllNamed(AppRoutes.landing);
          return;
        }
      }

      await _routeAuthenticatedHome();
    }
  }

  Future<void> _routeAuthenticatedHome() async {
    await PostAuthBootstrap.syncPushToken();
    if (_isClosed) return;
    final onboarding = Get.find<OnboardingService>();
    if (!await onboarding.isCompleted()) {
      Get.offAllNamed(AppRoutes.onboarding);
    } else {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  @override
  void onClose() {
    _isClosed = true;
    _loadingTimer?.cancel();
    final completer = _delayCompleter;
    if (completer != null && !completer.isCompleted) completer.complete();
    super.onClose();
  }
}
