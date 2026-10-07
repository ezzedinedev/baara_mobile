import 'package:flutter_test/flutter_test.dart';
import 'package:baara/app/core/services/app_update_service.dart';

void main() {
  group('AppUpdateService.isOlder', () {
    test('compare champ par champ, pas comme du texte', () {
      expect(AppUpdateService.isOlder('1.2.0', '1.10.0'), isTrue);
      expect(AppUpdateService.isOlder('1.10.0', '1.2.0'), isFalse);
    });

    test('même version : pas plus ancienne', () {
      expect(AppUpdateService.isOlder('1.0.0', '1.0.0'), isFalse);
    });

    test('ignore le numéro de build', () {
      expect(AppUpdateService.isOlder('1.0.0+7', '1.0.0'), isFalse);
      expect(AppUpdateService.isOlder('1.0.0+7', '1.0.1'), isTrue);
    });

    test('versions courtes complétées par des zéros', () {
      expect(AppUpdateService.isOlder('1.2', '1.2.0'), isFalse);
      expect(AppUpdateService.isOlder('1', '1.0.1'), isTrue);
    });

    test('cible vide ou invalide : jamais de blocage', () {
      expect(AppUpdateService.isOlder('1.0.0', ''), isFalse);
      expect(AppUpdateService.isOlder('1.0.0', 'abc'), isFalse);
    });
  });
}
