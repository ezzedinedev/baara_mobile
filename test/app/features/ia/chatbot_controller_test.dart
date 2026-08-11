import 'package:flutter_test/flutter_test.dart';
import 'package:baara/app/data/models/ai_models.dart';
import 'package:baara/app/features/ia/domain/repositories/i_ia_repository.dart';
import 'package:baara/app/features/ia/presentation/controllers/chatbot_controller.dart';

class _FakeIaRepository implements IIaRepository {
  AiChatResponse? chatResponse;

  @override
  Future<AiChatResponse> chatSend({
    required String message,
    String? sessionId,
  }) async {
    return chatResponse ??
        const AiChatResponse(
          reply: 'Réponse test',
          sessionId: 'sess-1',
          ctaActions: [],
        );
  }

  @override
  Future<List<Map<String, dynamic>>> chatSessions() async => [];

  @override
  Future<List<Map<String, dynamic>>> chatSession(String sessionId) async => [];

  @override
  Future<bool> sendChatFeedback({
    required String sessionId,
    required int rating,
    int? assistantMessageIndex,
    String? comment,
    String? correction,
  }) async =>
      true;

  @override
  Future<AiCvAudit> cvAudit() async => const AiCvAudit(
        overallQuality: 80,
        atsFriendly: true,
        keywordsMissing: [],
        sections: {},
      );

  @override
  Future<AiProfileScore> profileScore() async => const AiProfileScore(
        overall: 70,
        breakdown: {},
        suggestions: [],
      );

  @override
  Future<AiCoverLetter> coverLetter({
    required String offerId,
    String tone = 'formal',
    String length = 'medium',
  }) async =>
      const AiCoverLetter(
        fullText: 'Lettre',
        tone: 'formal',
        length: 'medium',
        warnings: [],
      );

  @override
  Future<Map<String, dynamic>> cvAdapt(String offerId) async => {};

  @override
  Future<Map<String, dynamic>> cvAdaptApply(
          Map<String, dynamic> suggestions) async =>
      {};

  @override
  Future<Map<String, dynamic>> cvRewrite({
    String? section,
    String? content,
    String tone = 'professional',
  }) async =>
      {};

  @override
  Future<AiMatchFeedResponse> matchFeed({int limit = 20, bool rerank = true}) async =>
      const AiMatchFeedResponse(offers: [], count: 0, reranked: false);
}

void main() {
  late ChatbotController controller;
  late _FakeIaRepository fakeRepo;

  setUp(() {
    fakeRepo = _FakeIaRepository();
    controller = ChatbotController(fakeRepo);
  });

  group('ChatbotController', () {
    test('send adds user and assistant messages', () async {
      fakeRepo.chatResponse = const AiChatResponse(
        reply: 'Bonjour !',
        sessionId: 's1',
        ctaActions: [],
      );

      await controller.send('Salut');

      expect(controller.messages.length, greaterThanOrEqualTo(2));
      expect(controller.messages.last.content, 'Bonjour !');
      expect(controller.isSending.value, isFalse);
    });
  });
}
