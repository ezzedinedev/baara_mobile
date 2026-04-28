part of '../home_profile_manager.dart';

/// Parsers et helpers extraits de HomeProfileManager.
extension HomeProfileManagerParsing on HomeProfileManager {
  List<HomeCvSection> _sortedCvSections() {
    final sections = cvSections.toList(growable: true);
    sections.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return sections;
  }

  String _cvDownloadFileName() {
    final rawName =
        profile.value.fullName.trim().isEmpty ? 'cv' : profile.value.fullName;
    final safeName = rawName
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return '${safeName.isEmpty ? 'cv' : safeName}_${selectedCvTemplate.value}.pdf';
  }

  HomeUserProfile _parseProfile(Map<String, dynamic> payload) {
    final user = _asMap(payload['user']) ?? const <String, dynamic>{};
    final profileData = _asMap(payload['profile']) ?? const <String, dynamic>{};
    final id = _asString(user['id']) ?? '';
    final createdAt = DateTime.tryParse(_asString(user['created_at']) ?? '');

    return HomeUserProfile(
      id: id,
      firstName: _asString(user['first_name']) ?? '',
      lastName: _asString(user['last_name']) ?? '',
      email: _asString(user['email']) ?? '',
      phone: _asString(user['phone']) ?? '',
      avatarUrl: _resolveAssetUrl(_asString(user['avatar_url']) ?? ''),
      city: _asString(user['city']) ?? '',
      region: _asString(user['region']) ?? '',
      userType: _asString(user['user_type']) ?? 'candidate',
      headline: _asString(profileData['headline']) ?? '',
      summary: _asString(profileData['summary']) ?? '',
      skills: _asStringList(profileData['skills']),
      memberSinceLabel: createdAt == null
          ? 'Non renseigne'
          : DateFormat('dd/MM/yyyy').format(createdAt.toLocal()),
      referenceLabel: id.isEmpty
          ? 'ID indisponible'
          : 'WEP-${id.substring(0, 4).toUpperCase()}-${id.substring(id.length - 4).toUpperCase()}',
      isVerified: _asBool(
        profileData['is_verified'] ?? profileData['credibility_badge'],
      ),
    );
  }

  HomeProfilePreferences _parsePreferences(dynamic payload) {
    final data = _asMap(payload) ?? const <String, dynamic>{};
    final notifications =
        _asMap(data['notifications']) ?? const <String, dynamic>{};
    final appearance = _asMap(data['apparence']) ?? const <String, dynamic>{};

    return HomeProfilePreferences(
      notificationsEnabled: _asBool(notifications['enabled']),
      offerUpdates: _asBool(notifications['offer_updates']),
      applicationUpdates: _asBool(notifications['application_updates']),
      matchAlerts: _asBool(notifications['match_alerts']),
      messageAlerts: _asBool(notifications['message_alerts']),
      trainingUpdates: _asBool(notifications['training_updates']),
      theme: _asString(appearance['theme']) ?? 'light',
      language: _asString(appearance['language']) ?? 'fr',
    );
  }

  HomeUploadedCv? _parseUploadedCvFromPayload(
    dynamic payload, {
    String fallbackFileName = '',
  }) {
    final data = _asMap(payload);
    if (data == null) {
      return fallbackFileName.trim().isEmpty
          ? null
          : HomeUploadedCv(
              fileName: fallbackFileName,
              url: '',
              mimeType: '',
              uploadedAt: DateTime.now(),
            );
    }

    final nested = _asMap(data['uploaded_cv']) ??
        _asMap(data['cv_file']) ??
        _asMap(data['file']) ??
        data;

    final fileName = _firstNonEmpty([
      _asString(nested['file_name']),
      _asString(nested['filename']),
      _asString(nested['name']),
      fallbackFileName,
    ]);
    final rawUrl = _firstNonEmpty([
      _asString(nested['url']),
      _asString(nested['file_url']),
      _asString(nested['path']),
    ]);

    if (fileName.isEmpty && rawUrl.isEmpty) {
      return null;
    }

    return HomeUploadedCv(
      fileName: fileName,
      url: rawUrl.isEmpty ? '' : _resolveAssetUrl(rawUrl),
      mimeType: _firstNonEmpty([
        _asString(nested['mime_type']),
        _asString(nested['mime']),
      ]),
      uploadedAt: DateTime.tryParse(
        _firstNonEmpty([
          _asString(nested['uploaded_at']),
          _asString(nested['created_at']),
        ]),
      ),
    );
  }

