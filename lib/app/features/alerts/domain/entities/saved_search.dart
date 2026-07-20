
class SavedSearch {
  const SavedSearch({
    required this.id,
    required this.label,
    required this.filters,
    required this.notify,
    this.matchCount = 0,
    this.createdAt,
  });

  final String id;
  final String label;
  final Map<String, dynamic> filters;
  final bool notify;

  /// Nombre d'offres actives correspondant actuellement (aperçu backend).
  final int matchCount;
  final DateTime? createdAt;

  String? get search => _asString('search');
  String? get sectorId => _asString('sector_id');
  String? get contractType => _asString('contract_type');
  String? get sort => _asString('sort');
  bool get isRemote => filters['is_remote'] == true || filters['is_remote'] == 1;

  /// Puces lisibles résumant les critères (hors secteur, dont l'id n'est pas
  /// human-readable ici).
  List<String> get chips {
    final out = <String>[];
    final s = search;
    if (s != null && s.trim().isNotEmpty) out.add('« ${s.trim()} »');
    final c = contractType;
    if (c != null && c.isNotEmpty) out.add(c);
    if (isRemote) out.add('Télétravail');
    return out;
  }

  String? _asString(String key) {
    final v = filters[key];
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }

  SavedSearch copyWith({bool? notify, int? matchCount}) => SavedSearch(
        id: id,
        label: label,
        filters: filters,
        notify: notify ?? this.notify,
        matchCount: matchCount ?? this.matchCount,
        createdAt: createdAt,
      );
}
