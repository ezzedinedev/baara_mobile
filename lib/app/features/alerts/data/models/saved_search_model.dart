import '../../domain/entities/saved_search.dart';

/// Mapping JSON ↔ [SavedSearch] (API /saved-searches).
class SavedSearchModel {
  const SavedSearchModel._();

  static SavedSearch fromJson(Map<String, dynamic> json) {
    final rawFilters = json['filters'];
    final filters = rawFilters is Map
        ? rawFilters.map((k, v) => MapEntry(k.toString(), v))
        : <String, dynamic>{};

    return SavedSearch(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? 'Alerte',
      filters: filters,
      notify: json['notify'] == true || json['notify'] == 1,
      matchCount: (json['match_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  /// Corps de création/mise à jour (POST/PUT).
  static Map<String, dynamic> toRequestBody({
    required String label,
    required Map<String, dynamic> filters,
    bool? notify,
  }) {
    return {
      'label': label,
      'filters': filters,
      if (notify != null) 'notify': notify,
    };
  }
}
