class OfferModel {
  const OfferModel({
    required this.id,
    required this.title,
    required this.company,
    required this.companyLogo,
    required this.location,
    required this.salary,
    required this.contractType,
    required this.requiredSkills,
    required this.minYearsExperience,
    required this.description,
    required this.sector,
    required this.experienceLabel,
    required this.deadlineLabel,
    required this.isRemote,
    required this.createdAt,
    this.employerLatitude,
    this.employerLongitude,
    this.employerAddress,
  });

  final String id;
  final String title;
  final String company;
  final String? companyLogo;
  final String location;
  final String salary;
  final String contractType;
  final List<String> requiredSkills;
  final int minYearsExperience;
  final String description;
  final String sector;
  final String experienceLabel;
  final String deadlineLabel;
  final bool isRemote;
  final DateTime? createdAt;

  // Localisation entreprise (smart location) — disponible quand l'employer
  // a renseigne sa position GPS dans ses parametres web.
  final double? employerLatitude;
  final double? employerLongitude;
  final String? employerAddress;

  bool get employerHasGeoLocation =>
      employerLatitude != null && employerLongitude != null;

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    final employer = json['employer'] is Map<String, dynamic>
        ? json['employer'] as Map<String, dynamic>
        : null;

    return OfferModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      company: json['company_name'] ?? employer?['company_name'] ?? '',
      companyLogo: json['company_logo'] ?? employer?['logo'] ?? employer?['logo_url'],
      location: _formatLocation(json),
      salary: _formatSalary(json),
      contractType: json['contract_type'] ?? '',
      requiredSkills: _parseSkills(json['required_skills']),
      minYearsExperience: _parseExperience(json['experience_level']),
      description: json['description'] ?? '',
      sector: json['sector']?['name'] ?? json['sector'] ?? '',
      experienceLabel: _formatExperienceLabel(json),
      deadlineLabel: _formatDeadline(json['deadline']),
      isRemote: json['is_remote'] == true || json['is_remote'] == 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      employerLatitude: _parseDouble(employer?['latitude']),
      employerLongitude: _parseDouble(employer?['longitude']),
      employerAddress: _emptyToNull(employer?['address']),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static String? _emptyToNull(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  static String _formatLocation(Map<String, dynamic> json) {
    final parts = <String>[];
    if (json['city'] != null) parts.add(json['city']);
    if (json['region'] != null) parts.add(json['region']);
    if (json['is_remote'] == true || json['is_remote'] == 1) parts.add('Remote');
    return parts.isEmpty ? 'Non precise' : parts.join(' • ');
  }

  static String _formatSalary(Map<String, dynamic> json) {
    if (json['salary_visible'] != true) return 'Salaire a negocier';
    final min = json['salary_min'];
    final max = json['salary_max'];
    final currency = json['salary_currency'] ?? 'XOF';
    if (min != null && max != null) return '$min - $max $currency';
    if (min != null) return 'A partir de $min $currency';
    if (max != null) return 'Jusqu\'a $max $currency';
    return 'Salaire non precise';
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
    return 'Non precise';
  }

  static String _formatDeadline(dynamic value) {
    if (value == null) return 'Date limite non precisee';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return 'Date limite non precisee';
    return 'Cloture le ${date.day}/${date.month}/${date.year}';
  }
}

class OfferFilter {
  const OfferFilter({
    this.sector,
    this.contractType,
    this.location,
    this.isRemote,
    this.minSalary,
    this.maxSalary,
    this.experienceLevel,
  });

  final String? sector;
  final String? contractType;
  final String? location;
  final bool? isRemote;
  final int? minSalary;
  final int? maxSalary;
  final String? experienceLevel;

  OfferFilter copyWith({
    String? sector,
    String? contractType,
    String? location,
    bool? isRemote,
    int? minSalary,
    int? maxSalary,
    String? experienceLevel,
  }) {
    return OfferFilter(
      sector: sector ?? this.sector,
      contractType: contractType ?? this.contractType,
      location: location ?? this.location,
      isRemote: isRemote ?? this.isRemote,
      minSalary: minSalary ?? this.minSalary,
      maxSalary: maxSalary ?? this.maxSalary,
      experienceLevel: experienceLevel ?? this.experienceLevel,
    );
  }

  Map<String, String> toQueryParams() {
    return {
      if (sector != null) 'sector': sector!,
      if (contractType != null) 'contract_type': contractType!,
      if (location != null) 'location': location!,
      if (isRemote != null) 'is_remote': isRemote! ? '1' : '0',
      if (minSalary != null) 'min_salary': minSalary.toString(),
      if (maxSalary != null) 'max_salary': maxSalary.toString(),
      if (experienceLevel != null) 'experience_level': experienceLevel!,
    };
  }
}

class SectorModel {
  const SectorModel({
    required this.id,
    required this.name,
    required this.offerCount,
  });

  final String id;
  final String name;
  final int offerCount;

  factory SectorModel.fromJson(Map<String, dynamic> json) {
    return SectorModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      offerCount: json['offer_count'] ?? json['count'] ?? 0,
    );
  }
}