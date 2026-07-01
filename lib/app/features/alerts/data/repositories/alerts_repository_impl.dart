import 'package:opportune_bf/app/core/constants/api_constants.dart';
import 'package:opportune_bf/app/core/network/api_provider.dart';

import '../../domain/entities/saved_search.dart';
import '../../domain/repositories/i_alerts_repository.dart';
import '../models/saved_search_model.dart';

class AlertsRepositoryImpl implements IAlertsRepository {
  AlertsRepositoryImpl({required ApiProvider apiProvider})
      : _api = apiProvider;

  final ApiProvider _api;

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      if (data['items'] is List) return data['items'] as List;
      if (data['data'] is List) return data['data'] as List;
    }
    return const [];
  }

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
  Future<List<SavedSearch>> getSavedSearches() async {
    final response = await _api.getJson(ApiConstants.savedSearches);
    if (response['success'] == true) {
      return _extractList(response['data'])
          .whereType<Map<String, dynamic>>()
          .map(SavedSearchModel.fromJson)
          .toList();
    }
    return [];
  }

  @override
  Future<SavedSearch?> createSavedSearch({
    required String label,
    required Map<String, dynamic> filters,
    bool notify = true,
  }) async {
    final response = await _api.postJson(
      ApiConstants.savedSearches,
      SavedSearchModel.toRequestBody(
        label: label,
        filters: filters,
        notify: notify,
      ),
    );
    if (response['success'] == true) {
      final item = _extractItem(response['data']);
      if (item != null) return SavedSearchModel.fromJson(item);
    }
    return null;
  }

  @override
  Future<bool> setNotify(String id, bool notify) async {
    try {
      final response = await _api.putJson(
        ApiConstants.savedSearch(id),
        {'notify': notify},
      );
      return response['success'] == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> deleteSavedSearch(String id) async {
    try {
      final response = await _api.deleteJson(ApiConstants.savedSearch(id));
      return response['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
