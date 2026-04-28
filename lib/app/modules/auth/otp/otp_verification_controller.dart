import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/network/api_provider.dart';
import '../../../../routes/app_routes.dart';
import '../../../core/widgets/widgets.dart';

/// Controller pour la vérification d'un code OTP à 6 chiffres.
///
/// Arguments attendus via `Get.arguments` :
///   - `phone` (obligatoire) : identifiant utilisé pour l'OTP
///   - `redirectTo` (optionnel, défaut = [AppRoutes.home]) : route après succès
///
/// Note : le backend ne supporte que l'OTP par téléphone (POST /auth/otp/verify
/// exige `phone`). Le flow email a été retiré pour rester aligné.
class OtpVerificationController extends GetxController {
  OtpVerificationController({ApiProvider? apiProvider})
      : _apiProvider = apiProvider ?? Get.find<ApiProvider>();

  final ApiProvider _apiProvider;

  // Args dérivés de `Get.arguments`.
  late final String _phone;
  late final String _redirectTo;

  // Un TextField invisible dans l'écran capture la saisie clavier native.
  // Son contenu alimente `codeDigits` via [onCodeChanged].
  final hiddenTextCtrl = TextEditingController();
  final hiddenFocus = FocusNode();

  // État réactif.
  final codeDigits = <String>[].obs;
  final focusIndex = 0.obs;
  final isVerifying = false.obs;
  final isResending = false.obs;
  final errorMsg = ''.obs;
  final showSuccess = false.obs;
  final resendSecondsLeft = 60.obs;

  Timer? _resendTimer;

  String get currentCode => codeDigits.join();

  @override
  void onInit() {
    super.onInit();
    final args = (Get.arguments as Map?) ?? const <String, dynamic>{};
    _phone = args['phone']?.toString() ?? '';
    _redirectTo = args['redirectTo']?.toString() ?? AppRoutes.home;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      hiddenFocus.requestFocus();
    });

    _startResendCountdown();
  }

  @override
  void onClose() {
    _resendTimer?.cancel();
    hiddenTextCtrl.dispose();
    hiddenFocus.dispose();
    super.onClose();
  }

  /// Réagit à la saisie clavier du TextField invisible.
  /// Ne garde que les chiffres, cap à 6 caractères.
  void onCodeChanged(String raw) {
    final clean = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final truncated = clean.length > 6 ? clean.substring(0, 6) : clean;

    codeDigits.value = truncated.split('');
    focusIndex.value = codeDigits.length.clamp(0, 5);
    errorMsg.value = '';

    // Remet le TextField sur la valeur nettoyée si l'utilisateur a collé
    // du texte invalide.
    if (hiddenTextCtrl.text != truncated) {
      hiddenTextCtrl.value = TextEditingValue(
        text: truncated,
        selection: TextSelection.collapsed(offset: truncated.length),
      );
    }

    if (codeDigits.length == 6 && !isVerifying.value) {
      HapticFeedback.selectionClick();
      verify();
    }
  }

  void requestFocusAt(int index) {
    focusIndex.value = index.clamp(0, 5);
    hiddenFocus.requestFocus();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    resendSecondsLeft.value = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendSecondsLeft.value <= 0) {
        timer.cancel();
        return;
      }
      resendSecondsLeft.value--;
    });
  }

  Future<void> verify() async {
    if (currentCode.length != 6 || isVerifying.value) return;
    if (_phone.isEmpty) {
      errorMsg.value = 'Session invalide. Recommencez l\'inscription.';
      return;
    }

    isVerifying.value = true;
    errorMsg.value = '';

    try {
      final payload = <String, dynamic>{
        'otp': currentCode,
        'phone': _phone,
      };
      final response =
          await _apiProvider.postJson(ApiConstants.otpVerify, payload);

      final success = response['success'] == true;
      if (!success) {
        errorMsg.value = response['message']?.toString() ??
            'Code invalide ou expiré.';
        _clearCode();
        AppHaptics.error();
        return;
      }

      AppHaptics.success();
      showSuccess.value = true;
      await Future<void>.delayed(const Duration(milliseconds: 900));
      Get.offAllNamed(_redirectTo);
    } on Exception {
      errorMsg.value = 'Connexion impossible. Réessayez.';
      AppHaptics.error();
    } finally {
      isVerifying.value = false;
    }
  }

  Future<void> resend() async {
    if (resendSecondsLeft.value > 0 || isResending.value) return;
    if (_phone.isEmpty) return;

    isResending.value = true;
    try {
      await _apiProvider.postJson(
        ApiConstants.otpResend,
        {'phone': _phone},
      );
      _clearCode();
      _startResendCountdown();
      AppToast.success(
        'Code renvoyé',
        'Un nouveau code vient d\'être envoyé.',
      );
    } on Exception {
      errorMsg.value = 'Envoi impossible. Réessayez dans un instant.';
      AppHaptics.error();
    } finally {
      isResending.value = false;
    }
  }

  void _clearCode() {
    codeDigits.clear();
    hiddenTextCtrl.clear();
    focusIndex.value = 0;
  }
}

class OtpVerificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OtpVerificationController>(
      () => OtpVerificationController(),
    );
  }
}
