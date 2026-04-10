import 'dart:async';

import 'package:get/get.dart';

import '../../../routes/app_routes.dart';

class SplashController extends GetxController {
  final progress = 0.obs;
  Timer? _loadingTimer;
  Completer<void>? _delayCompleter;
  bool _isClosed = false;

  String get loadingMessage {
    if (progress.value < 30) {
      return 'Initialisation...';
    }
    if (progress.value < 60) {
      return 'Chargement des donnees...';
    }
    if (progress.value < 85) {
      return 'Preparation de votre espace...';
    }
    return 'Presque pret...';
  }

  @override
  void onInit() {
    super.onInit();
    _startLoading();
  }

  Future<void> _startLoading() async {
    const steps = <(int, int)>[
      (15, 400),
      (32, 300),
      (48, 250),
      (65, 350),
      (78, 200),
      (89, 300),
      (95, 200),
      (100, 150),
    ];

    for (final step in steps) {
      await _delay(Duration(milliseconds: step.$2));
      if (_isClosed) {
        return;
      }
      for (int i = progress.value; i <= step.$1; i++) {
        progress.value = i;
        await _delay(const Duration(milliseconds: 18));
        if (_isClosed) {
          return;
        }
      }
    }

    await _delay(const Duration(milliseconds: 600));
    if (_isClosed) {
      return;
    }
    Get.offAllNamed(
      AppRoutes.landing,
    );
  }

  Future<void> _delay(Duration duration) {
    _loadingTimer?.cancel();
    final completer = Completer<void>();
    _delayCompleter = completer;
    _loadingTimer = Timer(duration, () {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    return completer.future;
  }

  @override
  void onClose() {
    _isClosed = true;
    _loadingTimer?.cancel();
    final completer = _delayCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    super.onClose();
  }
}
