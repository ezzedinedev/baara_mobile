import 'dart:convert';

import 'package:opportune_bf/app/core/constants/api_constants.dart';
import 'package:opportune_bf/app/core/network/api_provider.dart';

import '../../domain/entities/portfolio_item.dart';

/// CRUD du portfolio candidat (GET/POST /profile/portfolio, PUT/DELETE /{item}).
/// Supporte l'upload d'images (`media_uploads[]`) via multipart.
/// cf. ProfileApiController (portfolio / addPortfolioItem / updatePortfolioItem
/// / deletePortfolioItem).
class PortfolioRepository {
  const PortfolioRepository({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  final ApiProvider _apiProvider;

  Future<List<PortfolioItem>> list() async {
    final response = await _apiProvider.getJson(ApiConstants.profilePortfolio);
    final data = _data(response);
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(PortfolioItem.fromJson)
          .toList();
    }
    return const [];
  }

  Future<PortfolioItem> create(
    Map<String, dynamic> fields, {
    List<ApiMultipartFile> images = const [],
  }) =>
      _persist(null, fields, images);

  Future<PortfolioItem> update(
    String id,
    Map<String, dynamic> fields, {
    List<ApiMultipartFile> images = const [],
  }) =>
      _persist(id, fields, images);

  Future<void> delete(String id) async {
    final response =
        await _apiProvider.deleteJson(ApiConstants.profilePortfolioItem(id));
    _ensureSuccess(response);
  }

  Future<PortfolioItem> _persist(
    String? id,
    Map<String, dynamic> fields,
    List<ApiMultipartFile> images,
  ) async {
    final isUpdate = id != null;
    final endpoint = isUpdate
        ? ApiConstants.profilePortfolioItem(id)
        : ApiConstants.profilePortfolio;

    // Sans image : requête JSON classique (les tableaux passent tels quels).
    if (images.isEmpty) {
      final response = isUpdate
          ? await _apiProvider.putJson(endpoint, fields)
          : await _apiProvider.postJson(endpoint, fields);
      return PortfolioItem.fromJson(_asMap(_data(response)));
    }

    // Avec image(s) : multipart. PHP ne parse pas le corps multipart sur PUT
    // → on POST avec spoofing `_method=PUT` pour atteindre le handler update.
    final mpFields = <String, String>{};
    fields.forEach((k, v) {
      if (v == null) return;
      mpFields[k] = v is List || v is Map ? jsonEncode(v) : v.toString();
    });
    if (isUpdate) mpFields['_method'] = 'PUT';

    final response = await _apiProvider.sendMultipart(
      endpoint,
      method: 'POST',
      fields: mpFields,
      files: images,
    );
    return PortfolioItem.fromJson(_asMap(_data(response)));
  }

  dynamic _data(Map<String, dynamic> response) {
    _ensureSuccess(response);
    return response['data'];
  }

  void _ensureSuccess(Map<String, dynamic> response) {
    final statusCode = response['statusCode'] as int?;
    final success =
        response['success'] as bool? ?? (statusCode != null && statusCode < 400);
    if (!success) {
      throw ApiException(
        message: response['message']?.toString() ?? 'Opération impossible.',
        statusCode: statusCode,
      );
    }
  }

  Map<String, dynamic> _asMap(dynamic v) =>
      v is Map<String, dynamic> ? v : <String, dynamic>{};
}
