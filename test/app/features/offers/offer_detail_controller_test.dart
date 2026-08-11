import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:baara/routes/app_routes.dart';
import 'package:baara/app/features/offers/data/models/application_model.dart';
import 'package:baara/app/features/offers/data/models/upcoming_interview_model.dart';
import 'package:baara/app/features/offers/data/models/interview_detail_model.dart';
import 'package:baara/app/features/offers/data/models/job_proposal_model.dart';
import 'package:baara/app/features/offers/domain/entities/apply_result.dart';
import 'package:baara/app/features/offers/domain/entities/offer.dart';
import 'package:baara/app/features/offers/domain/entities/matched_offer.dart';
import 'package:baara/app/features/offers/domain/entities/sector_option.dart';
import 'package:baara/app/features/offers/domain/repositories/i_offer_repository.dart';
import 'package:baara/app/features/offers/presentation/controllers/offer_detail_controller.dart';
import 'package:baara/app/features/ia/domain/repositories/i_ia_repository.dart';
import 'package:baara/app/data/models/ai_models.dart';

class _FakeOfferRepository implements IOfferRepository {
  Offer? offerById;

  /// Offres réellement candidatées — c'est ce qui manquait : l'ancien
  /// « Adapter + postuler » n'appelait jamais applyToOffer.
  final appliedOfferIds = <String>[];

  @override
  Future<Offer?> getOfferById(String id) async => offerById;

  @override
  Future<OfferPage> getOffers({
    int page = 1,
    int perPage = 20,
    String? search,
    String? sectorId,
    String? contractType,
    String? city,
    String? region,
    bool? isRemote,
    int? salaryMin,
    String? sort,
  }) async =>
      const OfferPage(items: [], currentPage: 1, hasMore: false);

  @override
  Future<List<SectorOption>> getSectors() async => [];

  @override
  Future<List<Offer>> getFeaturedOffers() async => [];

  @override
  Future<List<MatchedOffer>> getMatchedOffers({int limit = 20}) async => [];

  @override
  Future<bool> saveOffer(String offerId) async => true;

  @override
  Future<bool> unsaveOffer(String offerId) async => true;

  @override
  Future<List<Offer>> getSavedOffers() async => [];

  @override
  Future<ApplyResult> applyToOffer(
    String offerId, {
    Map<String, dynamic>? screeningAnswers,
  }) async {
    appliedOfferIds.add(offerId);
    return ApplyResult(
      application: ApplicationModel(
        id: 'app-1',
        offerId: offerId,
        candidateId: 'cand-1',
        status: ApplicationStatus.newApp,
        appliedAt: DateTime.now(),
        aiMatchScore: 0,
        screeningScore: 0,
      ),
      isMatch: false,
      score: 0,
    );
  }

  @override
  Future<List<ApplicationModel>> getMyApplications({
    int page = 1,
    int perPage = 20,
  }) async =>
      [];

  @override
  Future<ApplicationModel?> getApplicationDetail(String id) async => null;

  @override
  Future<bool> withdrawApplication(String id) async => true;

  @override
  Future<List<UpcomingInterview>> getUpcomingInterviews() async => [];

  @override
  Future<List<InterviewDetailModel>> getInterviews() async => [];

  @override
  Future<InterviewDetailModel?> getInterviewDetail(String id) async => null;

  @override
  Future<bool> respondToInterview(
    String id, {
    required InterviewAction action,
    String? message,
    DateTime? proposedDate,
  }) async =>
      true;

  @override
  Future<List<JobProposalModel>> getJobProposals() async => [];

  @override
  Future<JobProposalModel?> getJobProposalDetail(String id) async => null;

  @override
  Future<bool> respondToProposal(
    String id, {
    required JobProposalAction action,
    String? message,
  }) async =>
      true;
}

class _FakeIaRepository implements IIaRepository {
  /// Réponse simulée de `/ai/cv/adapt`.
  Map<String, dynamic> adaptResult = const {
    'suggestions': {
      'bio': {'suggested': 'Nouvelle bio'},
    },
  };

  /// Lève sur l'écriture au CV, pour vérifier que la candidature part quand même.
  bool failOnAdaptApply = false;

  final cvAdaptOfferIds = <String>[];
  final cvAdaptApplyPayloads = <Map<String, dynamic>>[];

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
  Future<Map<String, dynamic>> cvAdapt(String offerId) async {
    cvAdaptOfferIds.add(offerId);
    return adaptResult;
  }

  @override
  Future<Map<String, dynamic>> cvAdaptApply(
      Map<String, dynamic> suggestions) async {
    cvAdaptApplyPayloads.add(suggestions);
    if (failOnAdaptApply) {
      throw Exception('no_applicable_suggestion');
    }
    return {};
  }

  @override
  Future<AiCvAudit> cvAudit() async => const AiCvAudit(
        overallQuality: 0,
        atsFriendly: true,
        keywordsMissing: [],
        sections: {},
      );

  @override
  Future<AiMatchFeedResponse> matchFeed({
    int limit = 20,
    bool rerank = true,
  }) async =>
      const AiMatchFeedResponse(offers: [], count: 0, reranked: false);

  @override
  Future<AiProfileScore> profileScore() async => const AiProfileScore(
        overall: 0,
        breakdown: {},
        suggestions: [],
      );

  @override
  Future<Map<String, dynamic>> cvRewrite({
    String? section,
    String? content,
    String tone = 'professional',
  }) async =>
      {};

