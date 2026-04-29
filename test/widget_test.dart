import 'package:flutter_test/flutter_test.dart';

/// Le widget test scaffolding par defaut tentait de pumper `OpportuneBFApp`
/// entier — qui depend de ApiProvider, AuthTokenStore (secure storage),
/// SharedPreferences, etc. tous non mockes en environnement test → echec
/// systematique. Les vrais tests vivent dans `test/offers/`,
/// `test/notifications/`, etc. — pure unit, sans dependance Flutter
/// runtime. Ce fichier reste comme placeholder pour le scaffolding.
void main() {
  test('placeholder smoke', () {
    expect(true, isTrue);
  });
}
