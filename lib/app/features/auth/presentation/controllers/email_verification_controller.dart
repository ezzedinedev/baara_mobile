import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/utils/user_facing_error.dart';
import 'package:baara/app/core/widgets/widgets.dart';

import '../../domain/repositories/i_auth_repository.dart';

/// Vérification de l'adresse email de l'utilisateur connecté.
///
/// Contrairement à l'OTP téléphone (pendant l'inscription), ce flux est
/// **authentifié** : le code part par email vers l'adresse à prouver, et au
/// succès on revient à l'écran précédent avec un résultat `true`.
class EmailVerificationController extends GetxController {
  EmailVerificationController(this._authRepository);

  final IAuthRepository _authRepository;

  final codeCtrl = TextEditingController();
  final isLoading = false.obs;
  final isResending = false.obs;
  final errorMsg = ''.obs;
  final deliveryPhase = AuthDeliveryPhase.idle.obs;
  final sendError = ''.obs;

  /// Email affiché (transmis via Get.arguments), purement informatif.
  String email = '';

  /// Secondes restantes avant de pouvoir renvoyer (le backend impose 60 s).
  final resendCountdown = 0.obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['email'] != null) {
      email = args['email'].toString();
    }
    // Envoi automatique du premier code à l'arrivée sur l'écran.
    _send(initial: true);
  }

  Future<void> _send({bool initial = false}) async {
    if (resendCountdown.value > 0 && !initial) return;
    try {
      if (!initial) isResending.value = true;
      deliveryPhase.value = AuthDeliveryPhase.sending;
      sendError.value = '';
      final api = _authRepository.sendEmailVerification();
      await Future.wait([
        api,
        if (initial) Future<void>.delayed(const Duration(milliseconds: 800)),
      ]);
      deliveryPhase.value = AuthDeliveryPhase.sent;
      _startCountdown();
      if (!initial) {
        AppToast.success(
          'Code envoyé',
          'Un nouveau code a été envoyé à votre email.',
        );
      }
    } catch (e) {
      sendError.value = userFacingError(e);
      deliveryPhase.value = AuthDeliveryPhase.failed;
      // À l'arrivée, un échec d'envoi (SMTP…) est signalé sans bloquer la saisie
      // d'un code éventuellement déjà reçu.
      if (initial) {
        errorMsg.value = userFacingError(e);
      } else {
        AppToast.error('Échec', userFacingError(e));
      }
    } finally {
      isResending.value = false;
    }
  }

  /// Renvoi manuel (bouton « Renvoyer »).
  Future<void> resend() => _send();

  Future<void> verify() async {
    final code = codeCtrl.text.trim();
    if (code.length != 6) {
      errorMsg.value = 'Le code doit comporter 6 chiffres.';
      return;
    }
    try {
      isLoading.value = true;
      errorMsg.value = '';
      await _authRepository.verifyEmail(code);
      AppHaptics.confirm();
      // Rend `true` à l'appelant (le profil rafraîchit alors l'état).
      Get.back<bool>(result: true);
      AppToast.success('Email vérifié', 'Votre adresse a été confirmée.');
    } catch (e) {
      errorMsg.value = userFacingError(e);
    } finally {
      isLoading.value = false;
    }
  }

  void _startCountdown() {
    resendCountdown.value = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (resendCountdown.value <= 1) {
        resendCountdown.value = 0;
        t.cancel();
      } else {
        resendCountdown.value--;
      }
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    codeCtrl.dispose();
    super.onClose();
  }
}
