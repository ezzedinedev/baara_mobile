import 'package:baara/app/core/network/api_provider.dart';
import 'package:baara/app/core/network/api_response.dart';
import 'package:baara/app/core/constants/api_constants.dart';
import '../../domain/entities/apply_result.dart';
import '../../domain/entities/offer.dart';
import '../../domain/entities/matched_offer.dart';
import '../../domain/entities/sector_option.dart';
import '../../domain/repositories/i_offer_repository.dart';
import '../models/offer_model.dart';
import '../../domain/exceptions/missing_skills_exception.dart';
import '../models/application_model.dart';
import '../models/upcoming_interview_model.dart';
import '../models/interview_detail_model.dart';
import '../models/job_proposal_model.dart';

/// Implémentation concrète du dépôt d'offres utilisant une API REST.
class OfferRepositoryImpl implements IOfferRepository {
  final ApiProvider _apiProvider;

  OfferRepositoryImpl({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  List<dynamic> _extractList(dynamic data) => ApiResponse.extractList(data);

  List<dynamic> _extractOfferList(dynamic data) => _extractList(data);

  Map<String, dynamic>? _extractItem(dynamic data) =>
      ApiResponse.extractItem(data);

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
  }) async {
    final params = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (sectorId != null && sectorId.isNotEmpty) 'sector_id': sectorId,
      if (contractType != null && contractType.isNotEmpty)
        'contract_type': contractType,
      if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
      if (region != null && region.isNotEmpty) 'region': region,
      if (isRemote == true) 'is_remote': '1',
      if (salaryMin != null && salaryMin > 0) 'salary_min': '$salaryMin',
      if (sort != null && sort.isNotEmpty) 'sort': sort,
      'match': '1',
    };
    final query = params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final response =
        await _apiProvider.getJson('${ApiConstants.offers}?$query');
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de charger les offres.');

    final data = response['data'];
    final items = _extractOfferList(data)
        .map((json) => OfferModel.fromJson(json as Map<String, dynamic>))
        .toList();

