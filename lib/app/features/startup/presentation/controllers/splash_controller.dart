import 'dart:async';
import 'package:get/get.dart';
import 'package:opportune_bf/app/core/services/auth_token_store.dart';
import 'package:opportune_bf/routes/app_routes.dart';

class SplashController extends GetxController {
  SplashController(this._tokenStore);

  final AuthTokenStore _tokenStore;
  final progress = 0.obs;
  Timer? _loadingTimer;
  Completer<void>? _delayCompleter;
  bool _isClosed = false;

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
    const steps = <(int, int)>[
      (15, 400), (32, 300), (48, 250), (65, 350),
      (78, 200), (89, 300), (95, 200), (100, 150),
    ];

    for (final step in steps) {
      await _delay(Duration(milliseconds: step.$2));
      if (_isClosed) return;
      for (int i = progress.value; i <= step.$1; i++) {
        progress.value = i;
        await _delay(const Duration(milliseconds: 18));
        if (_isClosed) return;
      }
    }

    await _delay(const Duration(milliseconds: 600));
    if (_isClosed) return;
    await _routeAfterSplash();
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
    final token = await _tokenStore.readTokenOrNull();
    if (_isClosed) return;
    Get.offAllNamed(
      token == null || token.isEmpty ? AppRoutes.landing : AppRoutes.home,
    );
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
