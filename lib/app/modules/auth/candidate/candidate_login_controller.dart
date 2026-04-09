import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/core/constants/api_constants.dart';
import '../../../../app/core/utils/validators.dart';
import '../../../../app/data/providers/api_provider.dart';
import '../../../../routes/app_routes.dart';

class CandidateLoginController extends GetxController {
  CandidateLoginController()
      : _apiProvider = Get.find<ApiProvider>(),
        _secureStorage = const FlutterSecureStorage();

  final ApiProvider _apiProvider;
  final FlutterSecureStorage _secureStorage;

  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final isLoading = false.obs;
  final errorMsg = ''.obs;

  @override
  void onClose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.onClose();
  }

  Future<void> loginWithEmail() async {
    final form = formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    isLoading.value = true;
    errorMsg.value = '';

    try {
      final data = await _apiProvider.postJson(
        ApiConstants.loginEmail,
        {
          'email': emailCtrl.text.trim(),
          'password': passwordCtrl.text,
          'device_name': 'flutter-android',
          'user_type': 'candidate',
        },
      );

      if (data['statusCode'] == 200 && data['success'] == true) {
        await _persistSession(
          token: (data['data'] as Map<String, dynamic>)['token'] as String,
          userType: 'candidate',
        );
        Get.offAllNamed(AppRoutes.home);
        return;
      }

      errorMsg.value =
          data['message'] as String? ?? 'Identifiants incorrects.';
    } on Exception {
      errorMsg.value = 'Erreur de connexion. Vérifiez votre réseau.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginWithPhone(String phone, String pin) async {
    isLoading.value = true;
    errorMsg.value = '';

    try {
      final data = await _apiProvider.postJson(
        ApiConstants.loginPhone,
        {
          'phone': phone,
          'pin': pin,
          'device_name': 'flutter-android',
        },
      );

      if (data['statusCode'] == 200 && data['success'] == true) {
        await _persistSession(
          token: (data['data'] as Map<String, dynamic>)['token'] as String,
          userType: 'candidate',
        );
        Get.offAllNamed(AppRoutes.home);
        return;
      }

      errorMsg.value = data['message'] as String? ?? 'Erreur de connexion.';
    } on Exception {
      errorMsg.value = 'Erreur réseau. Réessayez.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginWithGoogle() async {
    Get.snackbar(
      'Connexion Google',
      'Connexion Google en cours d\'intégration.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  String? validateEmail(String? value) => Validators.email(value);

  String? validatePassword(String? value) =>
      Validators.password(value, minLength: 4);

  Future<void> _persistSession({
    required String token,
    required String userType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_type', userType);
    await _secureStorage.write(key: 'auth_token', value: token);
  }
}
