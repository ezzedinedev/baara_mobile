import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../routes/app_routes.dart';

class SplashController extends GetxController {
  final progress = 0.obs;

  String get loadingMessage {
    if (progress.value < 30) {
      return 'Initialisation...';
    }
    if (progress.value < 60) {
      return 'Chargement des données...';
    }
    if (progress.value < 85) {
      return 'Préparation de votre espace...';
    }
    return 'Presque prêt...';
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
      await Future<void>.delayed(Duration(milliseconds: step.$2));
      for (int i = progress.value; i <= step.$1; i++) {
        progress.value = i;
        await Future<void>.delayed(const Duration(milliseconds: 18));
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 600));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null && token.isNotEmpty) {
      Get.offAllNamed(AppRoutes.home);
      return;
    }

    Get.offAllNamed(AppRoutes.landing);
  }
}
