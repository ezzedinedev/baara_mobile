import 'package:flutter_test/flutter_test.dart';
import 'package:baara/app/core/utils/password_strength.dart';

void main() {
  group('PasswordStrengthEvaluator', () {
    test('empty password returns empty strength', () {
      expect(PasswordStrengthEvaluator.evaluate(''), PasswordStrength.empty);
    });

    test('weak password detected', () {
      expect(PasswordStrengthEvaluator.evaluate('abc'), PasswordStrength.weak);
    });

    test('strong password detected', () {
      expect(
        PasswordStrengthEvaluator.evaluate('Baara2026!Secure'),
        PasswordStrength.strong,
      );
    });

    test('missingCriteria lists unmet rules', () {
      final missing = PasswordStrengthEvaluator.missingCriteria('abc');
      expect(missing, contains('8 caractères minimum'));
      expect(missing, contains('Une majuscule'));
    });
  });
}
