part of '../home_controller.dart';

// Parsing helpers extraits de HomeController.
// Regroupés dans une extension pour préserver l'accès aux champs
// privés du controller (même library grâce à part of).
extension HomeControllerParsing on HomeController {
  List<dynamic> _extractItems(dynamic payload) {
    if (payload is List) {
      return payload;
    }

    final map = _asMap(payload);
    if (map == null) {
      return const [];
    }

    final items = map['items'];
    if (items is List) {
      return items;
    }

    final pageItems = map['data'];
    if (pageItems is List) {
      return pageItems;
    }

    return const [];
  }

  HomeOfferPreview? _parseOffer(dynamic payload) {
    final data = _asMap(payload);
    if (data == null) {
      return null;
    }

    final employer =
        _asMap(data['employer']) ?? _asMap(data['employer_profile']);
    final skills = _asStringList(data['required_skills']);

    return HomeOfferPreview(
      id: _firstNonEmpty([
        _asString(data['id']),
        _asString(data['uuid']),
      ], fallback: ''),
      title: _firstNonEmpty([
        _asString(data['title']),
      ], fallback: 'Offre publiee'),
      company: _firstNonEmpty([
        _asString(employer?['company_name']),
        _asString(data['company_name']),
      ], fallback: 'Entreprise'),
      location: _formatOfferLocation(data, employer),
      salary: _formatSalary(data),
      contractType: _firstNonEmpty([
        _asString(data['contract_type']),
      ], fallback: 'Contrat non precise'),
      requiredSkills: skills,
      minYearsExperience: _parseMinYearsExperience(data['experience_level']),
      description: _firstNonEmpty([
        _asString(data['description']),
      ], fallback: 'Aucune description fournie.'),
      sector: _firstNonEmpty([
        _asString(_asMap(data['sector'])?['name']),
      ], fallback: 'Secteur non precise'),
      experienceLabel: _formatExperienceLabel(data),
      deadlineLabel: _formatOfferDeadline(
        data['deadline'] ?? data['application_deadline'],
      ),
      isRemote: _asBool(data['is_remote']),
    );
  }

  HomeFormationPreview? _parseTraining(dynamic payload) {
    final data = _asMap(payload);
    if (data == null) {
      return null;
    }

    final provider = _asMap(data['provider']);
    final modules = _parseTrainingLessons(
      data['modules'] ??
          data['lessons'] ??
          data['contents'] ??
          data['course_modules'],
    );
    final priceAmount =
        _asNum(data['cost_fcfa'] ?? data['price'] ?? data['amount']) ??
            (_asBool(data['is_paid']) ? 1 : 0);

    return HomeFormationPreview(
      id: _firstNonEmpty([
        _asString(data['id']),
        _asString(data['uuid']),
      ], fallback: ''),
      title: _firstNonEmpty([
        _asString(data['title']),
      ], fallback: 'Parcours de formation'),
      providerName: _resolveTrainingProviderName(provider),
      location: _firstNonEmpty([
        _asString(data['location']),
      ], fallback: 'Lieu non precise'),
      formatLabel: _formatTrainingFormat(data['format']),
      level: _formatTrainingLevel(data['level']),
      lessons: _asInt(data['modules_count'] ?? data['lessons_count']) == 0
          ? modules.length
          : _asInt(data['modules_count'] ?? data['lessons_count']),
      rating: _asDouble(data['avg_rating']),
      enrolledCount: _asInt(data['enrolled_count']),
      status: _formatTrainingStatus(data),
      priceLabel: _formatTrainingPrice(priceAmount),
      priceAmount: priceAmount,
      sector: _firstNonEmpty([
        _asString(_asMap(data['sector'])?['name']),
      ], fallback: 'Secteur non precise'),
      description: _firstNonEmpty([
        _asString(data['description']),
        _asString(data['summary']),
        _asString(data['overview']),
      ], fallback: 'Description non fournie.'),
      durationLabel: _formatTrainingDuration(data),
      startDateLabel: _formatTrainingDateLabel(
        data['start_date'] ?? data['starts_at'] ?? data['published_at'],
        fallback: 'Date de debut non precisee',
      ),
      deadlineLabel: _formatTrainingDateLabel(
        data['registration_deadline'] ?? data['deadline'] ?? data['end_date'],
        fallback: 'Date limite non precisee',
      ),
      certificationLabel: _formatTrainingCertification(data),
      languageLabel: _firstNonEmpty([
        _asString(data['language']),
        _asString(data['teaching_language']),
      ], fallback: 'Langue non precisee'),
      contactLabel: _firstNonEmpty([
        _asString(data['contact_email']),
        _asString(data['contact_phone']),
        _asString(provider?['email']),
      ], fallback: 'Contact non precise'),
      objectives: _asTextList(
        data['objectives'] ?? data['goals'] ?? data['learning_outcomes'],
      ),
      requirements: _asTextList(
        data['requirements'] ?? data['prerequisites'] ?? data['audience'],
      ),
      modules: modules,
      isEnrolled: _asBool(data['is_enrolled'] ?? data['enrolled']),
      coverUrl: _resolveTrainingAssetUrl(
        _firstNonEmpty([
          _asString(data['image_path']),
          _asString(data['image_url']),
          _asString(data['cover_url']),
          _asString(data['cover']),
          _asString(data['banner_url']),
          _asString(data['thumbnail_url']),
        ], fallback: ''),
      ),
    );
  }