    return OfferPage(
      items: items,
      currentPage: ApiResponse.currentPage(data, fallback: page),
      hasMore: ApiResponse.hasMorePages(
        data,
        pageSize: perPage,
        itemCount: items.length,
      ),
    );
  }

  @override
  Future<List<SectorOption>> getSectors() async {
    final response = await _apiProvider.getJson(ApiConstants.sectors);
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de charger les secteurs.');
    return _extractList(response['data'])
        .whereType<Map<String, dynamic>>()
        .map(SectorOption.fromJson)
        .toList();
  }

  @override
  Future<Offer?> getOfferById(String id) async {
    final response = await _apiProvider.getJson('${ApiConstants.offers}/$id');
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de charger cette offre.');
    final item = _extractItem(response['data']);
    if (item != null) return OfferModel.fromJson(item);
    return null;
  }

  @override
  Future<List<Offer>> getFeaturedOffers() async {
    final response = await _apiProvider.getJson(ApiConstants.offersFeatured);
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de charger les offres à la une.');
    return _extractList(response['data'])
        .map((json) => OfferModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<MatchedOffer>> getMatchedOffers({int limit = 20}) async {
    final response =
        await _apiProvider.getJson('${ApiConstants.aiMatchFeed}?limit=$limit');
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de charger les recommandations.');
    final data = response['data'] as Map<String, dynamic>? ?? const {};
    final offers = data['offers'] as List? ?? const [];
    return offers
        .whereType<Map<String, dynamic>>()
        .map((j) {
          final raw = (j['match_score'] as num?)?.toDouble() ?? 0;
          final score = (raw <= 1 ? raw * 100 : raw).round().clamp(0, 100);
          return MatchedOffer(
            id: j['id']?.toString() ?? '',
            title: j['title']?.toString() ?? '',
            company: j['company_name']?.toString() ?? '',
            location: j['location']?.toString() ?? '',
            score: score,
            explanation: j['match_explanation']?.toString() ?? '',
          );
        })
        .where((m) => m.id.isNotEmpty)
        .toList();
  }

  @override
  Future<bool> saveOffer(String offerId) async {
    final response = await _apiProvider.postJson(
      ApiConstants.offerSavePath(offerId),
      {},
    );
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible d\'enregistrer cette offre.');
    return true;
  }

  @override
  Future<bool> unsaveOffer(String offerId) async {
    final response = await _apiProvider.deleteJson(
      ApiConstants.offerSavePath(offerId),
    );
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de retirer cette offre des favoris.');
    return true;
  }

  @override
  Future<List<Offer>> getSavedOffers() async {
    final response = await _apiProvider.getJson(ApiConstants.offersSaved);
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de charger vos offres enregistrées.');
    return _extractList(response['data'])
        .whereType<Map<String, dynamic>>()
        .map(OfferModel.fromJson)
        .toList();
  }

  @override
  Future<ApplyResult> applyToOffer(String offerId,
      {Map<String, dynamic>? screeningAnswers}) async {
    final response = await _apiProvider.postJson(
      ApiConstants.applications,
      {
        'offer_id': offerId,
        if (screeningAnswers != null) 'screening_answers': screeningAnswers,
      },
    );
    if (response['success'] == true && response['data'] != null) {
      final app =
          ApplicationModel.fromJson(response['data'] as Map<String, dynamic>);
      final match = response['match'] as Map<String, dynamic>?;
      final isMatch =
          match?['is_match'] == true || response['is_match'] == true;
      final score = (match?['score'] as num?)?.toInt() ?? 0;
      return ApplyResult(application: app, isMatch: isMatch, score: score);
    }

    final data = response['data'];
    if (data is Map && data['requires_skills'] == true) {
      throw MissingSkillsException(
        response['message']?.toString() ??
            'Ajoutez vos compétences à votre CV avant de postuler.',
      );
    }

    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible d\'envoyer votre candidature.');
    throw ApiException(
      message: response['message']?.toString() ??
          'Impossible d\'envoyer votre candidature.',
      statusCode: response['statusCode'] as int?,
    );
  }

  @override
  Future<List<ApplicationModel>> getMyApplications(
      {int page = 1, int perPage = 20}) async {
    final response = await _apiProvider.getJson(
      '${ApiConstants.applications}?page=$page&per_page=$perPage',
    );
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de charger vos candidatures.');
    return _extractList(response['data'])
        .map(
            (json) => ApplicationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ApplicationModel?> getApplicationDetail(String id) async {
    final response = await _apiProvider.getJson(ApiConstants.application(id));
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de charger cette candidature.');
    final json = _extractItem(response['data']);
    if (json != null) return ApplicationModel.fromJson(json);
    return null;
  }

  @override
  Future<bool> withdrawApplication(String id) async {
    final response =
        await _apiProvider.deleteJson(ApiConstants.application(id));
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de retirer cette candidature.');
    return true;
  }

  @override
  Future<List<UpcomingInterview>> getUpcomingInterviews() async {
    final response =
        await _apiProvider.getJson(ApiConstants.applicationsInterviewsUpcoming);
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de charger vos entretiens.');
    return _extractList(response['data'])
        .whereType<Map<String, dynamic>>()
        .map(UpcomingInterview.fromJson)
        .toList();
  }

  @override
  Future<List<InterviewDetailModel>> getInterviews() async {
    final response =
        await _apiProvider.getJson(ApiConstants.applicationsInterviews);
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de charger vos entretiens.');
    return _extractList(response['data'])
        .whereType<Map<String, dynamic>>()
        .map(InterviewDetailModel.fromJson)
        .toList();
  }

  @override
  Future<InterviewDetailModel?> getInterviewDetail(String id) async {
    final response =
        await _apiProvider.getJson(ApiConstants.applicationInterview(id));
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de charger cet entretien.');
    final json = _extractItem(response['data']);
    if (json != null) return InterviewDetailModel.fromJson(json);
    return null;
  }

  @override
  Future<bool> respondToInterview(
    String id, {
    required InterviewAction action,
    String? message,
    DateTime? proposedDate,
  }) async {
    final response = await _apiProvider.postJson(
      ApiConstants.applicationInterviewRespond(id),
      {
        'action': action.wire,
        if (message != null && message.trim().isNotEmpty)
          'message': message.trim(),
        if (proposedDate != null)
          'proposed_date': proposedDate.toIso8601String(),
      },
    );
    if (response['success'] == true || response['ok'] == true) return true;
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible d\'envoyer votre réponse.');
    return false;
  }

  @override
  Future<List<JobProposalModel>> getJobProposals() async {
    final response = await _apiProvider.getJson(ApiConstants.jobProposals);
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de charger vos offres d\'emploi.');
    return _extractList(response['data'])
        .whereType<Map<String, dynamic>>()
        .map(JobProposalModel.fromJson)
        .toList();
  }

  @override
  Future<JobProposalModel?> getJobProposalDetail(String id) async {
    final response = await _apiProvider.getJson(ApiConstants.jobProposal(id));
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de charger cette proposition.');
    final json = _extractItem(response['data']);
    if (json != null) return JobProposalModel.fromJson(json);
    return null;
  }

  @override
  Future<bool> respondToProposal(
    String id, {
    required JobProposalAction action,
    String? message,
  }) async {
    final response = await _apiProvider.postJson(
      ApiConstants.jobProposalRespond(id),
      {
        'action': action.wire,
        if (message != null && message.trim().isNotEmpty)
          'message': message.trim(),
      },
    );
    if (response['success'] == true || response['ok'] == true) return true;
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible d\'envoyer votre réponse.');
    return false;
  }
}
