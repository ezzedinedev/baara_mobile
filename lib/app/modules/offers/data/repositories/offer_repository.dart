import '../../../../core/network/api_provider.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/application_model.dart';
import '../models/offer_model.dart';

class OfferRepository {
  const OfferRepository({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  final ApiProvider _apiProvider;

  Future<PaginatedResult<OfferModel>> getOffers({
    int page = 1,
    int perPage = 20,
    OfferFilter? filter,
    void Function(Map<String, dynamic> raw)? onRaw,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (filter != null) ...filter.toQueryParams(),
    };

    final query = _buildQuery(queryParams);
    final response = await _apiProvider.getJson('${ApiConstants.offers}$query');
    onRaw?.call(response);

    return _parsePaginatedResponse(response);
  }

  /// Public — utilise par le controller pour parser un payload deja en
  /// memoire (cache disque ou response API). Evite de devoir refaire
  /// l'appel API quand on hydrate depuis le cache au boot d'un ecran.
  PaginatedResult<OfferModel> parsePaginatedResponse(
      Map<String, dynamic> response) {
    return _parsePaginatedResponse(response);
  }

  /// Pareil pour la liste savedOffers : reutilise la logique de
  /// `getSavedOffers` sur un payload cache.
  List<OfferModel> parseSavedOffersResponse(Map<String, dynamic> response) {
    final data = response['data'];
    final List<dynamic> rawItems;
    if (data is List) {
      rawItems = data;
    } else if (data is Map && data['data'] is List) {
      rawItems = data['data'] as List;
    } else {
      return <OfferModel>[];
    }
    return rawItems
        .whereType<Map<String, dynamic>>()
        .map<OfferModel?>((entry) {
          final nested = entry['offer'];
          if (nested is Map<String, dynamic>) {
            return OfferModel.fromJson(nested);
          }
          if (entry['title'] != null) return OfferModel.fromJson(entry);
          return null;
        })
        .whereType<OfferModel>()
        .toList();
  }

  /// Pareil pour applications : extrait la liste depuis le payload cache.
  List<ApplicationModel> parseMyApplicationsResponse(
      Map<String, dynamic> response) {
    final data = response['data'];
    final list = data is List
        ? data
        : (data is Map && data['data'] is List ? data['data'] as List : null);
    if (list == null) return <ApplicationModel>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map(ApplicationModel.fromJson)
        .toList();
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

  /// Backend renvoie un paginator de [SavedItem] (item_type=job_offer) avec
  /// la relation `offer` (employer + sector) eagerloadee. On extrait donc
  /// l'offre imbriquee, pas le SavedItem lui-meme.
  /// cf. `OfferApiController@saved` cote Laravel.
  Future<List<OfferModel>> getSavedOffers({
    int page = 1,
    int perPage = 20,
    void Function(Map<String, dynamic> raw)? onRaw,
  }) async {
    final response = await _apiProvider.getJson(
      '${ApiConstants.offersSaved}?page=$page&per_page=$perPage',
    );
    onRaw?.call(response);
    final data = response['data'];
    final List<dynamic> rawItems;
    if (data is List) {
      rawItems = data;
    } else if (data is Map && data['data'] is List) {
      rawItems = data['data'] as List;
    } else {
      return <OfferModel>[];
    }
    return rawItems
        .whereType<Map<String, dynamic>>()
        .map<OfferModel?>((entry) {
          // Cas attendu : SavedItem avec relation `offer` imbriquee.
          final nested = entry['offer'];
          if (nested is Map<String, dynamic>) {
            return OfferModel.fromJson(nested);
          }
          // Fallback : si le backend renvoie deja l'offre a plat (pour
          // d'eventuels endpoints rapides), on la consomme telle quelle.
          if (entry['title'] != null) {
            return OfferModel.fromJson(entry);
          }
          return null;
        })
        .whereType<OfferModel>()
        .toList();
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

  /// Crée une candidature via `POST /api/v1/applications`, en miroir exact
  /// du flux Laravel (`ApplicationApiController@store`).
  ///
  /// Le serveur impose : compte candidat, offre active, deadline non passée,
  /// CV présent (builder ou uploadé), pas de candidature existante (UNIQUE
  /// `offer_id` + `candidate_id`). Chaque violation lève une [ApplyException]
  /// typée pour que l'UI choisisse le message approprié.
  Future<ApplicationModel> applyToOffer(
    String offerId, {
    Map<String, dynamic>? screeningAnswers,
  }) async {
    final payload = <String, dynamic>{
      'offer_id': offerId,
      if (screeningAnswers != null) 'screening_answers': screeningAnswers,
    };

    final response = await _apiProvider.postJson(
      ApiConstants.applications,
      payload,
    );

    final statusCode = response['statusCode'] as int?;
    final success = response['success'] == true;
    final message = _extractMessage(response);

    if (success && (statusCode == 201 || statusCode == 200)) {
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        return ApplicationModel.fromJson(data);
      }
      throw const ApplyException(
        ApplyFailureReason.unknown,
        'Réponse inattendue du serveur.',
      );
    }

    throw ApplyException(_mapFailureReason(statusCode, message), message);
  }

  /// Liste les candidatures de l'utilisateur connecté.
  /// Leve une exception si le backend renvoie une erreur (401/403/5xx) —
  /// sinon le bug etait masque car le parser tombait sur `data` non-list
  /// et retournait silencieusement une liste vide ("Aucune candidature").
  Future<List<ApplicationModel>> getMyApplications({
    int page = 1,
    int perPage = 20,
    String? status,
    void Function(Map<String, dynamic> raw)? onRaw,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (status != null) 'status': status,
    };
    final response = await _apiProvider.getJson(
      '${ApiConstants.applications}${_buildQuery(queryParams)}',
    );
    onRaw?.call(response);

    final statusCode = response['statusCode'] as int?;
    final success = response['success'] == true;
    if (!success || (statusCode != null && statusCode >= 400)) {
      throw _ApiCallException(
        statusCode: statusCode,
        message: _extractMessage(response),
      );
    }

    final data = response['data'];
    final list = data is List
        ? data
        : (data is Map && data['data'] is List ? data['data'] as List : null);
    if (list == null) return <ApplicationModel>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map(ApplicationModel.fromJson)
        .toList();
  }

  String _extractMessage(Map<String, dynamic> response) {
    final raw = response['message']?.toString();
    if (raw != null && raw.trim().isNotEmpty) return raw;
    final errors = response['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
      return first.toString();
    }
    return 'Erreur lors de l\'envoi de la candidature.';
  }

  ApplyFailureReason _mapFailureReason(int? statusCode, String message) {
    switch (statusCode) {
      case 401:
        return ApplyFailureReason.unauthorized;
      case 403:
        return ApplyFailureReason.notCandidate;
      case 400:
        return ApplyFailureReason.invalidOffer;
    }

    if (statusCode == 422) {
      final lc = message.toLowerCase();
      if (lc.contains('deja postule') ||
          lc.contains('déjà postulé') ||
          lc.contains('already applied')) {
        return ApplyFailureReason.alreadyApplied;
      }
      if (lc.contains('deadline') ||
          lc.contains('expir') ||
          lc.contains('cloture') ||
          lc.contains('clôtur') ||
          lc.contains('passé')) {
        return ApplyFailureReason.deadlinePassed;
      }
      if (lc.contains('cv') || lc.contains('curriculum')) {
        return ApplyFailureReason.noCv;
      }
      if (lc.contains('active') ||
          lc.contains('publi') ||
          lc.contains('fermée') ||
          lc.contains('fermee')) {
        return ApplyFailureReason.offerNotActive;
      }
    }

    return ApplyFailureReason.unknown;
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

/// Exception interne levee quand un appel API renvoie une enveloppe
/// `{success: false}` ou un statut HTTP >= 400. Sert a faire remonter
/// le message backend au controller (qui le passe a `_friendlyError`).
class _ApiCallException implements Exception {
  const _ApiCallException({this.statusCode, required this.message});

  final int? statusCode;
  final String message;

  @override
  String toString() => 'API ${statusCode ?? '??'}: $message';
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