  HomeCvSection? _parseCvSection(dynamic payload) {
    final data = _asMap(payload);
    if (data == null) {
      return null;
    }

    return HomeCvSection(
      id: _asString(data['id']),
      sectionType: _asString(data['section_type']) ?? 'experience',
      title: _asString(data['title']) ?? '',
      organization: _asString(data['organization']) ?? '',
      startDate: DateTime.tryParse(_asString(data['start_date']) ?? ''),
      endDate: DateTime.tryParse(_asString(data['end_date']) ?? ''),
      isCurrent: _asBool(data['is_current']),
      description: _asString(data['description']) ?? '',
      missions: _asStringList(data['missions']),
      achievements: _asStringList(data['achievements']),
      level: _asString(data['level']) ?? '',
      mention: _asString(data['mention']) ?? '',
      externalUrl: _asString(data['external_url']) ?? '',
      displayOrder: _asInt(data['display_order']),
    );
  }

  HomePortfolioItem? _parsePortfolioItem(dynamic payload) {
    final data = _asMap(payload);
    if (data == null) {
      return null;
    }

    return HomePortfolioItem(
      id: _asString(data['id']),
      itemType: _asString(data['item_type']) ?? 'project',
      title: _asString(data['title']) ?? '',
      description: _asString(data['description']) ?? '',
      results: _asString(data['results']) ?? '',
      externalUrl: _asString(data['external_url']) ?? '',
      techStack: _asStringList(data['tech_stack']),
      mediaUrls: _asStringList(data['media_urls'])
          .map(_resolveAssetUrl)
          .toList(growable: false),
      displayOrder: _asInt(data['display_order']),
      isVerified: _asBool(data['is_verified']),
      isPublic:
          data.containsKey('is_public') ? _asBool(data['is_public']) : true,
    );
  }

  List<dynamic> _extractItems(dynamic payload) {
    if (payload is List) {
      return payload;
    }

    final map = _asMap(payload);
    if (map == null) {
      return const [];
    }

    if (map['items'] is List) {
      return map['items'] as List<dynamic>;
    }

    if (map['data'] is List) {
      return map['data'] as List<dynamic>;
    }

    return const [];
  }

  Future<String> _readToken() async {
    return _tokenStore.readToken();
  }

  String _resolveAssetUrl(String value) => resolveAssetUrl(value);

  String _friendlyErrorMessage(
    Object error, {
    required String fallback,
  }) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.contains('Impossible de joindre l\'API')) {
      return 'Connexion au service impossible pour le moment.';
    }
    return message.isEmpty ? fallback : message;
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

  String? _asString(dynamic value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty || text == 'null' ? null : text;
  }

  String _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => _asString(item))
          .whereType<String>()
          .where((item) => item.trim().isNotEmpty)
          .toList(growable: false);
    }
    return const [];
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

  int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(_asString(value) ?? '') ?? 0;
  }

  String? _formatIsoDate(DateTime? date) {
    if (date == null) {
      return null;
    }
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _sectionLabel(String sectionType) {
    switch (sectionType) {
      case 'experience':
        return 'Experience';
      case 'education':
        return 'Formation';
      case 'certification':
        return 'Certification';
      case 'skill':
        return 'Competence';
      case 'language':
        return 'Langues';
      case 'project':
        return 'Projet';
      case 'volunteer':
        return 'Benevolat';
      case 'award':
        return 'Prix et distinctions';
      case 'publication':
        return 'Publications';
      case 'reference':
        return 'References';
      case 'other':
        return 'Autres informations';
      default:
        return sectionType;
    }
  }

  String _englishSectionLabel(String sectionType) {
    switch (sectionType) {
      case 'experience':
        return 'Professional experience';
      case 'education':
        return 'Education';
      case 'certification':
        return 'Certifications';
      case 'skill':
        return 'Skills';
      case 'language':
        return 'Languages';
      case 'project':
        return 'Projects';
      case 'volunteer':
        return 'Volunteer work';
      case 'award':
        return 'Awards';
      case 'publication':
        return 'Publications';
      case 'reference':
        return 'References';
      case 'other':
        return 'Additional information';
      default:
        return sectionType;
    }
  }

  String _formatCvSectionDates(HomeCvSection section) {
    final start = section.startDate == null
        ? ''
        : DateFormat('MM/yyyy').format(section.startDate!);
    final end = section.isCurrent
        ? 'Present'
        : section.endDate == null
            ? ''
            : DateFormat('MM/yyyy').format(section.endDate!);

    if (start.isEmpty && end.isEmpty) {
      return '';
    }
    if (start.isEmpty) {
      return end;
    }
    if (end.isEmpty) {
      return start;
    }
    return '$start - $end';
  }
}
