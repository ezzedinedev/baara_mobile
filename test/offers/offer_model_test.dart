import 'package:flutter_test/flutter_test.dart';
import 'package:opportune_bf/app/modules/offers/data/models/offer_model.dart';

void main() {
  group('OfferModel.fromJson', () {
    test('parse les champs de base depuis le payload backend', () {
      final json = {
        'id': '01HV-OFFER-1',
        'title': 'Developpeur Flutter',
        'company_name': 'OpporTune Tech',
        'company_logo': 'logos/op.png',
        'city': 'Ouagadougou',
        'region': 'Centre',
        'is_remote': false,
        'contract_type': 'CDI',
        'experience_level': 3,
        'description': 'Mission Flutter senior.',
        'sector': {'id': '1', 'name': 'Tech'},
        'salary_visible': true,
        'salary_min': 500000,
        'salary_max': 900000,
        'salary_currency': 'XOF',
        'required_skills': ['Dart', 'Flutter', 'GetX'],
        'created_at': '2026-04-01T10:00:00Z',
        'deadline': '2026-05-30',
      };

      final offer = OfferModel.fromJson(json);

      expect(offer.id, '01HV-OFFER-1');
      expect(offer.title, 'Developpeur Flutter');
      expect(offer.company, 'OpporTune Tech');
      expect(offer.companyLogo, 'logos/op.png');
      expect(offer.location, 'Ouagadougou • Centre');
      expect(offer.contractType, 'CDI');
      expect(offer.minYearsExperience, 3);
      expect(offer.sector, 'Tech');
      expect(offer.requiredSkills, ['Dart', 'Flutter', 'GetX']);
      expect(offer.salary, contains('500000'));
      expect(offer.salary, contains('900000'));
      expect(offer.isRemote, isFalse);
      expect(offer.createdAt, DateTime.parse('2026-04-01T10:00:00Z'));
    });

    test('extrait company_name + logo depuis la relation employer imbriquee',
        () {
      // Cas du backend qui renvoie l'offre via `with('employer')` plutot
      // qu'a plat — il faut aussi lire dans json['employer'].
      final json = {
        'id': 'X',
        'title': 'Stage RH',
        'employer': {
          'company_name': 'RH Solutions',
          'logo': 'rh.png',
        },
        'city': 'Bobo',
      };

      final offer = OfferModel.fromJson(json);

      expect(offer.company, 'RH Solutions');
      expect(offer.companyLogo, 'rh.png');
      expect(offer.location, 'Bobo');
    });

    test('respecte salary_visible=false → "a negocier" sans nombre', () {
      final json = {
        'id': 'X',
        'title': 'T',
        'salary_visible': false,
        'salary_min': 100000,
        'salary_max': 200000,
      };
      expect(OfferModel.fromJson(json).salary, 'Salaire a negocier');
    });

    test('parse skills depuis une string CSV (compat backend old format)', () {
      final json = {
        'id': 'X',
        'title': 'T',
        'required_skills': 'Java, PHP, MySQL',
      };
      expect(
        OfferModel.fromJson(json).requiredSkills,
        ['Java', 'PHP', 'MySQL'],
      );
    });

    test('Remote ajoute au location quand is_remote=1 (int) ou true', () {
      final asInt = OfferModel.fromJson({
        'id': 'X',
        'title': 'T',
        'city': 'Ouaga',
        'is_remote': 1,
      });
      expect(asInt.location, 'Ouaga • Remote');
      expect(asInt.isRemote, isTrue);

      final asBool = OfferModel.fromJson({
        'id': 'X',
        'title': 'T',
        'is_remote': true,
      });
      expect(asBool.isRemote, isTrue);
    });

    test('id manquant → string vide (jamais null)', () {
      final offer = OfferModel.fromJson({'title': 'No id'});
      expect(offer.id, '');
    });
  });
}
