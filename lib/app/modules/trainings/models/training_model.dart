import '../../../core/utils/asset_url.dart';

class TrainingModel {
  const TrainingModel({
    required this.id,
    required this.title,
    required this.providerName,
    required this.providerLogo,
    required this.location,
    required this.format,
    required this.level,
    required this.lessons,
    required this.rating,
    required this.enrolledCount,
    required this.status,
    required this.priceLabel,
    required this.price,
    required this.sector,
    required this.description,
    required this.durationLabel,
    required this.startDateLabel,
    required this.deadlineLabel,
    required this.certificationLabel,
    required this.languageLabel,
    required this.objectives,
    required this.requirements,
    required this.modules,
    required this.contactLabel,
    required this.isBookmarked,
    required this.isEnrolled,
    this.coverUrl = '',
  });

  final String id;
  final String title;
  final String providerName;
  final String? providerLogo;
  final String location;
  final String format;
  final String level;
  final int lessons;
  final double rating;
  final int enrolledCount;
  final String status;
  final String priceLabel;
  final double? price;
  final String sector;
  final String description;
  final String durationLabel;
  final String startDateLabel;
  final String deadlineLabel;
  final String certificationLabel;
  final String languageLabel;
  final List<String> objectives;
  final List<String> requirements;
  final List<TrainingModule> modules;
  final String contactLabel;
  final bool isBookmarked;
  final bool isEnrolled;
  final String coverUrl;

  factory TrainingModel.fromJson(Map<String, dynamic> json) {
    return TrainingModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      providerName: _resolveProviderName(json['provider']),
      providerLogo: json['provider']?['logo'],
      location: json['location'] ?? '',
      format: _formatTrainingFormat(json['format']),
      level: _formatTrainingLevel(json['level']),
      lessons: json['modules_count'] ?? json['lessons'] ?? 0,
      rating: (json['avg_rating'] ?? json['rating'] ?? 0).toDouble(),
      enrolledCount: json['enrolled_count'] ?? 0,
      status: _formatTrainingStatus(json['status']),
      priceLabel: _formatTrainingPrice(json['cost_fcfa']),
      price: json['cost_fcfa']?.toDouble(),
      sector: json['sector']?['name'] ?? json['sector'] ?? '',
      description: json['description'] ?? json['summary'] ?? '',
      durationLabel: _formatTrainingDuration(json),
      startDateLabel: _formatTrainingDateLabel(json['start_date']),
      deadlineLabel: _formatTrainingDeadline(json['application_deadline']),
      certificationLabel: _formatCertification(json['certification']),
      languageLabel: _formatLanguage(json['language']),
      objectives: _parseList(json['objectives']),
      requirements: _parseList(json['requirements']),
      modules: _parseModules(json['modules']),
      contactLabel: _formatContact(json['contact']),
      isBookmarked: json['is_bookmarked'] ?? false,
      isEnrolled: json['is_enrolled'] ?? false,
      coverUrl: _resolveCoverUrl(json),
    );
  }

  static String _resolveCoverUrl(Map<String, dynamic> json) {
    final raw = (json['image_path'] ??
            json['image_url'] ??
            json['cover_url'] ??
            json['cover'] ??
            json['banner_url'] ??
            json['thumbnail_url'] ??
            '')
        .toString();
    // Le backend stocke le chemin relatif (ex: `formations/abc.jpg`) ; il
    // faut le prefixer du host + `/storage/` pour obtenir une URL servable.
    return resolveAssetUrl(raw);
  }

  static String _resolveProviderName(dynamic provider) {
    if (provider == null) return 'Organisme de formation';
    if (provider is Map) {
      return provider['company_name'] ??
          '${provider['first_name'] ?? ''} ${provider['last_name'] ?? ''}'.trim() ??
          provider['email'] ??
          'Organisme de formation';
    }
    return 'Organisme de formation';
  }

  static String _formatTrainingFormat(dynamic value) {
    final v = value?.toString().toLowerCase() ?? '';
    switch (v) {
      case 'online': return 'En ligne';
      case 'onsite': return 'Presentiel';
      case 'hybrid': return 'Hybride';
      default: return 'Format non precise';
    }
  }

  static String _formatTrainingLevel(dynamic value) {
    final v = value?.toString().toLowerCase() ?? '';
    switch (v) {
      case 'beginner': return 'Debutant';
      case 'intermediate': return 'Intermediaire';
      case 'advanced': return 'Avance';
      default: return 'Tous niveaux';
    }
  }

  static String _formatTrainingStatus(dynamic value) {
    final v = value?.toString().toLowerCase() ?? '';
    if (v == 'active') return 'Publiee';
    return value?.toString() ?? 'Disponible';
  }

  static String _formatTrainingPrice(dynamic value) {
    final cost = value?.toDouble();
    if (cost == null || cost <= 0) return 'Gratuite';
    return '${cost.toStringAsFixed(0)} XOF';
  }

  static String _formatTrainingDuration(Map<String, dynamic> json) {
    final duration = json['duration_hours'] ?? json['duration'];
    if (duration != null) return '$duration heures';
    final weeks = json['duration_weeks'];
    if (weeks != null) return '$weeks semaines';
    return 'Non precise';
  }

  static String _formatTrainingDateLabel(dynamic value) {
    if (value == null) return 'Date non precisee';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return 'Date non precisee';
    return 'Debut: ${date.day}/${date.month}/${date.year}';
  }

  static String _formatTrainingDeadline(dynamic value) {
    if (value == null) return 'Pas de date limite';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return 'Pas de date limite';
    return 'Inscription: ${date.day}/${date.month}/${date.year}';
  }

  static String _formatCertification(dynamic value) {
    if (value == null || value.toString().isEmpty) return 'Aucun';
    return value.toString();
  }

  static String _formatLanguage(dynamic value) {
    if (value == null) return 'Francais';
    return value.toString();
  }

  static List<String> _parseList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) return value.split(',').map((e) => e.trim()).toList();
    return [];
  }

  static List<TrainingModule> _parseModules(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => TrainingModule.fromJson(e)).toList();
    }
    return [];
  }

  static String _formatContact(dynamic value) {
    if (value == null) return 'Contact non disponible';
    return value.toString();
  }
}

class TrainingModule {
  const TrainingModule({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.isCompleted,
  });

  final String id;
  final String title;
  final String description;
  final int duration;
  final bool isCompleted;

  factory TrainingModule.fromJson(Map<String, dynamic> json) {
    return TrainingModule(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      duration: json['duration_minutes'] ?? json['duration'] ?? 0,
      isCompleted: json['is_completed'] ?? false,
    );
  }
}

class TrainingFilter {
  const TrainingFilter({
    this.sector,
    this.level,
    this.format,
    this.isFree,
    this.maxPrice,
  });

  final String? sector;
  final String? level;
  final String? format;
  final bool? isFree;
  final double? maxPrice;

  TrainingFilter copyWith({
    String? sector,
    String? level,
    String? format,
    bool? isFree,
    double? maxPrice,
  }) {
    return TrainingFilter(
      sector: sector ?? this.sector,
      level: level ?? this.level,
      format: format ?? this.format,
      isFree: isFree ?? this.isFree,
      maxPrice: maxPrice ?? this.maxPrice,
    );
  }

  Map<String, String> toQueryParams() {
    return {
      if (sector != null) 'sector': sector!,
      if (level != null) 'level': level!,
      if (format != null) 'format': format!,
      if (isFree == true) 'is_free': '1',
      if (maxPrice != null) 'max_price': maxPrice.toString(),
    };
  }
}