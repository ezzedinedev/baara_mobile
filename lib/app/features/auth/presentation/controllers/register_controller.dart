import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jobaway/app/core/constants/api_constants.dart';
import 'package:jobaway/app/core/network/api_provider.dart';
import 'package:jobaway/app/core/utils/user_facing_error.dart';
import 'package:jobaway/routes/app_routes.dart';
import 'package:jobaway/app/core/widgets/widgets.dart';
import '../../domain/repositories/i_auth_repository.dart';

class RegisterController extends GetxController {
  final IAuthRepository _authRepository;
  RegisterController(this._authRepository);

  final currentStep = 1.obs;
  final isLoading = false.obs;
  final errorMsg = ''.obs;
  final acceptedTerms = false.obs;
  final registrationProfile = ''.obs;
  final selectedCountryIso = 'BF'.obs;

  /// Liste des pays proposés (zone UEMOA) — cf. [PhoneCountry.uemoa].
  final countries = PhoneCountry.uemoa;

  /// Pays / indicatif actuellement sélectionné, dérivé de [selectedCountryIso].
  PhoneCountry get selectedCountry =>
      PhoneCountry.byIso(selectedCountryIso.value);

  final stepOneFormKey = GlobalKey<FormState>();
  final stepTwoFormKey = GlobalKey<FormState>();
  final stepThreeFormKey = GlobalKey<FormState>();

  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final countryCtrl = TextEditingController(text: 'Burkina Faso');
  final passwordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['registration_profile'] != null) {
      registrationProfile.value = args['registration_profile'].toString();
    }
  }

  void selectCountry(String isoCode) {
    selectedCountryIso.value = isoCode;
    countryCtrl.text = PhoneCountry.byIso(isoCode).name;
  }

  String? validateCountry(String? v) =>
      (v == null || v.isEmpty) ? 'Champ requis' : null;

  /// Valide la partie locale du numéro (chiffres seulement, 6 à 12 chiffres).
  String? validatePhone(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Numéro requis';
    if (digits.length < 6 || digits.length > 12) {
      return 'Numéro invalide';
    }
    return null;
  }

  /// Numéro complet au format international (ex. `+22670000000`).
  String get fullPhone {
    final digits = phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    return '${selectedCountry.dialCode}$digits';
  }

  String? validateRequired(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Champ requis' : null;

  String? validateEmail(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Email requis';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) {
      return 'Email invalide';
    }
    return null;
  }

  String? validatePassword(String? v) {
    final s = v ?? '';
    if (s.isEmpty) return 'Mot de passe requis';
    if (s.length < 8) return 'Au moins 8 caractères';
    return null;
  }

  String? validateConfirmPassword(String? v) =>
      (v != passwordCtrl.text) ? 'Les mots de passe ne correspondent pas' : null;

  /// Numéro d'étape (1-3) portant le champ backend fourni, ou `null` si inconnu.
  int? _stepForField(String field) {
    switch (field) {
      case 'first_name':
      case 'last_name':
        return 1;
      case 'email':
      case 'phone':
        return 2;
      case 'password':
      case 'pin':
        return 3;
    }
    return null;
  }

  /// Ramène l'utilisateur à la première étape contenant un champ en erreur,
  /// pour qu'il voie et corrige le champ fautif signalé par le serveur.
  void _goToFirstInvalidStep(Iterable<String> fields) {
    int? target;
    for (final field in fields) {
      final step = _stepForField(field);
      if (step != null && (target == null || step < target)) {
        target = step;
      }
    }
    if (target != null && target != currentStep.value) {
      currentStep.value = target;
    }
  }

  void onContinue() async {
    if (currentStep.value == 1 && stepOneFormKey.currentState!.validate()) {
      currentStep.value = 2;
    } else if (currentStep.value == 2 &&
        stepTwoFormKey.currentState!.validate()) {
      currentStep.value = 3;
    } else if (currentStep.value == 3 &&
        stepThreeFormKey.currentState!.validate()) {
      if (!acceptedTerms.value) {
        errorMsg.value = "Acceptez les conditions d'utilisation";
        return;
      }
      await _register();
    }
  }

  Future<void> _register() async {
    try {
      isLoading.value = true;
      errorMsg.value = '';
      await _authRepository.register({
        'first_name': firstNameCtrl.text.trim(),
        'last_name': lastNameCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'phone': fullPhone,
        'password': passwordCtrl.text,
        'password_confirmation': confirmPasswordCtrl.text,
        'user_type': 'candidate',
        if (registrationProfile.value.isNotEmpty)
          'registration_profile': registrationProfile.value,
        if (registrationProfile.value.isNotEmpty)
          'profile_type': registrationProfile.value,
        'device_name': ApiConstants.authDeviceName,
      });
      Get.offAllNamed(AppRoutes.otpVerification,
          arguments: {'phone': fullPhone, 'email': emailCtrl.text.trim()});
      AppToast.success(
        'Compte créé',
        'Vérifiez votre compte avec le code reçu par email.',
      );
    } on ApiValidationException catch (e) {
      // Détail par champ : on affiche le message précis et on ramène
      // l'utilisateur à l'étape du champ fautif.
      errorMsg.value = e.message;
      _goToFirstInvalidStep(e.errors.keys);
    } catch (e) {
      errorMsg.value = userFacingError(e);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    countryCtrl.dispose();
    passwordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    super.onClose();
  }
}
