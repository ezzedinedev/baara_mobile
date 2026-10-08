import 'package:flutter_test/flutter_test.dart';
import 'package:baara/app/core/widgets/common/month_year_picker_sheet.dart';

void main() {
  group('formatMonthYear', () {
    test('mois en toutes lettres puis année', () {
      expect(formatMonthYear(3, 2022), 'mars 2022');
    });

    test('année seule sans mois', () {
      expect(formatMonthYear(null, 2019), '2019');
    });
  });

  group('parseMonthYear', () {
    test('relit le format enregistré', () {
      final r = parseMonthYear('mars 2022');
      expect(r.month, 3);
      expect(r.year, 2022);
      expect(r.present, isFalse);
    });

    test('accepte les anciennes saisies libres', () {
      expect(parseMonthYear('2020').year, 2020);
      expect(parseMonthYear('2020').month, isNull);
      expect(parseMonthYear('03/2021').month, 3);
      expect(parseMonthYear('03/2021').year, 2021);
      expect(parseMonthYear('Sept. 2018').month, 9);
      expect(parseMonthYear('juillet 2020').month, 7);
      expect(parseMonthYear('juin 2020').month, 6);
      expect(parseMonthYear('Juil. 2021').month, 7);
      expect(parseMonthYear('fevrier 2019').month, 2);
    });

    test('reconnaît un poste en cours', () {
      expect(parseMonthYear('Présent').present, isTrue);
      expect(parseMonthYear('en cours').present, isTrue);
    });

    test('valeur vide ou illisible : rien de deviné', () {
      final r = parseMonthYear('');
      expect(r.year, isNull);
      expect(r.month, isNull);
      expect(parseMonthYear('bientôt').year, isNull);
    });
  });
}
