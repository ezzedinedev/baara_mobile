import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opportune_bf/app/core/services/google_auth_service.dart';
import 'package:opportune_bf/app/core/utils/user_facing_error.dart';
import 'package:opportune_bf/app/core/utils/validators.dart';
import 'package:opportune_bf/routes/app_routes.dart';
import '../../domain/repositories/i_auth_repository.dart';

class CandidateLoginController extends GetxController {
  final IAuthRepository _authRepository;
  final GoogleAuthService _googleAuth;

  CandidateLoginController(this._authRepository, {GoogleAuthService? googleAuthService})
      : _googleAuth = googleAuthService ?? GoogleAuthService();

  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final isLoading = false.obs;
  final errorMsg = ''.obs;
  final _loginAttempts = 0.obs;
  final _loginCooldown = false.obs;
  static const int _maxAttempts = 5;
  static const Duration _cooldownDuration = Duration(seconds: 30);

  @override
  void onClose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.onClose();
  }

  Future<void> loginWithEmail() async {
    if (_loginCooldown.value) {
      errorMsg.value = 'Trop de tentatives. Réessayez dans 30s.';
      return;
    }
    final form = formKey.currentState;
    if (form == null || !form.validate()) return;

    try {
      isLoading.value = true;
      errorMsg.value = '';
      await _authRepository.loginWithEmail(emailCtrl.text.trim(), passwordCtrl.text);
      _loginAttempts.value = 0;
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      _loginAttempts.value++;
      errorMsg.value = userFacingError(e);
      if (_loginAttempts.value >= _maxAttempts) {
        _loginCooldown.value = true;
        _loginAttempts.value = 0;
        Future.delayed(_cooldownDuration, () {
          _loginCooldown.value = false;
        });
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      isLoading.value = true;
      errorMsg.value = '';
      final result = await _googleAuth.signIn();
      if (result.cancelled) return;
      if (!result.isSuccess) {
        errorMsg.value = result.error ?? 'Erreur Google';
        return;
      }
      await _authRepository.loginWithGoogle(result.idToken!, email: result.email);
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      errorMsg.value = "Échec de connexion Google";
    } finally {
      isLoading.value = false;
    }
  }

  String? validateEmail(String? value) => Validators.email(value);
  String? validatePassword(String? value) => Validators.password(value, minLength: 8);
}
