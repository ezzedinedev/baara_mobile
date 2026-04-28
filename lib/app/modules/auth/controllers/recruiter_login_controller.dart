import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/core/constants/api_constants.dart';
import '../../../../app/core/services/auth_token_store.dart';
import '../../../../app/core/services/google_auth_service.dart';
import '../../../../app/core/utils/validators.dart';
import '../../../../app/core/network/api_provider.dart';
import '../../../../routes/app_routes.dart';

class RecruiterLoginController extends GetxController {
  RecruiterLoginController({GoogleAuthService? googleAuthService})
      : _apiProvider = Get.find<ApiProvider>(),
        _tokenStore = const AuthTokenStore(),
        _googleAuth = googleAuthService ?? GoogleAuthService();

  final ApiProvider _apiProvider;
  final AuthTokenStore _tokenStore;
  final GoogleAuthService _googleAuth;

  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final obscurePass = true.obs;

  final isLoading = false.obs;
  final errorMsg = ''.obs;

  @override
  void onClose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.onClose();
  }

  void togglePassword() => obscurePass.toggle();

  Future<void> login() async {
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
          'device_name': ApiConstants.authDeviceName,
          'user_type': 'employer',
        },
      );

      final token = _extractToken(data);
      if (data['statusCode'] == 200 &&
          data['success'] == true &&
          token != null) {
        await _persistSession(
          token: token,
          userType: 'employer',
        );
        Get.offAllNamed(AppRoutes.home);
        return;
      }

      errorMsg.value = _extractApiMessage(
        data,
        fallback: 'Identifiants incorrects.',
      );
    } on Exception catch (error) {
      final message = error.toString();
      if (message.contains('Impossible de joindre l\'API')) {
        errorMsg.value = 'Connexion au service impossible pour le moment.';
      } else {
        errorMsg.value = 'Erreur de connexion. Verifiez votre reseau.';
      }
    } finally {
      passwordCtrl.clear();
      isLoading.value = false;
    }
  }

  Future<void> loginWithGoogle() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMsg.value = '';

    try {
      final googleResult = await _googleAuth.signIn();

      if (googleResult.cancelled) {
        return;
      }
      if (!googleResult.isSuccess) {
        errorMsg.value =
            googleResult.error ?? 'Connexion Google indisponible.';
        return;
      }

      final data = await _apiProvider.postJson(
        ApiConstants.loginGoogle,
        {
          'id_token': googleResult.idToken,
          'user_type': 'employer',
          'device_name': ApiConstants.authDeviceName,
          if (googleResult.email != null) 'email': googleResult.email,
        },
      );

      final token = _extractToken(data);
      if (data['statusCode'] == 200 &&
          data['success'] == true &&
          token != null) {
        await _persistSession(token: token, userType: 'employer');
        Get.offAllNamed(AppRoutes.home);
        return;
      }

      errorMsg.value = _extractApiMessage(
        data,
        fallback: 'Connexion Google refusée par le serveur.',
      );
      await _googleAuth.signOut();
    } on Exception catch (error) {
      final message = error.toString();
      if (message.contains('Impossible de joindre l\'API')) {
        errorMsg.value = 'Connexion au service impossible pour le moment.';
      } else {
        errorMsg.value = 'Erreur de connexion Google. Réessayez.';
      }
      await _googleAuth.signOut();
    } finally {
      isLoading.value = false;
    }
  }

  String? validateEmail(String? value) => Validators.email(value);

  String? validatePassword(String? value) => Validators.password(value);

  Future<void> _persistSession({
    required String token,
    required String userType,
  }) async {
    await _tokenStore.saveSession(token: token, userType: userType);
  }

  String? _extractToken(Map<String, dynamic> data) {
    final payload = data['data'];
    if (payload is Map<String, dynamic>) {
      final token = payload['token'];
      if (token is String && token.trim().isNotEmpty) {
        return token;
      }
    }

    final token = data['token'];
    if (token is String && token.trim().isNotEmpty) {
      return token;
    }
    return null;
  }

  String _extractApiMessage(
    Map<String, dynamic> data, {
    required String fallback,
  }) {
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }

    final errors = data['errors'];
    if (errors is Map<String, dynamic>) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }

    return fallback;
  }
}