  List<HomeTrainingLesson> _parseTrainingLessons(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return [
      for (var index = 0; index < value.length; index++)
        if (_parseTrainingLesson(value[index], index) case final lesson?)
          lesson,
    ];
  }

  HomeTrainingLesson? _parseTrainingLesson(dynamic payload, int index) {
    final data = _asMap(payload);
    if (data == null) {
      return null;
    }

    final backendId = _firstNonEmpty([
      _asString(data['id']),
      _asString(data['uuid']),
      _asString(data['module_id']),
    ], fallback: '');
    final type = _normalizeLessonType(
      data['type'] ??
          data['content_type'] ??
          data['media_type'] ??
          data['lesson_type'] ??
          data['format'],
      data,
    );
    final title = _firstNonEmpty([
      _asString(data['title']),
      _asString(data['name']),
    ], fallback: 'Lecon ${index + 1}');

    return HomeTrainingLesson(
      id: backendId.isNotEmpty ? backendId : 'local_lesson_$index',
      backendId: backendId,
      title: title,
      subtitle: _firstNonEmpty([
        _asString(data['subtitle']),
        _asString(data['chapter']),
      ], fallback: ''),
      description: _firstNonEmpty([
        _asString(data['description']),
        _asString(data['summary']),
        _asString(data['content']),
      ], fallback: 'Description non fournie.'),
      type: type,
      typeLabel: _lessonTypeLabel(type),
      durationLabel: _formatLessonDuration(data),
      assetUrl: _resolveTrainingAssetUrl(
        _firstNonEmpty([
          _asString(data['content_url']),
          _asString(data['url']),
          _asString(data['file_url']),
          _asString(data['media_url']),
          _asString(data['video_url']),
          _asString(data['document_url']),
          _asString(data['image_url']),
          _asString(data['asset_url']),
          _asString(data['download_url']),
          _asString(data['attachment_url']),
          _asString(data['file_path']),
          _asString(data['path']),
        ], fallback: ''),
      ),
      thumbnailUrl: _resolveTrainingAssetUrl(
        _firstNonEmpty([
          _asString(data['thumbnail_url']),
          _asString(data['cover_url']),
          _asString(data['image']),
        ], fallback: ''),
      ),
      fileName: _firstNonEmpty([
        _asString(data['file_name']),
        _asString(data['filename']),
      ], fallback: _defaultLessonFileName(title, type)),
      isCompleted: _asBool(data['is_completed'] ?? data['completed']),
    );
  }

