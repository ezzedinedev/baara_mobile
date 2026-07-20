import 'package:jobaway/app/features/offers/data/models/application_model.dart';
import 'package:jobaway/app/features/offers/data/models/interview_detail_model.dart';
import 'package:jobaway/app/features/offers/data/models/job_proposal_model.dart';
import 'package:jobaway/app/features/offers/data/models/upcoming_interview_model.dart';
import 'package:jobaway/app/features/offers/domain/entities/apply_result.dart';
import 'package:jobaway/app/features/offers/domain/entities/matched_offer.dart';
import 'package:jobaway/app/features/offers/domain/entities/offer.dart';
import 'package:jobaway/app/features/offers/domain/entities/sector_option.dart';
import 'package:jobaway/app/features/offers/domain/repositories/i_offer_repository.dart';

/// Trace d'un appel à `respondToInterview`.
class InterviewCall {
  const InterviewCall(this.id, this.action, this.message, this.proposedDate);
  final String id;
  final InterviewAction action;
  final String? message;
  final DateTime? proposedDate;
}

/// Trace d'un appel à `respondToProposal`.
class ProposalCall {
  const ProposalCall(this.id, this.action, this.message);
  final String id;
  final JobProposalAction action;
  final String? message;
}

/// Double de test enregistrant les réponses aux entretiens et aux offres
/// d'emploi. Les autres méthodes du contrat renvoient des valeurs neutres :
/// aucun test de ce fichier ne les exerce.
class FakeOfferRepository implements IOfferRepository {
  FakeOfferRepository({this.respondSucceeds = true});

  /// Valeur rendue par `respondToInterview` / `respondToProposal`.
  final bool respondSucceeds;

  final interviewCalls = <InterviewCall>[];
  final proposalCalls = <ProposalCall>[];

  @override
  Future<bool> respondToInterview(
    String id, {
    required InterviewAction action,
    String? message,
    DateTime? proposedDate,
  }) async {
    interviewCalls.add(InterviewCall(id, action, message, proposedDate));
    return respondSucceeds;
  }

  @override
  Future<bool> respondToProposal(
    String id, {
    required JobProposalAction action,
    String? message,
  }) async {
    proposalCalls.add(ProposalCall(id, action, message));
    return respondSucceeds;
  }

  // ── Reste du contrat : non exercé ────────────────────────────────────────

  @override
  Future<ApplyResult> applyToOffer(String offerId,
          {Map<String, dynamic>? screeningAnswers}) =>
      throw UnimplementedError();

  @override
  Future<Offer?> getOfferById(String id) async => null;

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
  Future<List<ApplicationModel>> getMyApplications(
          {int page = 1, int perPage = 20}) async =>
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
  Future<List<JobProposalModel>> getJobProposals() async => [];

  @override
  Future<JobProposalModel?> getJobProposalDetail(String id) async => null;
}
