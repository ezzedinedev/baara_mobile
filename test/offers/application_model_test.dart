import 'package:flutter_test/flutter_test.dart';
import 'package:opportune_bf/app/modules/offers/data/models/application_model.dart';

void main() {
  group('ApplicationStatus.fromString', () {
    test('mappe les valeurs backend connues', () {
      expect(ApplicationStatus.fromString('new'), ApplicationStatus.newApp);
      expect(
        ApplicationStatus.fromString('shortlisted'),
        ApplicationStatus.shortlisted,
      );
      expect(
        ApplicationStatus.fromString('interview'),
        ApplicationStatus.interview,
      );
      expect(
        ApplicationStatus.fromString('rejected'),
        ApplicationStatus.rejected,
      );
    });

    test('fallback sur newApp pour valeur inconnue ou null', () {
      expect(ApplicationStatus.fromString(null), ApplicationStatus.newApp);
      expect(
        ApplicationStatus.fromString('unknown_status'),
        ApplicationStatus.newApp,
      );
    });
  });

  group('ApplicationModel.fromJson', () {
    test('parse une candidature complete avec offer imbriquee', () {
      final json = {
        'id': 'app-1',
        'offer_id': 'offer-1',
        'candidate_id': 'cand-1',
        'status': 'shortlisted',
        'applied_at': '2026-04-15T09:30:00Z',
        'ai_match_score': 78.5,
        'screening_score': 65,
        'rejection_reason': null,
        'offer': {
          'id': 'offer-1',
          'title': 'Lead Backend',
          'company_name': 'OpporTune',
        },
      };

      final app = ApplicationModel.fromJson(json);

      expect(app.id, 'app-1');
      expect(app.offerId, 'offer-1');
      expect(app.candidateId, 'cand-1');
      expect(app.status, ApplicationStatus.shortlisted);
      expect(app.aiMatchScore, 78.5);
      expect(app.screeningScore, 65.0);
      expect(app.appliedAt, DateTime.parse('2026-04-15T09:30:00Z'));
      expect(app.offer, isNotNull);
      expect(app.offer!.title, 'Lead Backend');
    });

    test('rejected avec rejection_reason → isRejected=true', () {
      final app = ApplicationModel.fromJson({
        'id': 'a',
        'offer_id': 'o',
        'candidate_id': 'c',
        'status': 'rejected',
        'rejection_reason': 'Profil pas en adequation.',
      });
      expect(app.isRejected, isTrue);
      expect(app.rejectionReason, 'Profil pas en adequation.');
    });

    test('applied_at manquant → fallback created_at puis now', () {
      final withCreated = ApplicationModel.fromJson({
        'id': 'a',
        'offer_id': 'o',
        'candidate_id': 'c',
        'status': 'new',
        'created_at': '2026-04-01T00:00:00Z',
      });
      expect(
        withCreated.appliedAt,
        DateTime.parse('2026-04-01T00:00:00Z'),
      );

      // Aucun champ date → on prend now() ; on verifie juste que c'est
      // recent (moins d'1 seconde d'ecart) plutot qu'une valeur exacte.
      final withoutDate = ApplicationModel.fromJson({
        'id': 'a',
        'offer_id': 'o',
        'candidate_id': 'c',
        'status': 'new',
      });
      final delta = DateTime.now().difference(withoutDate.appliedAt).inSeconds;
      expect(delta, lessThan(2));
    });

    test('offer absente → app.offer == null (pas de crash)', () {
      final app = ApplicationModel.fromJson({
        'id': 'a',
        'offer_id': 'o',
        'candidate_id': 'c',
        'status': 'new',
      });
      expect(app.offer, isNull);
    });

    test('ai_match_score sous forme string (backend serialize en str)', () {
      final app = ApplicationModel.fromJson({
        'id': 'a',
        'offer_id': 'o',
        'candidate_id': 'c',
        'status': 'new',
        'ai_match_score': '82.0',
      });
      expect(app.aiMatchScore, 82.0);
    });
  });
}
