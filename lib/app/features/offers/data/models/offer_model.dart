import '../../domain/entities/offer.dart';

/// Modèle de données pour les offres, incluant le parsing JSON.
/// Hérite de l'entité [Offer] pour être utilisé dans les couches supérieures.
class OfferModel extends Offer {
  const OfferModel({
    required super.id,
    required super.title,
    required super.company,
    super.companyLogo,
    required super.location,
    required super.salary,
    required super.contractType,
    required super.requiredSkills,
    required super.minYearsExperience,
    required super.description,
    required super.sector,
    required super.isRemote,
    super.createdAt,
    super.experienceLabel,
    super.deadlineLabel,
    super.isBoosted,
    super.boostTier,
    super.boostLabel,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    final employer = json['employer'] is Map<String, dynamic>
        ? json['employer'] as Map<String, dynamic>
        : null;

    final badge = json['boost_badge'] is Map<String, dynamic>
        ? json['boost_badge'] as Map<String, dynamic>
        : null;

    return OfferModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Sans titre',
      company: json['company_name'] ?? employer?['company_name'] ?? 'Anonyme',
      companyLogo: json['company_logo'] ?? employer?['logo'] ?? employer?['logo_url'],
      location: _formatLocation(json),
      salary: _formatSalary(json),
      contractType: json['contract_type'] ?? '',
      requiredSkills: _parseSkills(json['required_skills']),
      minYearsExperience: _parseExperience(json['experience_level']),
      description: json['description'] ?? '',
      sector: json['sector'] is Map ? (json['sector']['name'] ?? '') : (json['sector']?.toString() ?? ''),
      isRemote: json['is_remote'] == true || json['is_remote'] == 1,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      experienceLabel: _formatExperienceLabel(json),
      deadlineLabel: _formatDeadline(json['deadline']),
      isBoosted: json['is_boosted'] == true || json['is_boosted'] == 1,
      boostTier: _parseBoostTier(json, badge),
      boostLabel: badge?['label']?.toString(),
    );
  }

  static int _parseBoostTier(Map<String, dynamic> json, Map<String, dynamic>? badge) {
    final fromBadge = badge?['tier'];
    if (fromBadge is int) return fromBadge;
    if (fromBadge != null) return int.tryParse(fromBadge.toString()) ?? 0;
    final raw = json['boost_tier'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  static String _formatLocation(Map<String, dynamic> json) {
    final parts = <String>[];
    if (json['city'] != null) parts.add(json['city'].toString());
    if (json['region'] != null) parts.add(json['region'].toString());
    if (json['is_remote'] == true || json['is_remote'] == 1) parts.add('Remote');
    return parts.isEmpty ? 'Non précisé' : parts.join(' • ');
  }

  static String _formatSalary(Map<String, dynamic> json) {
    if (json['salary_visible'] != true) return 'Salaire à négocier';
    final min = json['salary_min'];
    final max = json['salary_max'];
    final currency = json['salary_currency'] ?? 'XOF';
    if (min != null && max != null) return '$min - $max $currency';
    if (min != null) return 'À partir de $min $currency';
    if (max != null) return 'Jusqu\'à $max $currency';
    return 'Salaire non précisé';
  }

  static List<String> _parseSkills(dynamic skills) {
    if (skills == null) return [];
    if (skills is List) return skills.map((s) => s.toString()).toList();
    if (skills is String) return skills.split(',').map((s) => s.trim()).toList();
    return [];
  }

  static int _parseExperience(dynamic level) {
    if (level == null) return 0;
    if (level is int) return level;
    final match = RegExp(r'(\d+)').firstMatch(level.toString());
    return match != null ? int.tryParse(match.group(1) ?? '') ?? 0 : 0;
  }

  static String _formatExperienceLabel(Map<String, dynamic> json) {
    final level = json['experience_level'];
    if (level is int && level > 0) return '$level an(s)';
    if (level is String && level.isNotEmpty) return level;
    return 'Non précisé';
  }

  static String _formatDeadline(dynamic value) {
    if (value == null) return 'Pas de date limite';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return 'Pas de date limite';
    return 'Clôture le ${date.day}/${date.month}/${date.year}';
  }
}
