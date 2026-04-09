class Validators {
  Validators._();

  static String? requiredField(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Le champ $label est obligatoire';
    }
    return null;
  }

  static String? email(String? value) {
    final required = requiredField(value, 'e-mail');
    if (required != null) {
      return required;
    }

    final email = value!.trim();
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Adresse e-mail invalide';
    }
    return null;
  }

  static String? password(String? value, {int minLength = 4}) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est obligatoire';
    }
    if (value.length < minLength) {
      return 'Minimum $minLength caractères';
    }
    return null;
  }
}
