import 'package:opportune_bf/app/core/utils/asset_url.dart';
import '../../domain/entities/training.dart';

class TrainingModel extends Training {
  const TrainingModel({
    required super.id,
    required super.title,
    required super.providerName,
    super.providerLogo,
    required super.location,
    required super.format,
    required super.level,
    required super.lessons,
    required super.rating,
    required super.enrolledCount,
    required super.status,
    required super.priceLabel,
    super.price,
    required super.sector,
    required super.description,
    required super.durationLabel,
    required super.startDateLabel,
    required super.deadlineLabel,
    required super.certificationLabel,
    required super.languageLabel,
    required super.objectives,
    required super.requirements,
    required super.modules,
    required super.contactLabel,
    required super.isBookmarked,
    required super.isEnrolled,
    required super.coverUrl,
  });

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
    return resolveAssetUrl(raw);
  }

  static String _resolveProviderName(dynamic provider) {
    if (provider == null) return 'Organisme de formation';
    if (provider is Map) {
      return provider['company_name'] ??
          '${provider['first_name'] ?? ''} ${provider['last_name'] ?? ''}'
              .trim() ??
          provider['email'] ??
          'Organisme de formation';
    }
    return 'Organisme de formation';
  }

  static String _formatTrainingFormat(dynamic value) {
    final v = value?.toString().toLowerCase() ?? '';
    switch (v) {
      case 'online':
        return 'En ligne';
      case 'onsite':
        return 'Presentiel';
      case 'hybrid':
        return 'Hybride';
      default:
        return 'Format non precise';
    }
  }

  static String _formatTrainingLevel(dynamic value) {
    final v = value?.toString().toLowerCase() ?? '';
    switch (v) {
      case 'beginner':
        return 'Debutant';
      case 'intermediate':
        return 'Intermediaire';
      case 'advanced':
        return 'Avance';
      default:
        return 'Tous niveaux';
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
    final whole = cost.toStringAsFixed(0);
    final formatted = whole.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
    return '$formatted FCFA';
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

  static List<TrainingModuleModel> _parseModules(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => TrainingModuleModel.fromJson(e)).toList();
    }
    return [];
  }

  static String _formatContact(dynamic value) {
    if (value == null) return 'Contact non disponible';
    return value.toString();
  }
}

class TrainingModuleModel extends TrainingModule {
  const TrainingModuleModel({
    required super.id,
    required super.title,
    required super.description,
    required super.duration,
    required super.isCompleted,
    super.contentType,
    super.contentUrl,
    super.videoUrl,
    super.documentUrl,
    super.imageUrl,
    super.textContent,
    super.resourceUrl,
  });

  factory TrainingModuleModel.fromJson(Map<String, dynamic> json) {
    // Le backend (TrainingModule) expose `objectives_text` comme contenu de
    // la leçon ; on tolère aussi `description`/`summary`/`content` au cas où.
    final description = _moduleString(json, const [
      'description',
      'objectives_text',
      'summary',
      'content',
    ]);
    final rawContentUrl = _moduleString(json, const [
      'content_url',
      'url',
      'file_url',
      'media_url',
      'asset_url',
      'download_url',
      'attachment_url',
      'file_path',
      'path',
    ]);
    final videoUrl = _moduleString(json, const ['video_url', 'media_url']);
    final documentUrl = _moduleString(json, const [
      'document_url',
      'pdf_url',
      'file_url',
    ]);
    final imageUrl = _moduleString(json, const ['image_url', 'image']);
    final resourceUrl = _moduleString(json, const [
      'resource_url',
      'link',
      'link_url',
      'external_url',
    ]);
    final textContent = _moduleString(json, const [
      'text_content',
      'body',
      'rich_text',
      'html',
    ]);

    final type = _resolveContentType(
      _moduleString(json, const [
        'content_type',
        'type',
        'media_type',
        'lesson_type',
        'format',
      ]),
      rawContentUrl.isNotEmpty
          ? rawContentUrl
          : (videoUrl.isNotEmpty
              ? videoUrl
              : documentUrl.isNotEmpty
                  ? documentUrl
                  : imageUrl),
    );

    return TrainingModuleModel(
      id: json['id']?.toString() ?? '',
      title: (json['title'] ?? json['name'] ?? '').toString(),
      description: description,
      duration: _moduleInt(json, const ['duration_minutes', 'duration']),
      isCompleted: json['is_completed'] == true || json['completed'] == true,
      contentType: type,
      contentUrl: resolveAssetUrl(rawContentUrl),
      videoUrl: resolveAssetUrl(videoUrl),
      documentUrl: resolveAssetUrl(documentUrl),
      imageUrl: resolveAssetUrl(imageUrl),
      textContent: textContent,
      resourceUrl: resolveAssetUrl(resourceUrl),
    );
  }

  /// Première valeur non vide parmi [keys], en string trimée.
  static String _moduleString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final str = value.toString().trim();
      if (str.isNotEmpty) return str;
    }
    return '';
  }

  static int _moduleInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      final parsed = int.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return 0;
  }

  /// Normalise le `content_type` backend (`video|pdf|powerpoint|word|excel|
  /// quiz|image|text|link`) vers un [LessonContentType] géré par le lecteur.
  static LessonContentType _resolveContentType(String rawType, String url) {
    final type = rawType.toLowerCase();
    final lowerUrl = url.toLowerCase();

    bool urlEndsWith(List<String> exts) =>
        exts.any((e) => lowerUrl.contains('.$e'));

    if (type.contains('video') || urlEndsWith(['mp4', 'mov', 'webm', 'm3u8'])) {
      return LessonContentType.video;
    }
    if (type.contains('pdf') ||
        type.contains('document') ||
        type.contains('powerpoint') ||
        type.contains('word') ||
        type.contains('excel') ||
        type == 'ppt' ||
        type == 'doc' ||
        urlEndsWith(['pdf', 'ppt', 'pptx', 'doc', 'docx', 'xls', 'xlsx'])) {
      return LessonContentType.pdf;
    }
    if (type.contains('image') ||
        type.contains('infographic') ||
        urlEndsWith(['png', 'jpg', 'jpeg', 'gif', 'webp'])) {
      return LessonContentType.image;
    }
    if (type.contains('text') ||
        type.contains('article') ||
        type.contains('quiz')) {
      return LessonContentType.text;
    }
    if (type.contains('link') || type.contains('url')) {
      return LessonContentType.link;
    }
    return LessonContentType.unknown;
  }
}