  String _normalizeLessonType(dynamic rawValue, Map<String, dynamic> data) {
    final value = (_asString(rawValue) ?? '').toLowerCase();
    if (value.contains('video')) {
      return 'video';
    }
    if (value.contains('pdf') || value.contains('document')) {
      return 'pdf';
    }
    if (value.contains('image') || value.contains('infographic')) {
      return 'image';
    }

    final fileName = _firstNonEmpty([
      _asString(data['file_name']),
      _asString(data['filename']),
      _asString(data['content_url']),
      _asString(data['url']),
      _asString(data['file_url']),
      _asString(data['file_path']),
      _asString(data['path']),
    ], fallback: '')
        .toLowerCase();
    if (fileName.endsWith('.pdf')) {
      return 'pdf';
    }
    if (fileName.endsWith('.png') ||
        fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg') ||
        fileName.endsWith('.webp')) {
      return 'image';
    }
    if (fileName.endsWith('.mp4') || fileName.endsWith('.mov')) {
      return 'video';
    }

    return 'article';
  }

  String _lessonTypeLabel(String type) {
    switch (type) {
      case 'video':
        return 'Video';
      case 'pdf':
        return 'Document PDF';
      case 'image':
        return 'Infographie';
      default:
        return 'Lecon';
    }
  }

  String _resolveTrainingAssetUrl(String value) => resolveAssetUrl(value);

  String _formatLessonDuration(Map<String, dynamic> data) {
    final explicit = _firstNonEmpty([
      _asString(data['duration_label']),
      _asString(data['duration']),
    ], fallback: '');
    if (explicit.isNotEmpty && !RegExp(r'^\d+$').hasMatch(explicit)) {
      return explicit;
    }

    final minutes =
        _asNum(data['duration_minutes'] ?? data['minutes'] ?? data['duration']);
    if (minutes != null && minutes > 0) {
      return '${minutes.round()} min';
    }

    return '';
  }

  String _defaultLessonFileName(String title, String type) {
    final safeTitle = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final extension = switch (type) {
      'pdf' => 'pdf',
      'image' => 'png',
      'video' => 'mp4',
      _ => 'txt',
    };
    return '${safeTitle.isEmpty ? 'lecon' : safeTitle}.$extension';
  }

  String _formatOfferLocation(
    Map<String, dynamic> offer,
    Map<String, dynamic>? employer,
  ) {
    final parts = <String>[
      if (_asString(offer['city']) case final city? when city.isNotEmpty) city,
      if (_asString(offer['region']) case final region? when region.isNotEmpty)
        region,
      if (_asBool(offer['is_remote'])) 'Remote',
    ];

    if (parts.isEmpty && employer != null) {
      if (_asString(employer['city']) case final city? when city.isNotEmpty) {
        parts.add(city);
      }
      if (_asString(employer['region']) case final region?
          when region.isNotEmpty) {
        parts.add(region);
      }
    }

    return parts.isEmpty ? 'Lieu non precise' : parts.join(' • ');
  }

  String _formatSalary(Map<String, dynamic> data) {
    if (!_asBool(data['salary_visible'])) {
      return 'Salaire a negocier';
    }

    final min = _asNum(data['salary_min']);
    final max = _asNum(data['salary_max']);
    final currency = _firstNonEmpty([
      _asString(data['salary_currency']),
    ], fallback: 'XOF');

    if (min == null && max == null) {
      return 'Salaire non precise';
    }
    if (min != null && max != null) {
      return '${_formatMoney(min)} - ${_formatMoney(max)} $currency';
    }
    if (min != null) {
      return 'A partir de ${_formatMoney(min)} $currency';
    }
    return 'Jusqu\'a ${_formatMoney(max!)} $currency';
  }

