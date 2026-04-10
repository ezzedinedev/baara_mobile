import '../../../data/providers/api_provider.dart';
import '../../../core/constants/api_constants.dart';
import '../models/offer_model.dart';

class OfferRepository {
  const OfferRepository({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  final ApiProvider _apiProvider;

  Future<PaginatedResult<OfferModel>> getOffers({
    int page = 1,
    int perPage = 20,
    OfferFilter? filter,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (filter != null) ...filter.toQueryParams(),
    };

    final query = _buildQuery(queryParams);
    final response = await _apiProvider.getJson('${ApiConstants.offers}$query');

    return _parsePaginatedResponse(response);
  }

  Future<OfferModel?> getOfferById(String id) async {
    final response = await _apiProvider.getJson('${ApiConstants.offers}/$id');
    if (response['success'] == true && response['data'] != null) {
      return OfferModel.fromJson(response['data']);
    }
    return null;
  }

  Future<List<OfferModel>> getFeaturedOffers() async {
    final response = await _apiProvider.getJson(ApiConstants.offersFeatured);
    return _parseListResponse(response);
  }

  Future<List<OfferModel>> getSavedOffers(
      {int page = 1, int perPage = 20}) async {
    final response = await _apiProvider.getJson(
      '${ApiConstants.offersSaved}?page=$page&per_page=$perPage',
    );
    return _parseListResponse(response);
  }

  Future<bool> saveOffer(String offerId) async {
    final response = await _apiProvider.postJson(
      '${ApiConstants.offers}/$offerId/save',
      {},
    );
    return response['success'] == true;
  }

  Future<bool> unsaveOffer(String offerId) async {
    final response = await _apiProvider.deleteJson(
      '${ApiConstants.offers}/$offerId/save',
    );
    return response['success'] == true;
  }

  Future<bool> applyToOffer(String offerId,
      {Map<String, dynamic>? data}) async {
    final response = await _apiProvider.postJson(
      '${ApiConstants.offers}/$offerId/apply',
      data ?? {},
    );
    return response['success'] == true;
  }

  Future<List<SectorModel>> getSectors() async {
    final response = await _apiProvider.getJson(ApiConstants.sectors);
    if (response['success'] == true && response['data'] != null) {
      final list = response['data'] as List;
      return list.map((e) => SectorModel.fromJson(e)).toList();
    }
    return [];
  }

  String _buildQuery(Map<String, dynamic> params) {
    if (params.isEmpty) return '';
    final query = params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
    return '?$query';
  }

  PaginatedResult<OfferModel> _parsePaginatedResponse(
      Map<String, dynamic> response) {
    final data = response['data'];
    List<OfferModel> items = [];
    int currentPage = 1;
    int totalPages = 1;
    int total = 0;

    if (data is List) {
      items = data.map((e) => OfferModel.fromJson(e)).toList();
    } else if (data is Map) {
      if (data['data'] is List) {
        items =
            (data['data'] as List).map((e) => OfferModel.fromJson(e)).toList();
      }
      currentPage = data['current_page'] ?? 1;
      totalPages = data['last_page'] ?? 1;
      total = data['total'] ?? 0;
    }

    return PaginatedResult(
      items: items,
      currentPage: currentPage,
      totalPages: totalPages,
      total: total,
    );
  }

  List<OfferModel> _parseListResponse(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is List) {
      return data.map((e) => OfferModel.fromJson(e)).toList();
    }
    return [];
  }
}

class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.total,
  });

  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int total;

  bool get hasNextPage => currentPage < totalPages;
  bool get hasPreviousPage => currentPage > 1;
}
