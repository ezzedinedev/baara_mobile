import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:baara/app/core/services/onboarding_service.dart';
import 'package:baara/app/core/utils/user_facing_error.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import '../../domain/repositories/i_auth_repository.dart';

class OtpVerificationController extends GetxController {
  OtpVerificationController(this._authRepository);

  final IAuthRepository _authRepository;

  final otpCtrl = TextEditingController();
  final isLoading = false.obs;
  final isResending = false.obs;
  final errorMsg = ''.obs;
  final deliveryPhase = AuthDeliveryPhase.idle.obs;
  final sendError = ''.obs;

  /// Numéro rattaché au compte : sert de **clé API** (le serveur indexe les
  /// codes OTP sur le téléphone), pas de canal de livraison.
  String phone = '';

  /// Email de destination : le code est livré **par email** côté serveur.
  /// Utilisé pour l'affichage et les messages, pas pour les appels API.
  String email = '';

  /// Email affiché à l'utilisateur (canal de livraison du code OTP).
  String get codeDestination => email.isNotEmpty ? email : phone;

  /// Libellé principal pour l'écran OTP (toujours orienté email si connu).
  String get deliveryExplanation {
    if (email.isNotEmpty) {
      return 'Un code à 6 chiffres a été envoyé par email à $email.';
    }
    return 'Un code à 6 chiffres vous a été envoyé par email.';
  }

  /// Précision sur le rôle du téléphone (clé API côté serveur).
  String? get phoneSecurityNote {
    if (phone.isEmpty || email.isEmpty) return null;
    return 'Votre numéro ($phone) sert uniquement à sécuriser votre compte — le code arrive toujours par email.';
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      if (args['phone'] != null) phone = args['phone'].toString();
      if (args['email'] != null) email = args['email'].toString();
    }
    // Déclenche l'envoi du code dès l'arrivée sur l'écran (silencieux).
    if (phone.isNotEmpty) {
      _sendCode(initial: true);
    }
  }

  Future<void> _sendCode({bool initial = false}) async {
    if (phone.isEmpty) return;
    try {
      if (!initial) isResending.value = true;
      deliveryPhase.value = AuthDeliveryPhase.sending;
      sendError.value = '';
      await _authRepository.resendOtp(phone);
      deliveryPhase.value = AuthDeliveryPhase.sent;
      if (!initial) {
        AppToast.success(
            'Code envoyé', 'Un nouveau code a été envoyé à $codeDestination.');
      }
    } catch (e) {
      sendError.value = userFacingError(e);
      deliveryPhase.value = AuthDeliveryPhase.failed;
      if (!initial) AppToast.error('Échec', sendError.value);
    } finally {
      isResending.value = false;
    }
  }

  /// Renvoi manuel du code (bouton "Renvoyer").
  Future<void> resend() => _sendCode();

  Future<void> verifyOtp() async {
    // Évite le double appel (auto-submit sur 6 chiffres + bouton « Vérifier »)
    // qui consommerait deux fois le quota anti-bruteforce du serveur.
    if (isLoading.value) return;
    final code = otpCtrl.text.trim();
    if (code.length != 6) {
      errorMsg.value = 'Le code doit comporter 6 chiffres.';
      return;
    }
    if (phone.isEmpty) {
      errorMsg.value = 'Numéro introuvable, recommencez l\'inscription.';
      return;
    }
    try {
      isLoading.value = true;
      errorMsg.value = '';
      await _authRepository.verifyOtp(phone: phone, otp: code);
      final onboarding = Get.find<OnboardingService>();
      await onboarding.navigateAfterAuth();
      AppToast.success('Compte vérifié', 'Bienvenue sur Baara.bf !');
    } catch (e) {
      errorMsg.value = userFacingError(e);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    otpCtrl.dispose();
    super.onClose();
  }
}
