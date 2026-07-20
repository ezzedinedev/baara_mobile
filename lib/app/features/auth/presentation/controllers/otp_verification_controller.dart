import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jobaway/app/core/utils/user_facing_error.dart';
import 'package:jobaway/app/core/widgets/widgets.dart';
import 'package:jobaway/routes/app_routes.dart';
import '../../domain/repositories/i_auth_repository.dart';

class OtpVerificationController extends GetxController {
  OtpVerificationController(this._authRepository);

  final IAuthRepository _authRepository;

  final otpCtrl = TextEditingController();
  final isLoading = false.obs;
  final isResending = false.obs;
  final errorMsg = ''.obs;

  /// Numéro rattaché au compte : sert de **clé API** (le serveur indexe les
  /// codes OTP sur le téléphone), pas de canal de livraison.
  String phone = '';

  /// Email de destination : le code est livré **par email** côté serveur.
  /// Utilisé pour l'affichage et les messages, pas pour les appels API.
  String email = '';

  /// Destination affichée à l'utilisateur (email de préférence).
  String get codeDestination => email.isNotEmpty ? email : phone;

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
      await _authRepository.resendOtp(phone);
      if (!initial) {
        AppToast.success(
            'Code envoyé', 'Un nouveau code a été envoyé à $codeDestination.');
      }
    } catch (e) {
      if (!initial) AppToast.error('Échec', userFacingError(e));
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
      Get.offAllNamed(AppRoutes.candidateLogin);
      AppToast.success('Compte vérifié', 'Connectez-vous pour continuer.');
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
