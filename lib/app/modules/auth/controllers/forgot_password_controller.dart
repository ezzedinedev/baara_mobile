import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_provider.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../../routes/app_routes.dart';

/// Controller du flow Mot de passe oublie en 2 etapes :
///   1. Saisie du telephone → POST /auth/forgot-password → SMS OTP
///   2. Saisie OTP + nouveau password → POST /auth/reset-password
///
/// Le state `phone` survit entre les 2 ecrans pour ne pas re-saisir
/// le numero, et le timer de cooldown empêche le spam de l'envoi OTP.
class ForgotPasswordController extends GetxController {
  ForgotPasswordController({ApiProvider? apiProvider})
      : _apiProvider = apiProvider ?? Get.find<ApiProvider>();

  final ApiProvider _apiProvider;

  // ── State partagé entre étape 1 et étape 2 ────────────
  /// Téléphone saisi à l'étape 1, transmis à l'étape 2.
  final phone = ''.obs;

  // ── Étape 1 : demande de l'OTP ─────────────────────────
  final phoneCtrl = TextEditingController();
  final isRequesting = false.obs;
  final requestError = ''.obs;
  final cooldownSecondsLeft = 0.obs;
  Timer? _cooldownTimer;

  // ── Étape 2 : reset du password ────────────────────────
  final otpCtrl = TextEditingController();
  final newPasswordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();
  final obscureNewPassword = true.obs;
  final obscureConfirmPassword = true.obs;
  final isResetting = false.obs;
  final resetError = ''.obs;
  final formKey = GlobalKey<FormState>();

  @override
  void onClose() {
    _cooldownTimer?.cancel();
    phoneCtrl.dispose();
    otpCtrl.dispose();
    newPasswordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    super.onClose();
  }

  /// Envoie un OTP au telephone saisi. En succes, route vers l'ecran 2
  /// et demarre le cooldown 60s pour le bouton "Renvoyer".
  Future<void> requestReset() async {
    final raw = phoneCtrl.text.trim();
    if (raw.isEmpty) {
      requestError.value = 'Saisissez votre numéro de téléphone.';
      return;
    }

    isRequesting.value = true;
    requestError.value = '';

    try {
      final response = await _apiProvider.postJson(
        ApiConstants.forgotPassword,
        {'phone': raw},
      );

      final success = response['success'] == true;
      if (!success) {
        requestError.value = _extractApiMessage(
          response,
          fallback: 'Impossible d\'envoyer le code. Réessayez.',
        );
        AppHaptics.error();
        return;
      }

      // Sauvegarde le phone normalisé pour l'étape 2 + démarre le cooldown.
      phone.value = raw;
      _startCooldown();
      AppHaptics.success();
      AppToast.success(
        'Code envoyé',
        'Un SMS contenant un code à 6 chiffres vient d\'être envoyé.',
      );
      Get.toNamed(AppRoutes.forgotPasswordReset);
    } on Exception {
      requestError.value = 'Connexion impossible. Vérifiez votre réseau.';
      AppHaptics.error();
    } finally {
      isRequesting.value = false;
    }
  }

  /// Renvoyer l'OTP (sans changer d'écran). Disponible uniquement après
  /// expiration du cooldown.
  Future<void> resendOtp() async {
    if (cooldownSecondsLeft.value > 0 || phone.value.isEmpty) return;

    isRequesting.value = true;
    try {
      final response = await _apiProvider.postJson(
        ApiConstants.forgotPassword,
        {'phone': phone.value},
      );
      if (response['success'] == true) {
        _startCooldown();
        AppToast.info(
          'Code renvoyé',
          'Un nouveau code vient d\'être envoyé.',
        );
      } else {
        AppToast.error(
          'Renvoi impossible',
          _extractApiMessage(response, fallback: 'Réessayez dans un instant.'),
        );
      }
    } on Exception {
      AppToast.error('Connexion impossible', 'Vérifiez votre réseau.');
    } finally {
      isRequesting.value = false;
    }
  }

  /// Valide l'OTP et change le password. En succès, redirige vers le
  /// login candidat avec un toast de confirmation.
  Future<void> resetPassword() async {
    final form = formKey.currentState;
    if (form == null || !form.validate()) return;

    final otp = otpCtrl.text.trim();
    final newPassword = newPasswordCtrl.text;
    final confirm = confirmPasswordCtrl.text;

    if (otp.length != 6) {
      resetError.value = 'Le code doit faire 6 chiffres.';
      return;
    }
    if (newPassword != confirm) {
      resetError.value = 'Les mots de passe ne correspondent pas.';
      return;
    }
    if (newPassword.length < 8) {
      resetError.value = 'Le mot de passe doit faire au moins 8 caractères.';
      return;
    }

    isResetting.value = true;
    resetError.value = '';

    try {
      final response = await _apiProvider.postJson(
        ApiConstants.resetPassword,
        {
          'phone': phone.value,
          'otp': otp,
          'password': newPassword,
          'password_confirmation': confirm,
        },
      );

      final success = response['success'] == true;
      if (!success) {
        resetError.value = _extractApiMessage(
          response,
          fallback: 'Code incorrect ou expiré. Demandez un nouveau code.',
        );
        AppHaptics.error();
        return;
      }

      AppHaptics.success();
      AppToast.success(
        'Mot de passe modifié',
        'Connectez-vous avec votre nouveau mot de passe.',
      );
      // Reset complet du flow et retour au login candidat.
      _resetState();
      Get.offAllNamed(AppRoutes.candidateLogin);
    } on Exception {
      resetError.value = 'Connexion impossible. Vérifiez votre réseau.';
      AppHaptics.error();
    } finally {
      isResetting.value = false;
    }
  }

  void toggleNewPasswordVisibility() => obscureNewPassword.toggle();
  void toggleConfirmPasswordVisibility() => obscureConfirmPassword.toggle();

  void _startCooldown() {
    _cooldownTimer?.cancel();
    cooldownSecondsLeft.value = 60;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (cooldownSecondsLeft.value <= 0) {
        t.cancel();
        return;
      }
      cooldownSecondsLeft.value--;
    });
  }

  void _resetState() {
    phoneCtrl.clear();
    otpCtrl.clear();
    newPasswordCtrl.clear();
    confirmPasswordCtrl.clear();
    phone.value = '';
    requestError.value = '';
    resetError.value = '';
    cooldownSecondsLeft.value = 0;
    _cooldownTimer?.cancel();
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
        if (value is List && value.isNotEmpty) return value.first.toString();
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
    }
    return fallback;
  }
}

class ForgotPasswordBinding extends Bindings {
  @override
  void dependencies() {
    // Permanent pour que le state (phone) survive entre les 2 ecrans.
    if (!Get.isRegistered<ForgotPasswordController>()) {
      Get.put<ForgotPasswordController>(
        ForgotPasswordController(),
        permanent: true,
      );
    }
  }
}
