import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opportune_bf/app/core/constants/api_constants.dart';
import 'package:opportune_bf/app/core/utils/user_facing_error.dart';
import 'package:opportune_bf/routes/app_routes.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import '../../domain/repositories/i_auth_repository.dart';

class RegisterCountryOption {
  const RegisterCountryOption({
    required this.isoCode,
    required this.flag,
    required this.name,
    required this.dialCode,
  });

  final String isoCode;
  final String flag;
  final String name;
  final String dialCode;
}

class RegisterController extends GetxController {
  final IAuthRepository _authRepository;
  RegisterController(this._authRepository);

  final currentStep = 1.obs;
  final isLoading = false.obs;
  final errorMsg = ''.obs;
  final acceptedTerms = false.obs;
  final registrationProfile = ''.obs;
  final selectedCountryIso = 'BF'.obs;

  final countries = const <RegisterCountryOption>[
    RegisterCountryOption(
        isoCode: 'BF', flag: '🇧🇫', name: 'Burkina Faso', dialCode: '+226'),
    RegisterCountryOption(
        isoCode: 'CI', flag: '🇨🇮', name: 'Côte d\'Ivoire', dialCode: '+225'),
    RegisterCountryOption(
        isoCode: 'SN', flag: '🇸🇳', name: 'Sénégal', dialCode: '+221'),
  ];

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
    final country = countries.firstWhere((c) => c.isoCode == isoCode);
    countryCtrl.text = country.name;
    if (phoneCtrl.text.isEmpty) {
      phoneCtrl.text = '${country.dialCode} ';
    }
  }

  String? validateCountry(String? v) =>
      (v == null || v.isEmpty) ? 'Champ requis' : null;

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
        'phone': phoneCtrl.text.trim(),
        'password': passwordCtrl.text,
        'password_confirmation': confirmPasswordCtrl.text,
        'user_type': 'candidate',
        if (registrationProfile.value.isNotEmpty)
          'registration_profile': registrationProfile.value,
        if (registrationProfile.value.isNotEmpty)
          'profile_type': registrationProfile.value,
        'device_name': ApiConstants.authDeviceName,
      });
      final phone = phoneCtrl.text.trim();
      Get.offAllNamed(AppRoutes.otpVerification, arguments: {'phone': phone});
      AppToast.success(
        'Compte créé',
        'Vérifiez votre numéro avec le code reçu par SMS.',
      );
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
