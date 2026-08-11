import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baara/app/features/messaging/data/models/message_model.dart';
import 'package:baara/app/features/messaging/domain/entities/message.dart';
import 'package:baara/app/features/messaging/domain/repositories/i_messaging_repository.dart';
import 'package:baara/app/features/messaging/presentation/controllers/messages_controller.dart';
import 'package:baara/app/features/messaging/presentation/widgets/chat_structured_actions.dart';
import 'package:baara/app/features/offers/data/models/interview_detail_model.dart';

import '../../../support/fake_offer_repository.dart';

class _StubMessagingRepository implements IMessagingRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

/// Message d'entretien tel que le backend l'émet : contenu texte + `meta_json`.
Map<String, dynamic> _rescheduleRequestJson() => {
      'id': 'msg-1',
      'content': "L'employeur propose une autre date : vendredi 17 juillet.",
      'sent_at': '2026-07-09T10:00:00.000000Z',
      'is_mine': false,
      'message_type': 'text',
      'meta_json': {
        'type': 'reschedule_request',
        'interview_id': 'itw-42',
        'proposed_date': '2026-07-17T12:46:00.000Z',
        'actions': ['accept_new_date', 'propose_other'],
      },
    };

/// Monte un arbre minimal et rend le `BuildContext` de la page courante.
Future<BuildContext> _pumpContext(WidgetTester tester) async {
  late BuildContext ctx;
  await tester.pumpWidget(MaterialApp(
    home: Builder(builder: (context) {
      ctx = context;
      return const Scaffold(body: SizedBox());
    }),
  ));
  return ctx;
}

void main() {
  group('MessageModel.fromJson — meta_json', () {
    test('parse le type, la cible, la date et les actions', () {
      final msg = MessageModel.fromJson(_rescheduleRequestJson());
      final meta = msg.meta;

      expect(meta, isNotNull);
      expect(meta!.type, 'reschedule_request');
      expect(meta.interviewId, 'itw-42');
      expect(meta.targetId, 'itw-42');
      expect(meta.isInterview, isTrue);
      expect(meta.isProposal, isFalse);
      expect(meta.proposedDate, DateTime.parse('2026-07-17T12:46:00.000Z'));
      expect(meta.actions,
          [MessageAction.acceptNewDate, MessageAction.proposeOther]);
      expect(msg.hasActions, isTrue);
    });

    test('ignore une action inconnue du backend sans planter', () {
      final json = _rescheduleRequestJson();
      (json['meta_json'] as Map)['actions'] = ['accept', 'teleport'];

      final meta = MessageModel.fromJson(json).meta!;
      expect(meta.actions, [MessageAction.accept]);
    });

    test('un message sans meta_json n\'a ni meta ni boutons', () {
      final json = _rescheduleRequestJson()..remove('meta_json');
      final msg = MessageModel.fromJson(json);

      expect(msg.meta, isNull);
      expect(msg.hasActions, isFalse);
    });

    test('un message structuré émis par moi n\'affiche pas de boutons', () {
      final json = _rescheduleRequestJson()..['is_mine'] = true;
      final msg = MessageModel.fromJson(json);

      expect(msg.meta, isNotNull);
      expect(msg.hasActions, isFalse);
    });
  });

  group('MessagesController.respondToStructuredAction', () {
    testWidgets('accept_new_date est envoyé au backend comme `accept`',
        (tester) async {
      final offers = FakeOfferRepository();
      final controller =
          MessagesController(_StubMessagingRepository(), offers);
      final message = MessageModel.fromJson(_rescheduleRequestJson());
      final ctx = await _pumpContext(tester);

      await controller.respondToStructuredAction(
          ctx, message, MessageAction.acceptNewDate);

      expect(offers.interviewCalls, hasLength(1));
      expect(offers.interviewCalls.single.id, 'itw-42');
      expect(offers.interviewCalls.single.action, InterviewAction.accept);
      // Accepter n'envoie pas de date : le backend adopte celle qu'il a proposée.
      expect(offers.interviewCalls.single.proposedDate, isNull);
    });

    testWidgets('propose_other ouvre la feuille et n\'envoie rien si annulée',
        (tester) async {
      final offers = FakeOfferRepository();
      final controller =
          MessagesController(_StubMessagingRepository(), offers);
      final message = MessageModel.fromJson(_rescheduleRequestJson());
      final ctx = await _pumpContext(tester);

      final pending = controller.respondToStructuredAction(
          ctx, message, MessageAction.proposeOther);
      await tester.pumpAndSettle();

      expect(find.text('Proposer une autre date'), findsOneWidget);
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      await pending;

      expect(offers.interviewCalls, isEmpty);
      expect(controller.isRespondingTo(message.id), isFalse);
    });

    testWidgets('propose_other envoie la date choisie comme `reschedule`',
        (tester) async {
      final offers = FakeOfferRepository();
      final controller =
          MessagesController(_StubMessagingRepository(), offers);
      final message = MessageModel.fromJson(_rescheduleRequestJson());
      final ctx = await _pumpContext(tester);

      final pending = controller.respondToStructuredAction(
          ctx, message, MessageAction.proposeOther);
      await tester.pumpAndSettle();

      // La feuille pré-remplit J+1 à 09:00 : on valide tel quel.
      await tester.tap(find.text('Envoyer'));
      await tester.pumpAndSettle();
      await pending;

      expect(offers.interviewCalls, hasLength(1));
      final call = offers.interviewCalls.single;
      expect(call.action, InterviewAction.reschedule);
      expect(call.proposedDate, isNotNull);
      expect(call.proposedDate!.isAfter(DateTime.now()), isTrue);
    });

    testWidgets('une cible manquante ne déclenche aucun appel', (tester) async {
      final offers = FakeOfferRepository();
      final controller =
          MessagesController(_StubMessagingRepository(), offers);
      final json = _rescheduleRequestJson();
      (json['meta_json'] as Map).remove('interview_id');
      final message = MessageModel.fromJson(json);
      final ctx = await _pumpContext(tester);

      await controller.respondToStructuredAction(
          ctx, message, MessageAction.acceptNewDate);

      expect(offers.interviewCalls, isEmpty);
    });
  });

  group('ChatStructuredActions', () {
    Future<void> pumpActions(WidgetTester tester, Message message,
        {bool isBusy = false}) {
      return tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChatStructuredActions(
            message: message,
            isBusy: isBusy,
            onAction: (_) {},
          ),
        ),
      ));
    }

    testWidgets('rend un bouton par action + la date proposée',
        (tester) async {
      await pumpActions(tester, MessageModel.fromJson(_rescheduleRequestJson()));

      expect(find.text('Accepter la date'), findsOneWidget);
      expect(find.text('Proposer une autre date'), findsOneWidget);
      expect(find.textContaining('17/07/2026'), findsOneWidget);
    });

    testWidgets('ne rend rien pour un message sans action', (tester) async {
      final json = _rescheduleRequestJson()..remove('meta_json');
      await pumpActions(tester, MessageModel.fromJson(json));

      expect(find.byType(ChatStructuredActions), findsOneWidget);
      expect(find.text('Accepter la date'), findsNothing);
    });
  });
}
