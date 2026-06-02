import 'package:opportune_bf/app/core/network/api_provider.dart';
import 'package:opportune_bf/app/core/constants/api_constants.dart';
import '../../domain/entities/offer.dart';
import '../../domain/repositories/i_offer_repository.dart';
import '../models/offer_model.dart';
import '../models/application_model.dart';
import '../models/upcoming_interview_model.dart';

/// Implémentation concrète du dépôt d'offres utilisant une API REST.
class OfferRepositoryImpl implements IOfferRepository {
  final ApiProvider _apiProvider;

  OfferRepositoryImpl({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  /// Extrait une liste depuis les différentes formes d'enveloppe renvoyées
  /// par l'API : liste directe, paginator Laravel (`data`), ou `{items: [...]}`
  /// (forme utilisée par le endpoint /offers).
  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      if (data['items'] is List) return data['items'] as List;
      if (data['data'] is List) return data['data'] as List;
    }
    return const [];
  }

  // Conservé pour compat sémantique avec getOffers (alias).
  List<dynamic> _extractOfferList(dynamic data) => _extractList(data);

  /// Pour un endpoint "show" : l'offre peut être sous `data` directement ou
  /// sous `data.item`.
  Map<String, dynamic>? _extractItem(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['item'] is Map<String, dynamic>) {
        return data['item'] as Map<String, dynamic>;
      }
      return data;
    }
    return null;
  }

  @override
  Future<List<Offer>> getOffers({int page = 1, int perPage = 20}) async {
    try {
      final response = await _apiProvider.getJson(
        '${ApiConstants.offers}?page=$page&per_page=$perPage',
      );

      if (response['success'] == true) {
        return _extractOfferList(response['data'])
            .map((json) => OfferModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<Offer?> getOfferById(String id) async {
    try {
      final response = await _apiProvider.getJson('${ApiConstants.offers}/$id');
      if (response['success'] == true) {
        final item = _extractItem(response['data']);
        if (item != null) return OfferModel.fromJson(item);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Offer>> getFeaturedOffers() async {
    try {
      final response = await _apiProvider.getJson(ApiConstants.offersFeatured);
      if (response['success'] == true) {
        return _extractList(response['data'])
            .map((json) => OfferModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<bool> saveOffer(String offerId) async {
    try {
      final response = await _apiProvider.postJson(
        ApiConstants.offerSavePath(offerId),
        {},
      );
      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> unsaveOffer(String offerId) async {
    try {
      final response = await _apiProvider.deleteJson(
        ApiConstants.offerSavePath(offerId),
      );
      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<ApplicationModel> applyToOffer(String offerId, {Map<String, dynamic>? screeningAnswers}) async {
    final response = await _apiProvider.postJson(
      ApiConstants.applications,
      {
        'offer_id': offerId,
        if (screeningAnswers != null) 'screening_answers': screeningAnswers,
      },
    );
    if (response['success'] == true && response['data'] != null) {
      return ApplicationModel.fromJson(response['data']);
    }
    throw Exception(response['message'] ?? 'Failed to apply');
  }

  @override
  Future<List<ApplicationModel>> getMyApplications({int page = 1, int perPage = 20}) async {
    final response = await _apiProvider.getJson(
      '${ApiConstants.applications}?page=$page&per_page=$perPage',
    );
    if (response['success'] == true) {
      return _extractList(response['data'])
          .map((json) => ApplicationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<UpcomingInterview>> getUpcomingInterviews() async {
    final response =
        await _apiProvider.getJson(ApiConstants.applicationsInterviewsUpcoming);
    if (response['success'] == true) {
      return _extractList(response['data'])
          .whereType<Map<String, dynamic>>()
          .map(UpcomingInterview.fromJson)
          .toList();
    }
    return [];
  }
}
