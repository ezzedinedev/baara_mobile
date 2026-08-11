import '../entities/apply_result.dart';
import '../entities/offer.dart';
import '../entities/matched_offer.dart';
import '../entities/sector_option.dart';
import '../../data/models/application_model.dart';
import '../../data/models/upcoming_interview_model.dart';
import '../../data/models/interview_detail_model.dart';
import '../../data/models/job_proposal_model.dart';

/// Résultat paginé de la liste d'offres (parité `OfferApiController@index`).
class OfferPage {
  final List<Offer> items;
  final int currentPage;
  final bool hasMore;

  const OfferPage({
    required this.items,
    required this.currentPage,
    required this.hasMore,
  });
}

abstract class IOfferRepository {
  /// Liste paginée des offres. Tous les filtres sont appliqués côté serveur
  /// (parité web — cf. OfferApiController@index : search, sector_id,
  /// contract_type, city, region, is_remote, salary_min, sort).
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
  });
  Future<Offer?> getOfferById(String id);
  Future<List<Offer>> getFeaturedOffers();

  /// Liste des secteurs d'activité pour peupler le filtre (GET
  /// /offers/sectors/list → [{id, name}]).
  Future<List<SectorOption>> getSectors();

  /// Offres recommandées par l'IA (match feed). Liste vide si l'utilisateur
  /// n'a pas de CV ou si aucune offre indexée.
  Future<List<MatchedOffer>> getMatchedOffers({int limit = 20});
  Future<bool> saveOffer(String offerId);
  Future<bool> unsaveOffer(String offerId);

  /// Offres enregistrées par le candidat (GET /offers/saved/list).
  Future<List<Offer>> getSavedOffers();

  // Applications
  Future<ApplyResult> applyToOffer(String offerId,
      {Map<String, dynamic>? screeningAnswers});
  Future<List<ApplicationModel>> getMyApplications(
      {int page = 1, int perPage = 20});

  /// Détail d'une candidature (GET /applications/{id}).
  Future<ApplicationModel?> getApplicationDetail(String id);

  /// Retire (désiste) une candidature (DELETE /applications/{id}).
  Future<bool> withdrawApplication(String id);

  /// Entretiens à venir (géoloc + itinéraire + .ics).
  /// GET /applications/interviews/upcoming.
  Future<List<UpcomingInterview>> getUpcomingInterviews();

  // ── Pipeline entretien (invitation → réponse) ──────────────────────────────

  /// Liste des entretiens du candidat (en attente / confirmés / report demandé).
  /// GET /applications/interviews.
  Future<List<InterviewDetailModel>> getInterviews();

  /// Détail d'un entretien. GET /applications/interviews/{id}.
  Future<InterviewDetailModel?> getInterviewDetail(String id);

  /// Réponse à une invitation d'entretien. POST /applications/interviews/{id}/respond.
  /// [proposedDate] est REQUIS lorsque [action] == reschedule.
  /// Retourne true si la réponse a été enregistrée.
  Future<bool> respondToInterview(
    String id, {
    required InterviewAction action,
    String? message,
    DateTime? proposedDate,
  });

  // ── Offres d'emploi formelles ──────────────────────────────────────────────

  /// Offres d'emploi reçues par le candidat. GET /applications/job-proposals.
  Future<List<JobProposalModel>> getJobProposals();

  /// Détail d'une offre d'emploi. GET /applications/job-proposals/{id}.
  Future<JobProposalModel?> getJobProposalDetail(String id);

  /// Réponse à une offre d'emploi. POST /applications/job-proposals/{id}/respond.
  /// [message] est REQUIS lorsque [action] == negotiate.
  /// Retourne true si la réponse a été enregistrée.
  Future<bool> respondToProposal(
    String id, {
    required JobProposalAction action,
    String? message,
  });
}
