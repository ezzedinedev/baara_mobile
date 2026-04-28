import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../core/network/api_provider.dart';
import '../../../../routes/app_routes.dart';
import '../../../core/widgets/widgets.dart';

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
  RegisterController() : _apiProvider = Get.find<ApiProvider>();

  final ApiProvider _apiProvider;

  final currentStep = 1.obs;
  final isLoading = false.obs;
  final errorMsg = ''.obs;
  final acceptedTerms = false.obs;
  final obscurePassword = true.obs;
  final obscureConfirmPassword = true.obs;
  final selectedCountryIso = 'BF'.obs;
  final registrationProfile = ''.obs;

  final countries = const <RegisterCountryOption>[
    RegisterCountryOption(
      isoCode: 'BF',
      flag: '🇧🇫',
      name: 'Burkina Faso',
      dialCode: '+226',
    ),
    RegisterCountryOption(
      isoCode: 'CI',
      flag: '🇨🇮',
      name: 'Cote d\'Ivoire',
      dialCode: '+225',
    ),
    RegisterCountryOption(
      isoCode: 'SN',
      flag: '🇸🇳',
      name: 'Senegal',
      dialCode: '+221',
    ),
    RegisterCountryOption(
      isoCode: 'ML',
      flag: '🇲🇱',
      name: 'Mali',
      dialCode: '+223',
    ),
    RegisterCountryOption(
      isoCode: 'NE',
      flag: '🇳🇪',
      name: 'Niger',
      dialCode: '+227',
    ),
    RegisterCountryOption(
      isoCode: 'BJ',
      flag: '🇧🇯',
      name: 'Benin',
      dialCode: '+229',
    ),
    RegisterCountryOption(
      isoCode: 'TG',
      flag: '🇹🇬',
      name: 'Togo',
      dialCode: '+228',
    ),
    RegisterCountryOption(
      isoCode: 'GH',
      flag: '🇬🇭',
      name: 'Ghana',
      dialCode: '+233',
    ),
    RegisterCountryOption(
      isoCode: 'CM',
      flag: '🇨🇲',
      name: 'Cameroun',
      dialCode: '+237',
    ),
    RegisterCountryOption(
      isoCode: 'FR',
      flag: '🇫🇷',
      name: 'France',
      dialCode: '+33',
    ),
    RegisterCountryOption(
      isoCode: 'US',
      flag: '🇺🇸',
      name: 'Etats-Unis',
      dialCode: '+1',
    ),
  ];

  final stepOneFormKey = GlobalKey<FormState>();
  final stepTwoFormKey = GlobalKey<FormState>();
  final stepThreeFormKey = GlobalKey<FormState>();

  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final countryCtrl = TextEditingController(text: 'Burkina Faso');
  final phoneCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();

  RegisterCountryOption get selectedCountry {
    return countries.firstWhere(
      (country) => country.isoCode == selectedCountryIso.value,
      orElse: () => countries.first,
    );
  }

  double get progressValue => currentStep.value / 3;
  int get progressPercent => (progressValue * 100).round();

  String get stepTitle {
    switch (currentStep.value) {
      case 1:
        return 'Commencons !';
      case 2:
        return 'Informations de contact';
      case 3:
      default:
        return 'Securisez votre compte';
    }
  }

  String get stepSubtitle {
    switch (currentStep.value) {
      case 1:
        return 'Dites-nous qui vous etes';
      case 2:
        return 'Comment pouvons-nous vous joindre ?';
      case 3:
      default:
        return 'Creez un mot de passe securise';
    }
  }

  String get backLabel =>
      currentStep.value == 1 ? 'Choix du profil' : 'Etape precedente';

  String get registrationProfileLabel {
    if (registrationProfile.value == 'student') {
      return 'Etudiant';
    }
    if (registrationProfile.value == 'professional') {
      return 'Professionnel';
    }
    return 'Non defini';
  }

  String get actionLabel =>
      currentStep.value == 3 ? 'Creer mon compte' : 'Continuer';

  @override
  void onInit() {
    super.onInit();
    final hasProfile = _hydrateRegistrationProfile();
    if (!hasProfile) {
      Future<void>.microtask(() => Get.offAllNamed(AppRoutes.registerProfile));
    }
    countryCtrl.text = selectedCountry.name;
  }

  void onBack() {
    errorMsg.value = '';
    if (currentStep.value == 1) {
      Get.offAllNamed(AppRoutes.registerProfile);
      return;
    }
    currentStep.value -= 1;
  }

  Future<void> onContinue() async {
    errorMsg.value = '';

    if (currentStep.value == 1) {
      if (_validateStep(stepOneFormKey)) {
        currentStep.value = 2;
      }
      return;
    }

    if (currentStep.value == 2) {
      if (_validateStep(stepTwoFormKey)) {
        currentStep.value = 3;
      }
      return;
    }

    if (!_validateStep(stepThreeFormKey)) {
      return;
    }

    if (!acceptedTerms.value) {
      errorMsg.value = 'Veuillez accepter les conditions d\'utilisation.';
      return;
    }

    await _register();
  }

  void toggleTerms() => acceptedTerms.toggle();

  void togglePasswordVisibility() => obscurePassword.toggle();

  void toggleConfirmPasswordVisibility() => obscureConfirmPassword.toggle();

  void selectCountry(String isoCode) {
    selectedCountryIso.value = isoCode;
    countryCtrl.text = selectedCountry.name;
    if (phoneCtrl.text.trim().isEmpty) {
      phoneCtrl.text = '${selectedCountry.dialCode} ';
    }
  }

  String? validateFirstName(String? value) {
    final required = Validators.requiredField(value, 'prenom');
    if (required != null) {
      return required;
    }
    if (value!.trim().length < 2) {
      return 'Minimum 2 caracteres';
    }
    return null;
  }

  String? validateLastName(String? value) {
    final required = Validators.requiredField(value, 'nom');
    if (required != null) {
      return required;
    }
    if (value!.trim().length < 2) {
      return 'Minimum 2 caracteres';
    }
    return null;
  }

  String? validateEmail(String? value) => Validators.email(value);

  String? validateCountry(String? value) =>
      Validators.requiredField(value, 'pays');

  String? validatePhone(String? value) {
    final required = Validators.requiredField(value, 'telephone');
    if (required != null) {
      return required;
    }
    final normalized = value!.trim();
    final phoneRegex = RegExp(r'^\+?[0-9 ]{8,20}$');
    if (!phoneRegex.hasMatch(normalized)) {
      return 'Numero de telephone invalide';
    }
    return null;
  }

  String? validatePassword(String? value) =>
      Validators.password(value, minLength: 8);

  String? validatePasswordConfirmation(String? value) {
    final required = Validators.requiredField(value, 'confirmation');
    if (required != null) {
      return required;
    }
    if (value != passwordCtrl.text) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  bool _validateStep(GlobalKey<FormState> formKey) {
    final form = formKey.currentState;
    if (form == null) {
      return false;
    }
    return form.validate();
  }

  Future<void> _register() async {
    isLoading.value = true;

    try {
      // NB : le backend (`AuthApiController@register`) ne valide pas `name`,
      // `country` ni `candidate_profile_type` — on les retire du payload pour
      // éviter de transporter du bruit. `candidate_profile_type` et `country`
      // devraient être persistés via un PUT /profile post-login si on veut les
      // conserver côté serveur.
      final payload = <String, dynamic>{
        'first_name': firstNameCtrl.text.trim(),
        'last_name': lastNameCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'password': passwordCtrl.text,
        'password_confirmation': confirmPasswordCtrl.text,
        'user_type': 'candidate',
        'device_name': ApiConstants.authDeviceName,
      };

      final data = await _apiProvider.postJson(ApiConstants.register, payload);

      if ((data['statusCode'] == 200 || data['statusCode'] == 201) &&
          data['success'] == true) {
        Get.offAllNamed(AppRoutes.candidateLogin);
        AppToast.success(
          'Inscription reussie',
          'Votre compte a ete cree. Connectez-vous pour continuer.',
        );
        return;
      }

      errorMsg.value = _buildRegisterErrorMessage(data);
    } on Exception {
      errorMsg.value = 'Erreur reseau. Veuillez reessayer.';
    } finally {
      passwordCtrl.clear();
      confirmPasswordCtrl.clear();
      isLoading.value = false;
    }
  }

  String _buildRegisterErrorMessage(Map<String, dynamic> data) {
    final statusCode = data['statusCode'];
    final fieldErrors = data['errors'];
    if (fieldErrors is Map) {
      final lines = <String>[];
      fieldErrors.forEach((key, value) {
        final field = _fieldLabel(key.toString());
        final message = _extractFieldMessage(
          fieldKey: key.toString(),
          rawValue: value,
        );
        if (message != null && message.isNotEmpty) {
          lines.add('$field : $message');
        }
      });

      if (lines.isNotEmpty) {
        return 'Donnees invalides :\n- ${lines.join('\n- ')}';
      }
    }

    final rawMessage = (data['message'] as String?)?.trim();
    if (rawMessage == null || rawMessage.isEmpty) {
      return 'Inscription impossible pour le moment.';
    }

    if (_isTechnicalBackendMessage(rawMessage)) {
      return 'Une erreur serveur est survenue. Veuillez reessayer plus tard.';
    }

    if (statusCode is int && statusCode >= 500) {
      return 'Le service est temporairement indisponible. Veuillez reessayer.';
    }

    if (rawMessage.toLowerCase().contains('given data was invalid')) {
      return 'Certaines donnees sont invalides. Verifiez les champs du formulaire.';
    }

    return rawMessage;
  }

  String? _extractFieldMessage({
    required String fieldKey,
    required dynamic rawValue,
  }) {
    if (rawValue is List && rawValue.isNotEmpty) {
      return _normalizeBackendMessage(
        fieldKey: fieldKey,
        message: rawValue.first.toString(),
      );
    }
    if (rawValue is String && rawValue.trim().isNotEmpty) {
      return _normalizeBackendMessage(
        fieldKey: fieldKey,
        message: rawValue,
      );
    }
    return null;
  }

  String _fieldLabel(String fieldKey) {
    switch (fieldKey) {
      case 'first_name':
        return 'Prenom';
      case 'last_name':
        return 'Nom';
      case 'name':
        return 'Nom complet';
      case 'email':
        return 'Adresse e-mail';
      case 'phone':
        return 'Numero de telephone';
      case 'country':
        return 'Pays';
      case 'password':
        return 'Mot de passe';
      case 'password_confirmation':
        return 'Confirmation du mot de passe';
      default:
        return fieldKey;
    }
  }

  String _normalizeBackendMessage({
    required String fieldKey,
    required String message,
  }) {
    final lower = message.toLowerCase();

    if (lower.contains('already been taken')) {
      if (fieldKey == 'email') {
        return 'Cette adresse e-mail est deja utilisee.';
      }
      if (fieldKey == 'phone') {
        return 'Ce numero de telephone est deja utilise.';
      }
      return 'Cette valeur est deja utilisee.';
    }

    if (lower.contains('field is required')) {
      return 'Ce champ est obligatoire.';
    }

    if (lower.contains('must be at least') &&
        RegExp(r'\d+').hasMatch(message)) {
      final size = RegExp(r'\d+').firstMatch(message)?.group(0);
      if (size != null) {
        return 'Minimum $size caracteres.';
      }
    }

    if (lower.contains('password confirmation does not match')) {
      return 'La confirmation du mot de passe ne correspond pas.';
    }

    if (lower.contains('must be a valid email')) {
      return 'Adresse e-mail invalide.';
    }

    if (_isTechnicalBackendMessage(message)) {
      return 'Valeur invalide.';
    }

    return message;
  }

  bool _isTechnicalBackendMessage(String message) {
    final lower = message.toLowerCase();
    const technicalMarkers = <String>[
      'sqlstate',
      'queryexception',
      'pdoexception',
      'syntax error',
      'integrity constraint',
      'connection: mysql',
      'select ',
      'insert into',
      'update `',
      'delete from',
      'stack trace',
      '#0 ',
      'vendor/laravel',
    ];

    for (final marker in technicalMarkers) {
      if (lower.contains(marker)) {
        return true;
      }
    }
    return false;
  }

  bool _hydrateRegistrationProfile() {
    final args = Get.arguments;
    if (args is! Map) {
      return false;
    }

    final rawValue = args['registration_profile']?.toString().toLowerCase();
    if (rawValue == 'student' || rawValue == 'professional') {
      registrationProfile.value = rawValue!;
      return true;
    }
    return false;
  }

  @override
  void onClose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    emailCtrl.dispose();
    countryCtrl.dispose();
    phoneCtrl.dispose();
    passwordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    super.onClose();
  }
}
