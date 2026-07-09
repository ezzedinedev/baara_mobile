import 'package:flutter_test/flutter_test.dart';
import 'package:opportune_bf/app/features/offers/data/models/application_model.dart';
import 'package:opportune_bf/app/features/offers/data/models/upcoming_interview_model.dart';
import 'package:opportune_bf/app/features/offers/data/models/interview_detail_model.dart';
import 'package:opportune_bf/app/features/offers/data/models/job_proposal_model.dart';
import 'package:opportune_bf/app/features/offers/domain/entities/apply_result.dart';
import 'package:opportune_bf/app/features/offers/domain/entities/offer.dart';
import 'package:opportune_bf/app/features/offers/domain/entities/matched_offer.dart';
import 'package:opportune_bf/app/features/offers/domain/entities/sector_option.dart';
import 'package:opportune_bf/app/features/offers/domain/repositories/i_offer_repository.dart';
import 'package:opportune_bf/app/features/offers/presentation/controllers/offer_detail_controller.dart';
import 'package:opportune_bf/app/features/ia/domain/repositories/i_ia_repository.dart';
import 'package:opportune_bf/app/data/models/ai_models.dart';

class _FakeOfferRepository implements IOfferRepository {
  Offer? offerById;

  @override
  Future<Offer?> getOfferById(String id) async => offerById;

  @override
  Future<List<Offer>> getOffers({
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
      [];

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
  Future<Map<String, dynamic>> cvAdaptApply(String offerId) async => {};

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

void main() {
  late OfferDetailController controller;
  late _FakeOfferRepository fakeOfferRepo;

  setUp(() {
    fakeOfferRepo = _FakeOfferRepository();
    controller = OfferDetailController(fakeOfferRepo, _FakeIaRepository());
  });

  group('OfferDetailController', () {
    test('fetches offer successfully', () async {
      fakeOfferRepo.offerById = const Offer(
        id: '1',
        title: 'Dev Flutter',
        company: 'Opportune',
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
}
