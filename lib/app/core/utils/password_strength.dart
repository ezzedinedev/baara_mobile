/// Évalue la robustesse d'un mot de passe (0 = vide, 4 = fort).
enum PasswordStrength {
  empty,
  weak,
  fair,
  good,
  strong;

  String get labelFr => switch (this) {
        PasswordStrength.empty => '',
        PasswordStrength.weak => 'Faible',
        PasswordStrength.fair => 'Moyen',
        PasswordStrength.good => 'Bon',
        PasswordStrength.strong => 'Fort',
      };

  /// Nombre de barres remplies (0–4).
  int get bars => switch (this) {
        PasswordStrength.empty => 0,
        PasswordStrength.weak => 1,
        PasswordStrength.fair => 2,
        PasswordStrength.good => 3,
        PasswordStrength.strong => 4,
      };
}

abstract final class PasswordStrengthEvaluator {
  static PasswordStrength evaluate(String password) {
    if (password.isEmpty) return PasswordStrength.empty;

    var score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 3) return PasswordStrength.fair;
    if (score <= 4) return PasswordStrength.good;
    return PasswordStrength.strong;
  }

  /// Critères manquants pour guider l'utilisateur.
  static List<String> missingCriteria(String password) {
    final missing = <String>[];
    if (password.length < 8) missing.add('8 caractères minimum');
    if (!RegExp(r'[A-Z]').hasMatch(password)) missing.add('Une majuscule');
    if (!RegExp(r'[a-z]').hasMatch(password)) missing.add('Une minuscule');
    if (!RegExp(r'\d').hasMatch(password)) missing.add('Un chiffre');
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      missing.add('Un caractère spécial');
    }
    return missing;
  }
}
