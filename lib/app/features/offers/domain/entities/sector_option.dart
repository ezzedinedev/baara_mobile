/// Secteur d'activité pour les filtres d'offres.
/// Source : GET /offers/sectors/list → data:[{id, name}].
class SectorOption {
  final String id;
  final String name;

  const SectorOption({required this.id, required this.name});

  factory SectorOption.fromJson(Map<String, dynamic> json) => SectorOption(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
      );
}
