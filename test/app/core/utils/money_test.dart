import 'package:flutter_test/flutter_test.dart';
import 'package:baara/app/core/utils/money.dart';

/// Insécable attendu entre les groupes de milliers et avant la devise.
/// Échappé ici aussi : comparer contre un insécable littéral rendrait l'échec
/// de test illisible (« attendu '350 000', obtenu '350 000' »).
const _s = '\u00A0';

void main() {
  group('formatAmount', () {
    // Le backend renvoie des décimaux Laravel : c'est la source du
    // « 350000.00 - 600000.00 XOF » affiché tel quel sur le détail d'offre.
    test('arrondit les décimales et groupe les milliers', () {
      expect(formatAmount('350000.00'), '350${_s}000');
      expect(formatAmount('600000.00'), '600${_s}000');
      expect(formatAmount(1234567), '1${_s}234${_s}567');
    });

    test('accepte un num comme une String', () {
      expect(formatAmount(350000), formatAmount('350000'));
    });

    test('ne groupe pas en dessous de mille', () {
      expect(formatAmount(999), '999');
    });

    test('rend null sur une valeur non numérique', () {
      expect(formatAmount(null), isNull);
      expect(formatAmount('à négocier'), isNull);
      expect(formatAmount(''), isNull);
    });
  });

  group('currencyLabel', () {
    test('XOF devient FCFA', () {
      expect(currencyLabel('XOF'), 'FCFA');
      expect(currencyLabel('xof'), 'FCFA');
      expect(currencyLabel(null), 'FCFA');
    });

    test('une autre devise est conservée', () {
      expect(currencyLabel('EUR'), 'EUR');
    });
  });

  group('formatMoneyRange', () {
    test('fourchette complète, devise écrite une seule fois', () {
      expect(
        formatMoneyRange('350000.00', '600000.00', currency: 'XOF'),
        '350${_s}000 – 600${_s}000${_s}FCFA',
      );
    });

    test('borne unique', () {
      expect(
        formatMoneyRange('350000.00', null),
        'À partir de 350${_s}000${_s}FCFA',
      );
      expect(
        formatMoneyRange(null, '600000.00'),
        'Jusqu\'à 600${_s}000${_s}FCFA',
      );
    });

    test('min == max ne produit pas une fourchette dégénérée', () {
      expect(formatMoneyRange('500000.00', '500000.00'),
          '500${_s}000${_s}FCFA');
    });

    test('rend null quand aucune borne n\'est exploitable', () {
      expect(formatMoneyRange(null, null), isNull);
    });

    // Garde-fou : c'est ce qui empêche « 350 » et « 000 » de se retrouver sur
    // deux lignes dans une carte étroite.
    test('les groupes de milliers sont liés par un insécable', () {
      final out = formatMoneyRange('350000.00', '600000.00')!;
      expect(out, contains('350${_s}000'));
      expect(out, contains('600${_s}000'));
    });
  });
}
