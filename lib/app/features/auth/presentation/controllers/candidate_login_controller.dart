import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:baara/app/core/services/google_auth_service.dart';
import 'package:baara/app/core/services/onboarding_service.dart';
import 'package:baara/app/core/utils/candidate_access.dart';
import 'package:baara/app/core/utils/user_facing_error.dart';
import 'package:baara/app/core/utils/validators.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import '../../domain/repositories/i_auth_repository.dart';

class CandidateLoginController extends GetxController {
  final IAuthRepository _authRepository;
  final GoogleAuthService _googleAuth;

  CandidateLoginController(this._authRepository,
      {GoogleAuthService? googleAuthService})
      : _googleAuth = googleAuthService ?? GoogleAuthService();

  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  /// Méthode de connexion choisie : 'email' (défaut) ou 'phone'.
  final loginMode = 'email'.obs;

  /// Pays / indicatif du champ téléphone (défaut Burkina Faso). Aligné sur
  /// l'inscription : le drapeau fixe l'indicatif, `phoneCtrl` = partie locale.
  final selectedCountryIso = 'BF'.obs;
  PhoneCountry get selectedCountry =>
      PhoneCountry.byIso(selectedCountryIso.value);
  void selectCountry(String isoCode) => selectedCountryIso.value = isoCode;

  /// Numéro complet au format international (ex. `+22670000000`) envoyé à l'API.
  String get fullPhone {
    final digits = phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    return '${selectedCountry.dialCode}$digits';
  }

  final isLoading = false.obs;
  final errorMsg = ''.obs;
  final _loginAttempts = 0.obs;
  final _loginCooldown = false.obs;
  static const int _maxAttempts = 5;
  static const Duration _cooldownDuration = Duration(seconds: 30);

  @override
  void onClose() {
    emailCtrl.dispose();
    phoneCtrl.dispose();
    passwordCtrl.dispose();
    super.onClose();
  }

  /// Bascule entre connexion par email et par téléphone (réinitialise l'erreur).
  void setMode(String mode) {
    if (loginMode.value == mode) return;
    loginMode.value = mode;
    errorMsg.value = '';
  }

  /// Soumet la connexion selon le mode actif (email ou téléphone). Mutualise la
  /// gestion d'erreurs + le cooldown anti-bruteforce des deux méthodes.
  Future<void> submit() async {
    if (_loginCooldown.value) {
      errorMsg.value = 'Trop de tentatives. Réessayez dans 30s.';
      return;
    }
    final form = formKey.currentState;
    if (form == null || !form.validate()) return;

    try {
      isLoading.value = true;
      errorMsg.value = '';
      if (loginMode.value == 'phone') {
        await _authRepository.loginWithPhone(fullPhone, passwordCtrl.text);
      } else {
        await _authRepository.loginWithEmail(
            emailCtrl.text.trim(), passwordCtrl.text);
      }
      _loginAttempts.value = 0;
      await Get.find<OnboardingService>().navigateAfterAuth();
    } on CandidateAccessDeniedException {
      await _authRepository.logout();
      errorMsg.value = CandidateAccess.blockedMessage;
      AppToast.info('Espace employeur', CandidateAccess.blockedMessage);
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
      await _authRepository.loginWithGoogle(result.idToken!,
          email: result.email);
      await Get.find<OnboardingService>().navigateAfterAuth();
    } on CandidateAccessDeniedException {
      await _authRepository.logout();
      errorMsg.value = CandidateAccess.blockedMessage;
      AppToast.info('Espace employeur', CandidateAccess.blockedMessage);
    } catch (e) {
      errorMsg.value = "Échec de connexion Google";
    } finally {
      isLoading.value = false;
    }
  }

  String? validateEmail(String? value) => Validators.email(value);

  /// Au login on NE valide PAS la complexité (majuscule/spécial…) : c'est le
  /// serveur qui vérifie l'exactitude. On exige seulement un champ non vide,
  /// sinon un mot de passe valide mais sans caractère spécial serait rejeté.
  String? validatePassword(String? value) =>
      (value == null || value.isEmpty) ? 'Entrez votre mot de passe' : null;

  /// Validation de la partie locale du numéro (chiffres seuls, 6 à 12).
  /// L'indicatif vient du drapeau sélectionné. Aligné sur l'inscription.
  String? validatePhone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Entrez votre numéro de téléphone';
    if (digits.length < 6 || digits.length > 12) {
      return 'Numéro de téléphone invalide';
    }
    return null;
  }
}
