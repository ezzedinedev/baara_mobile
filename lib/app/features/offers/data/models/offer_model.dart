import 'package:baara/app/core/utils/money.dart';

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
    super.isSaved,
    super.isApplied,
    super.applicationId,
    super.applicationStatus,
    super.screeningQuestions,
    super.matchScore,
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
      companyLogo:
          json['company_logo'] ?? employer?['logo'] ?? employer?['logo_url'],
      location: _formatLocation(json),
      salary: _formatSalary(json),
      contractType: json['contract_type'] ?? '',
      requiredSkills: _parseSkills(json['required_skills']),
      minYearsExperience: _parseExperience(json['experience_level']),
      description: json['description'] ?? '',
      sector: json['sector'] is Map
          ? (json['sector']['name'] ?? '')
          : (json['sector']?.toString() ?? ''),
      isRemote: json['is_remote'] == true || json['is_remote'] == 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      experienceLabel: _formatExperienceLabel(json),
      deadlineLabel: _formatDeadline(json['deadline']),
      isBoosted: json['is_boosted'] == true || json['is_boosted'] == 1,
      boostTier: _parseBoostTier(json, badge),
      boostLabel: badge?['label']?.toString(),
      isSaved: json['is_saved'] == null
          ? null
          : (json['is_saved'] == true || json['is_saved'] == 1),
      isApplied: json['is_applied'] == null
          ? null
          : (json['is_applied'] == true || json['is_applied'] == 1),
      applicationId: json['application_id']?.toString(),
      applicationStatus: json['application_status']?.toString(),
      screeningQuestions: _parseScreeningQuestions(json),
      // Absent (liste publique) ou null (CV/offre non indexés) = score inconnu.
      matchScore: json['match_score'] is num
          ? (json['match_score'] as num).round()
          : null,
    );
  }

  static List<ScreeningQuestion> _parseScreeningQuestions(
      Map<String, dynamic> json) {
    final raw = json['screening_questions'] ??
        json['screeningQuestions'] ??
        json['screening'] ??
        json['questions'];
    if (raw is! List) return const [];

    final questions = <ScreeningQuestion>[];
    for (var i = 0; i < raw.length; i++) {
      final item = raw[i];
      if (item is String) {
        final label = item.trim();
        if (label.isNotEmpty) {
          questions.add(ScreeningQuestion(id: 'q_$i', label: label));
        }
        continue;
      }
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final label = (map['label'] ?? map['question'] ?? map['title'] ?? '')
          .toString()
          .trim();
      if (label.isEmpty) continue;
      final id =
          (map['id'] ?? map['key'] ?? map['name'] ?? 'q_$i').toString().trim();
      final options = map['options'] is List
          ? (map['options'] as List).map((o) => o.toString()).toList()
          : const <String>[];
      questions.add(ScreeningQuestion(
        id: id.isEmpty ? 'q_$i' : id,
        label: label,
        type: (map['type'] ?? (options.isNotEmpty ? 'select' : 'text'))
            .toString(),
        required: map['required'] == true || map['is_required'] == true,
        options: options,
      ));
    }
    return questions;
  }

  static int _parseBoostTier(
      Map<String, dynamic> json, Map<String, dynamic>? badge) {
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
    if (json['is_remote'] == true || json['is_remote'] == 1) {
      parts.add('Remote');
    }
    return parts.isEmpty ? 'Non précisé' : parts.join(' • ');
  }

  static String _formatSalary(Map<String, dynamic> json) {
    if (json['salary_visible'] != true) return 'Salaire à négocier';
    // Les montants arrivent en décimaux Laravel (`350000.00`) : sans mise en
    // forme on affichait « 350000.00 - 600000.00 XOF ».
    return formatMoneyRange(
          json['salary_min'],
          json['salary_max'],
          currency: json['salary_currency']?.toString(),
        ) ??
        'Salaire non précisé';
  }

  static List<String> _parseSkills(dynamic skills) {
    if (skills == null) return [];
    if (skills is List) return skills.map((s) => s.toString()).toList();
    if (skills is String) {
      return skills.split(',').map((s) => s.trim()).toList();
    }
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
