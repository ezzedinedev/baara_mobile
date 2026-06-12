/// Type d'élément de portfolio (aligné sur l'enum backend).
enum PortfolioItemType {
  project,
  certification,
  testimonial,
  other;

  static PortfolioItemType fromString(String? v) {
    switch (v) {
      case 'certification':
        return PortfolioItemType.certification;
      case 'testimonial':
        return PortfolioItemType.testimonial;
      case 'other':
        return PortfolioItemType.other;
      case 'project':
      default:
        return PortfolioItemType.project;
    }
  }

  String get apiValue => name;

  String get label {
    switch (this) {
      case PortfolioItemType.project:
        return 'Projet';
      case PortfolioItemType.certification:
        return 'Certification';
      case PortfolioItemType.testimonial:
        return 'Témoignage';
      case PortfolioItemType.other:
        return 'Autre';
    }
  }
}

class PortfolioItem {
  final String id;
  final PortfolioItemType type;
  final String title;
  final String? description;
  final String? results;
  final String? externalUrl;
  final List<String> techStack;
  final List<String> mediaUrls;
  final int displayOrder;

  const PortfolioItem({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    this.results,
    this.externalUrl,
    this.techStack = const [],
    this.mediaUrls = const [],
    this.displayOrder = 0,
  });

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    return PortfolioItem(
      id: json['id']?.toString() ?? '',
      type: PortfolioItemType.fromString(json['item_type']?.toString()),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      results: json['results']?.toString(),
      externalUrl: json['external_url']?.toString(),
      techStack: _strList(json['tech_stack']),
      mediaUrls: _strList(json['media_urls']),
      displayOrder: json['display_order'] is num
          ? (json['display_order'] as num).toInt()
          : int.tryParse(json['display_order']?.toString() ?? '') ?? 0,
    );
  }

  static List<String> _strList(dynamic v) {
    if (v is List) {
      return v
          .map((e) => e.toString())
          .where((s) => s.trim().isNotEmpty)
          .toList();
    }
    return const [];
  }
}
