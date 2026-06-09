import 'package:flutter_test/flutter_test.dart';
import 'package:opportune_bf/app/core/network/api_provider.dart';
import 'package:opportune_bf/app/data/models/ai_models.dart';
import 'package:opportune_bf/app/data/repositories/ai_repository.dart';
import 'package:opportune_bf/app/features/ia/domain/entities/chat_message.dart';
import 'package:opportune_bf/app/features/ia/presentation/controllers/chatbot_controller.dart';

class _FakeAiRepository extends AiRepository {
  _FakeAiRepository() : super(apiProvider: ApiProvider());

  AiChatResponse? chatResponse;

  @override
  Future<AiChatResponse> chatSend({
    required String message,
    String? sessionId,
  }) async {
    return chatResponse ??
        const AiChatResponse(
          reply: 'Hi there!',
          ctaActions: [],
          sessionId: 'session123',
        );
  }

  @override
  Future<List<Map<String, dynamic>>> chatSessions() async => [];
}

void main() {
  late ChatbotController controller;
  late _FakeAiRepository fakeAiRepo;

  setUp(() {
    fakeAiRepo = _FakeAiRepository();
    controller = ChatbotController(fakeAiRepo);
  });

  group('ChatbotController', () {
    test('send() adds user message and then assistant reply', () async {
      fakeAiRepo.chatResponse = const AiChatResponse(
        reply: 'Hi there!',
        ctaActions: [],
        sessionId: 'session123',
      );

      await controller.send('Hello');

      expect(controller.messages.length, 2);
      expect(controller.messages[0].content, 'Hello');
      expect(controller.messages[1].content, 'Hi there!');
      expect(controller.sessionId.value, 'session123');
    });

    test('resetSession() clears messages and adds welcome', () {
      controller.messages.add(
        ChatMessage(role: 'user', content: 'x', at: DateTime.now()),
      );
      controller.resetSession();

      expect(controller.messages.length, 1);
      expect(controller.messages.first.role, 'assistant');
    });
  });
}
