import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opportune_bf/app/core/utils/user_facing_error.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/routes/app_routes.dart';
import '../../domain/repositories/i_auth_repository.dart';

class ForgotPasswordController extends GetxController {
  ForgotPasswordController(this._authRepository);

  final IAuthRepository _authRepository;

  final phoneCtrl = TextEditingController();
  final otpCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  /// 1 = saisie du téléphone, 2 = saisie du code + nouveau mot de passe.
  final step = 1.obs;
  final isLoading = false.obs;
  final errorMsg = ''.obs;
  int _otpAttempts = 0;
  bool _otpCooldown = false;
  static const int _maxOtpAttempts = 3;
  static const Duration _otpCooldownDuration = Duration(seconds: 30);

  /// Étape 1 : envoie le code de réinitialisation au téléphone.
  Future<void> requestReset() async {
    final phone = phoneCtrl.text.trim();
    if (phone.isEmpty) {
      errorMsg.value = 'Entrez votre numéro de téléphone.';
      return;
    }
    try {
      isLoading.value = true;
      errorMsg.value = '';
      await _authRepository.forgotPassword(phone);
      step.value = 2;
      _otpAttempts = 0;
      AppToast.success(
        'Code envoyé',
        'Un code de réinitialisation a été envoyé au $phone.',
      );
    } catch (e) {
      errorMsg.value = userFacingError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Étape 2 : valide le code et applique le nouveau mot de passe.
  Future<void> confirmReset() async {
    if (_otpCooldown) {
      errorMsg.value = 'Trop de tentatives. Réessayez dans 30s.';
      return;
    }
    final otp = otpCtrl.text.trim();
    final pwd = passwordCtrl.text;
    if (otp.length != 6) {
      errorMsg.value = 'Le code doit comporter 6 chiffres.';
      return;
    }
    if (pwd.length < 8) {
      errorMsg.value = 'Le mot de passe doit faire au moins 8 caractères.';
      return;
    }
    if (pwd != confirmCtrl.text) {
      errorMsg.value = 'Les mots de passe ne correspondent pas.';
      return;
    }
    try {
      isLoading.value = true;
      errorMsg.value = '';
      await _authRepository.resetPassword(
        phone: phoneCtrl.text.trim(),
        otp: otp,
        password: pwd,
      );
      _otpAttempts = 0;
      Get.offAllNamed(AppRoutes.candidateLogin);
      AppToast.success(
        'Mot de passe réinitialisé',
        'Connectez-vous avec votre nouveau mot de passe.',
      );
    } catch (e) {
      _otpAttempts++;
      errorMsg.value = userFacingError(e);
      if (_otpAttempts >= _maxOtpAttempts) {
        _otpCooldown = true;
        _otpAttempts = 0;
        Future.delayed(_otpCooldownDuration, () {
          _otpCooldown = false;
        });
      }
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    phoneCtrl.dispose();
    otpCtrl.dispose();
    passwordCtrl.dispose();
    confirmCtrl.dispose();
    super.onClose();
  }
}
