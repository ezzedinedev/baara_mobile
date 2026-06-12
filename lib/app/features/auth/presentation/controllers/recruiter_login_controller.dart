import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opportune_bf/app/core/services/google_auth_service.dart';
import 'package:opportune_bf/app/core/utils/user_facing_error.dart';
import 'package:opportune_bf/app/core/utils/validators.dart';
import 'package:opportune_bf/routes/app_routes.dart';
import '../../domain/repositories/i_auth_repository.dart';

class RecruiterLoginController extends GetxController {
  final IAuthRepository _authRepository;
  final GoogleAuthService _googleAuth;

  RecruiterLoginController(this._authRepository,
      {GoogleAuthService? googleAuthService})
      : _googleAuth = googleAuthService ?? GoogleAuthService();

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
    if (form == null || !form.validate()) return;

    try {
      isLoading.value = true;
      errorMsg.value = '';
      await _authRepository.loginWithEmail(
          emailCtrl.text.trim(), passwordCtrl.text);
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      errorMsg.value = userFacingError(e);
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
      await _authRepository.loginWithGoogle(result.idToken!,
          email: result.email);
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      errorMsg.value = "Échec de connexion Google";
    } finally {
      isLoading.value = false;
    }
  }

  String? validateEmail(String? v) => Validators.email(v);
  String? validatePassword(String? v) => Validators.password(v, minLength: 8);
}
