import 'package:flutter_test/flutter_test.dart';
import 'package:baara/app/features/messaging/data/models/conversation_model.dart';

Map<String, dynamic> _recruitmentJson({Map<String, dynamic>? application}) {
  return {
    'id': 'c1',
    'employer': {'company_name': 'Test Employer Company'},
    'last_message_at': '2026-07-20T11:44:00Z',
    'latest_message': {'content': 'Bonjour,'},
    'unread_candidate': 1,
    if (application != null) 'application': application,
  };
}

void main() {
  group('ConversationModel.fromJson — poste rattaché', () {
    // Un candidat peut avoir plusieurs conversations avec le même employeur
    // (une par candidature). Le titre valant le nom de la société pour toutes,
    // seul `offerTitle` permet de les distinguer dans la liste.
    test('lit application.offer.title', () {
      final conv = ConversationModel.fromJson(_recruitmentJson(
        application: {
          'id': 'a1',
          'offer': {'id': 'o1', 'title': 'Développeur Full Stack'},
        },
      ));

      expect(conv.title, 'Test Employer Company');
      expect(conv.offerTitle, 'Développeur Full Stack');
    });

    test('deux conversations du même employeur restent distinguables', () {
      final dev = ConversationModel.fromJson(_recruitmentJson(
        application: {
          'offer': {'title': 'Développeur Full Stack'},
        },
      ));
      final rh = ConversationModel.fromJson(_recruitmentJson(
        application: {
          'offer': {'title': 'Responsable RH'},
        },
      ));

      expect(dev.title, rh.title);
      expect(dev.offerTitle, isNot(rh.offerTitle));
    });

    test('offerTitle est nul sans candidature liée', () {
      final conv = ConversationModel.fromJson(_recruitmentJson());
      expect(conv.offerTitle, isNull);
    });

    test('offerTitle est nul quand la candidature n\'a pas d\'offre', () {
      final conv = ConversationModel.fromJson(
        _recruitmentJson(application: {'id': 'a1'}),
      );
      expect(conv.offerTitle, isNull);
    });

    test('un titre vide ou blanc est ramené à null', () {
      final conv = ConversationModel.fromJson(_recruitmentJson(
        application: {
          'offer': {'title': '   '},
        },
      ));
      expect(conv.offerTitle, isNull);
    });

    test('un DM direct n\'a pas de poste', () {
      final conv = ConversationModel.fromJson({
        'id': 'c2',
        'direct_user': {
          'id': 'u9',
          'first_name': 'Alice',
          'last_name': 'Kabore',
        },
        'last_message_at': '2026-07-20T11:44:00Z',
      });

      expect(conv.title, 'Alice Kabore');
      expect(conv.offerTitle, isNull);
    });
  });
}
