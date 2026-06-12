import '../../domain/entities/profile.dart';

class ProfileModel extends Profile {
  const ProfileModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.email,
    required super.phone,
    required super.country,
    required super.city,
    required super.userType,
    super.avatarUrl,
    super.headline,
    super.bio,
    required super.skills,
    required super.experiences,
    required super.educations,
    required super.languages,
    required super.isProfileComplete,
    super.dateOfBirth,
    super.nationality,
    super.countryResidence,
    super.linkedinUrl,
    super.githubUrl,
    super.portfolioUrl,
    super.desiredRole,
    super.notificationsEnabled,
    super.notificationChannels,
    super.teamActivity,
    super.themePref,
    super.languagePref,
    super.profileVisibility,
  });

  /// Clés des canaux de notification renvoyées par le backend.
  static const _channelKeys = <String>[
    'offer_updates',
    'application_updates',
    'match_alerts',
    'message_alerts',
    'training_updates',
  ];

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : json;
    final profile = json['profile'] is Map<String, dynamic>
        ? json['profile'] as Map<String, dynamic>
        : <String, dynamic>{};
    final cv = json['cv'] is Map<String, dynamic>
        ? json['cv'] as Map<String, dynamic>
        : <String, dynamic>{};

    final prefs = user['preferences'] is Map<String, dynamic>
        ? user['preferences'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final notif = prefs['notifications'] is Map<String, dynamic>
        ? prefs['notifications'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final apparence = prefs['apparence'] is Map<String, dynamic>
        ? prefs['apparence'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return ProfileModel(
      id: user['id']?.toString() ?? '',
      firstName: user['first_name'] ?? '',
      lastName: user['last_name'] ?? '',
      email: user['email'] ?? '',
      phone: user['phone'] ?? '',
      country: user['country'] ?? user['region'] ?? '',
      city: user['city'] ?? '',
      userType: user['user_type'] ?? 'candidate',
      avatarUrl:
          user['avatar_url'] ?? user['avatar'] ?? user['profile_picture'],
      headline: profile['headline'] ?? cv['desired_role'] ?? user['headline'],
      bio: profile['summary'] ?? cv['bio'] ?? user['bio'],
      skills: _parseList(profile['skills'] ?? cv['hard_skills']),
      experiences: _parseExperiences(cv['experiences'] ?? user['experiences']),
      educations: _parseEducations(
          cv['educations'] ?? user['educations'] ?? user['education']),
      languages: _parseLanguages(cv['languages'] ?? profile['languages']),
      isProfileComplete:
          user['is_profile_complete'] ?? user['is_complete'] ?? false,
      dateOfBirth: cv['date_of_birth'] != null
          ? DateTime.tryParse(cv['date_of_birth'].toString())
          : null,
      nationality: cv['nationality'],
      countryResidence: cv['country_residence'],
      linkedinUrl: cv['linkedin_url'],
      githubUrl: cv['github_url'],
      portfolioUrl: cv['portfolio_url'],
      desiredRole: cv['desired_role'],
      notificationsEnabled: _parseBool(notif['enabled'], fallback: true),
      notificationChannels: {
        for (final k in _channelKeys) k: _parseBool(notif[k], fallback: true),
      },
      teamActivity: _parseBool(notif['team_activity'], fallback: false),
      themePref: (apparence['theme'] ?? 'light').toString(),
      languagePref: (apparence['language'] ?? 'fr').toString(),
      profileVisibility: _parseVisibility(
        json['profile_visibility'] ??
            user['profile_visibility'] ??
            prefs['profile_visibility'],
      ),
    );
  }

  /// Normalise la visibilité du profil ('public' | 'connections'),
  /// défaut 'public' si valeur absente/inconnue.
  static String _parseVisibility(dynamic value) {
    final v = value?.toString().trim().toLowerCase();
    return v == 'connections' ? 'connections' : 'public';
  }

  static bool _parseBool(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value == 'true' || value == '1';
    return fallback;
  }

  static List<String> _parseList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) return value.split(',').map((e) => e.trim()).toList();
    return [];
  }

  static List<ExperienceModel> _parseExperiences(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => ExperienceModel.fromJson(e)).toList();
    }
    return [];
  }

  static List<EducationModel> _parseEducations(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => EducationModel.fromJson(e)).toList();
    }
    return [];
  }

  static List<LanguageModel> _parseLanguages(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => LanguageModel.fromJson(e)).toList();
    }
    return [];
  }
}

class ExperienceModel extends Experience {
  const ExperienceModel({
    required super.id,
    required super.title,
    required super.company,
    required super.location,
    required super.startDate,
    super.endDate,
    required super.isCurrent,
    super.description,
  });

  factory ExperienceModel.fromJson(Map<String, dynamic> json) {
    return ExperienceModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['job_title'] ?? '',
      company: json['company'] ?? json['company_name'] ?? '',
      location: json['location'] ?? '',
      startDate: _parseDate(json['start_date']),
      endDate: json['end_date'] != null ? _parseDate(json['end_date']) : null,
      isCurrent: json['is_current'] ?? json['current'] ?? false,
      description: json['description'] ?? json['responsibilities'],
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}

class EducationModel extends Education {
  const EducationModel({
    required super.id,
    required super.degree,
    required super.institution,
    required super.location,
    required super.startDate,
    super.endDate,
    super.fieldOfStudy,
    super.grade,
  });

  factory EducationModel.fromJson(Map<String, dynamic> json) {
    return EducationModel(
      id: json['id']?.toString() ?? '',
      degree: json['degree'] ?? json['diploma'] ?? '',
      institution:
          json['institution'] ?? json['school'] ?? json['university'] ?? '',
      location: json['location'] ?? '',
      startDate: _parseDate(json['start_date']),
      endDate: json['end_date'] != null ? _parseDate(json['end_date']) : null,
      fieldOfStudy: json['field_of_study'] ?? json['major'],
      grade: json['grade'] ?? json['gpa'],
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}

class LanguageModel extends Language {
  const LanguageModel({
    required super.id,
    required super.name,
    required super.level,
  });

  factory LanguageModel.fromJson(Map<String, dynamic> json) {
    return LanguageModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['language'] ?? '',
      level: json['level'] ?? json['proficiency'] ?? 'Intermediate',
    );
  }
}
