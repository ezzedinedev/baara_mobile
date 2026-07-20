import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jobaway/app/core/utils/user_facing_error.dart';
import 'package:jobaway/app/core/widgets/widgets.dart';
import 'package:jobaway/routes/app_routes.dart';
import '../../domain/repositories/i_auth_repository.dart';

class ForgotPasswordController extends GetxController {
  ForgotPasswordController(this._authRepository);

  final IAuthRepository _authRepository;

  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final otpCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  /// Identifiant choisi pour la réinitialisation : 'phone' (défaut) ou 'email'.
  final mode = 'phone'.obs;
  void setMode(String m) {
    if (mode.value == m) return;
    mode.value = m;
    errorMsg.value = '';
  }

  String? validateEmail(String? value) {
    final s = (value ?? '').trim();
    if (s.isEmpty) return 'Entrez votre email';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) {
      return 'Email invalide';
    }
    return null;
  }

  /// Pays / indicatif du champ téléphone (défaut Burkina Faso). Aligné sur
  /// l'inscription/connexion : le drapeau fixe l'indicatif, `phoneCtrl` = local.
  final selectedCountryIso = 'BF'.obs;
  PhoneCountry get selectedCountry =>
      PhoneCountry.byIso(selectedCountryIso.value);
  void selectCountry(String isoCode) => selectedCountryIso.value = isoCode;

  /// Numéro complet au format international (ex. `+22670000000`) envoyé à l'API.
  String get fullPhone {
    final digits = phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    return '${selectedCountry.dialCode}$digits';
  }

  String? validatePhone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Entrez votre numéro de téléphone';
    if (digits.length < 6 || digits.length > 12) {
      return 'Numéro de téléphone invalide';
    }
    return null;
  }

  /// 1 = saisie du téléphone, 2 = saisie du code + nouveau mot de passe.
  final step = 1.obs;
  final isLoading = false.obs;
  final errorMsg = ''.obs;
  int _otpAttempts = 0;
  bool _otpCooldown = false;
  static const int _maxOtpAttempts = 3;
  static const Duration _otpCooldownDuration = Duration(seconds: 30);

  /// Étape 1 : envoie le code de réinitialisation (email ou téléphone).
  Future<void> requestReset() async {
    final isEmail = mode.value == 'email';
    final error = isEmail ? validateEmail(emailCtrl.text) : validatePhone(phoneCtrl.text);
    if (error != null) {
      errorMsg.value = error;
      return;
    }
    try {
      isLoading.value = true;
      errorMsg.value = '';
      await _authRepository.forgotPassword(
        email: isEmail ? emailCtrl.text.trim() : null,
        phone: isEmail ? null : fullPhone,
      );
      step.value = 2;
      _otpAttempts = 0;
      AppToast.success(
        'Code envoyé',
        'Un code de réinitialisation a été envoyé par email.',
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
      final isEmail = mode.value == 'email';
      await _authRepository.resetPassword(
        email: isEmail ? emailCtrl.text.trim() : null,
        phone: isEmail ? null : fullPhone,
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
    emailCtrl.dispose();
    otpCtrl.dispose();
    passwordCtrl.dispose();
    confirmCtrl.dispose();
    super.onClose();
  }
}