  @override
  Future<AiChatResponse> chatSend({
    required String message,
    String? sessionId,
  }) async =>
      const AiChatResponse(reply: '', ctaActions: []);

  @override
  Future<List<Map<String, dynamic>>> chatSession(String sessionId) async => [];

  @override
  Future<List<Map<String, dynamic>>> chatSessions() async => [];

  @override
  Future<bool> sendChatFeedback({
    required String sessionId,
    required int rating,
    int? assistantMessageIndex,
    String? comment,
    String? correction,
  }) async =>
      true;
}

const _offer = Offer(
  id: '1',
  title: 'Dev Flutter',
  company: 'Baara',
  description: 'Desc',
  location: 'Ouaga',
  salary: '400 000 FCFA',
  contractType: 'CDI',
  requiredSkills: ['Flutter'],
  minYearsExperience: 2,
  sector: 'Informatique',
  isRemote: false,
);

void main() {
  late OfferDetailController controller;
  late _FakeOfferRepository fakeOfferRepo;
  late _FakeIaRepository fakeIaRepo;

  setUp(() {
    fakeOfferRepo = _FakeOfferRepository();
    fakeIaRepo = _FakeIaRepository();
    controller = OfferDetailController(fakeOfferRepo, fakeIaRepo);
  });

  group('OfferDetailController', () {
    test('fetches offer successfully', () async {
      fakeOfferRepo.offerById = const Offer(
        id: '1',
        title: 'Dev Flutter',
        company: 'Baara',
        description: 'Desc',
        location: 'Ouaga',
        salary: '400 000 FCFA',
        contractType: 'CDI',
        requiredSkills: ['Flutter'],
        minYearsExperience: 2,
        sector: 'Informatique',
        isRemote: false,
      );

      await controller.fetchOfferDetail('1');

      expect(controller.offer.value?.id, '1');
      expect(controller.isLoading.value, false);
    });

    test('handles missing offer correctly', () async {
      fakeOfferRepo.offerById = null;

      await controller.fetchOfferDetail('1');

      expect(controller.offer.value, null);
      expect(controller.errorMessage.value, 'Offre introuvable');
    });
  });

  // `/ai/cv/adapt/apply` applique les suggestions AU CV — il ne postule pas.
  // L'implémentation précédente l'appelait seul, avec `offer_id` au lieu de
  // `suggestions` : 422 systématique, et aucune candidature n'était créée.
  //
  // `testWidgets` et non `test` : le chemin de succès de `apply()` déclenche
  // haptique, confetti et feuille de confirmation, qui exigent un arbre de
  // widgets et un contexte GetX.
  group('OfferDetailController.adaptCvAndApply', () {
    tearDown(Get.reset);

    Future<void> pumpShell(WidgetTester tester) async {
      Get.put(controller);
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/accueil',
          getPages: [
            GetPage(
                name: '/accueil', page: () => const Scaffold(body: SizedBox())),
            GetPage(
              name: AppRoutes.offerMatch,
              page: () => const Scaffold(body: Text('CELEBRATION')),
            ),
          ],
        ),
      );
      fakeOfferRepo.offerById = _offer;
      await controller.fetchOfferDetail('1');
      await tester.pump();
    }

    /// Laisse retomber toasts et feuilles : un snackbar GetX laisse un Ticker
    /// actif qui ferait échouer le teardown.
    Future<void> settle(WidgetTester tester) async {
      await tester.pump();
      Get.closeAllSnackbars();
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('adapte le CV puis postule réellement', (tester) async {
      await pumpShell(tester);

      await controller.adaptCvAndApply();
      await settle(tester);

      expect(fakeIaRepo.cvAdaptOfferIds, ['1']);
      expect(fakeOfferRepo.appliedOfferIds, ['1'],
          reason: 'la candidature doit partir, pas seulement l\'adaptation');
      expect(controller.hasApplied.value, isTrue);
    });

    testWidgets('envoie les suggestions, jamais offer_id', (tester) async {
      await pumpShell(tester);

      await controller.adaptCvAndApply();
      await settle(tester);

      expect(fakeIaRepo.cvAdaptApplyPayloads, hasLength(1));
      final payload = fakeIaRepo.cvAdaptApplyPayloads.single;
      expect(payload, contains('bio'));
      expect(payload, isNot(contains('offer_id')));
    });

    testWidgets('postule même si aucune suggestion n\'est applicable',
        (tester) async {
      await pumpShell(tester);
      fakeIaRepo.failOnAdaptApply = true;

      await controller.adaptCvAndApply();
      await settle(tester);

      expect(fakeOfferRepo.appliedOfferIds, ['1']);
      expect(controller.hasApplied.value, isTrue);
    });

    testWidgets('ne postule pas deux fois', (tester) async {
      await pumpShell(tester);

      await controller.adaptCvAndApply();
      await settle(tester);
      await controller.adaptCvAndApply();
      await settle(tester);

      expect(fakeOfferRepo.appliedOfferIds, hasLength(1));
    });

    testWidgets('sans bloc suggestions, postule quand même', (tester) async {
      await pumpShell(tester);
      fakeIaRepo.adaptResult = const {};

      await controller.adaptCvAndApply();
      await settle(tester);

      expect(fakeIaRepo.cvAdaptApplyPayloads, isEmpty);
      expect(fakeOfferRepo.appliedOfferIds, ['1']);
    });
  });
}
