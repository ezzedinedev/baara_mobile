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
    final emailRegex = RegExp(
      r"^[A-Z0-9.!#$%&'*+/=?^_`{|}~-]+@(?:[A-Z0-9-]+\.)+[A-Z]{2,63}$",
      caseSensitive: false,
    );
    if (email.length > 254 ||
        email.contains('..') ||
        !emailRegex.hasMatch(email)) {
      return 'Adresse e-mail invalide';
    }
    return null;
  }

  static String? password(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est obligatoire';
    }
    if (value.length < minLength) {
      return 'Minimum $minLength caracteres';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Ajoutez une majuscule';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Ajoutez une minuscule';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Ajoutez un chiffre';
    }
    if (!RegExp(r'[^a-zA-Z0-9]').hasMatch(value)) {
      return 'Ajoutez un caractere special';
    }
    return null;
  }
}