  String _formatExperienceLabel(Map<String, dynamic> data) {
    final experienceLevel = _asString(data['experience_level']);
    if (experienceLevel != null && experienceLevel.isNotEmpty) {
      return experienceLevel;
    }

    final minYears = _parseMinYearsExperience(data['experience_level']);
    if (minYears > 0) {
      return '$minYears an(s)';
    }

    final requiredLevel = _asString(data['required_level']);
    if (requiredLevel != null && requiredLevel.isNotEmpty) {
      return requiredLevel;
    }

    return 'Non precise';
  }

  int _parseMinYearsExperience(dynamic value) {
    final raw = _asString(value);
    if (raw == null) {
      return 0;
    }

    final match = RegExp(r'(\d+)').firstMatch(raw);
    if (match == null) {
      return 0;
    }

    return int.tryParse(match.group(1) ?? '') ?? 0;
  }

  String _formatOfferDeadline(dynamic value) {
    final raw = _asString(value);
    if (raw == null || raw.isEmpty) {
      return 'Date limite non precisee';
    }

    final date = DateTime.tryParse(raw);
    if (date == null) {
      return 'Date limite non precisee';
    }

    return 'Cloture le ${DateFormat('dd/MM/yyyy').format(date.toLocal())}';
  }

  String _formatTrainingFormat(dynamic value) {
    switch ((_asString(value) ?? '').toLowerCase()) {
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

  String _formatTrainingLevel(dynamic value) {
    switch ((_asString(value) ?? '').toLowerCase()) {
      case 'beginner':
        return 'Debutant';
      case 'intermediate':
        return 'Intermediaire';
      case 'advanced':
        return 'Avance';
      default:
        return _firstNonEmpty([
          _asString(value),
        ], fallback: 'Tous niveaux');
    }
  }

  String _formatTrainingStatus(Map<String, dynamic> data) {
    final status = (_asString(data['status']) ?? '').toLowerCase();
    if (status == 'active' || status == 'published') {
      return 'Disponible';
    }

    return _firstNonEmpty([
      _asString(data['status']),
    ], fallback: 'Disponible');
  }

  String _formatTrainingDuration(Map<String, dynamic> data) {
    final explicit = _firstNonEmpty([
      _asString(data['duration']),
      _asString(data['duration_label']),
    ], fallback: '');
    if (explicit.isNotEmpty) {
      return explicit;
    }

    final hours = _asNum(data['duration_hours'] ?? data['hours_count']);
    if (hours != null && hours > 0) {
      return '${hours.round()} h';
    }

    final weeks = _asNum(data['duration_weeks']);
    if (weeks != null && weeks > 0) {
      return '${weeks.round()} semaine(s)';
    }

    return 'Duree non precisee';
  }

  String _formatTrainingCertification(Map<String, dynamic> data) {
    if (_asBool(data['certificate_available'] ?? data['has_certificate'])) {
      return 'Certificat disponible';
    }

    return _firstNonEmpty([
      _asString(data['certificate_label']),
      _asString(data['certification']),
    ], fallback: 'Certification non precisee');
  }

  String _formatTrainingDateLabel(
    dynamic value, {
    required String fallback,
  }) {
    final raw = _asString(value);
    if (raw == null || raw.isEmpty) {
      return fallback;
    }

    final date = DateTime.tryParse(raw);
    if (date == null) {
      return raw;
    }

    return DateFormat('dd/MM/yyyy').format(date.toLocal());
  }

  String _formatTrainingPrice(dynamic value) {
    final cost = _asNum(value);
    if (cost == null || cost <= 0) {
      return 'Gratuite';
    }

    return '${_formatMoney(cost)} XOF';
  }

  String _resolveTrainingProviderName(Map<String, dynamic>? provider) {
    final employerProfile = _asMap(provider?['employer_profile']);

    return _firstNonEmpty([
      _asString(employerProfile?['company_name']),
      _joinNames(
        _asString(provider?['first_name']),
        _asString(provider?['last_name']),
      ),
      _asString(provider?['email']),
    ], fallback: 'Organisme de formation');
  }

  String _joinNames(String? firstName, String? lastName) {
    final values = [
      if (firstName != null && firstName.trim().isNotEmpty) firstName.trim(),
      if (lastName != null && lastName.trim().isNotEmpty) lastName.trim(),
    ];

    return values.join(' ').trim();
  }

  String _friendlyErrorMessage(
    Object error, {
    required String fallback,
  }) {
    final raw = error.toString().replaceFirst('Exception: ', '').trim();
    final lower = raw.toLowerCase();

    // Coupures reseau / API injoignable.
    if (lower.contains('socketexception') ||
        lower.contains('handshakeexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('impossible de joindre') ||
        lower.contains('unable to connect') ||
        lower.contains('timeoutexception') ||
        lower.contains('connection timeout')) {
      return 'Connexion au service impossible. Verifiez votre reseau et reessayez.';
    }

    // 404 / route inexistante (jargon Laravel).
    if (lower.contains('could not be found') ||
        lower.contains('route ') && lower.contains('not found') ||
        lower.contains('404')) {
      return 'Cette action n\'est pas encore disponible. Reessayez plus tard.';
    }

    // 401 / session expiree.
    if (lower.contains('unauthenticated') ||
        lower.contains('unauthorized') ||
        lower.contains('session introuvable') ||
        lower.contains('401')) {
      return 'Votre session a expire. Connectez-vous pour continuer.';
    }

    // 403 / acces refuse.
    if (lower.contains('forbidden') || lower.contains('403')) {
      return 'Vous n\'avez pas les droits pour cette action.';
    }

    // 500 / erreur serveur.
    if (lower.contains('server error') ||
        lower.contains('internal server') ||
        lower.contains('500')) {
      return 'Une erreur serveur est survenue. Notre equipe est prevenue.';
    }

    // 422 / validation.
    if (lower.contains('validation') || lower.contains('422')) {
      return raw.isEmpty ? 'Donnees invalides.' : raw;
    }

    // Messages tres techniques (URLs, UUIDs, balises) → fallback metier.
    final looksTechnical = raw.contains('api/') ||
        raw.contains('http') ||
        RegExp(r'[0-9a-f]{8}-[0-9a-f]{4}').hasMatch(lower);
    if (looksTechnical) {
      return fallback;
    }

    return raw.isEmpty ? fallback : raw;
  }

  String _extractApiMessage(
    Map<String, dynamic> data, {
    required String fallback,
  }) {
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }

    final errors = data['errors'];
    if (errors is Map<String, dynamic>) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }

    return fallback;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry('$key', val));
    }
    return null;
  }

  List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => _asString(item))
          .whereType<String>()
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }

  List<String> _asTextList(dynamic value) {
    if (value is List) {
      return _asStringList(value);
    }

    final raw = _asString(value);
    if (raw == null) {
      return const [];
    }

    return raw
        .split(RegExp(r'\r\n|\r|\n|;'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  String? _asString(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();
    return text.isEmpty || text == 'null' ? null : text;
  }

  int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(_asString(value) ?? '') ?? 0;
  }

  double _asDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(_asString(value) ?? '') ?? 0;
  }

  num? _asNum(dynamic value) {
    if (value is num) {
      return value;
    }
    return num.tryParse(_asString(value) ?? '');
  }

  bool _asBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }

    final text = (_asString(value) ?? '').toLowerCase();
    return text == '1' || text == 'true' || text == 'yes';
  }

  String _formatMoney(num value) {
    return HomeController._moneyFormat.format(value.round());
  }

  String _firstNonEmpty(
    Iterable<String?> values, {
    required String fallback,
  }) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return fallback;
  }

}
