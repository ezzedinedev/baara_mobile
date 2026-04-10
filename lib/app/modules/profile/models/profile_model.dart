class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.country,
    required this.city,
    required this.userType,
    required this.avatarUrl,
    required this.headline,
    required this.bio,
    required this.skills,
    required this.experiences,
    required this.educations,
    required this.languages,
    required this.isProfileComplete,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String country;
  final String city;
  final String userType;
  final String? avatarUrl;
  final String? headline;
  final String? bio;
  final List<String> skills;
  final List<ExperienceModel> experiences;
  final List<EducationModel> educations;
  final List<LanguageModel> languages;
  final bool isProfileComplete;

  String get fullName => '$firstName $lastName';

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id']?.toString() ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      country: json['country'] ?? '',
      city: json['city'] ?? '',
      userType: json['user_type'] ?? 'candidate',
      avatarUrl: json['avatar'] ?? json['avatar_url'] ?? json['profile_picture'],
      headline: json['headline'] ?? json['title'] ?? json['job_title'],
      bio: json['bio'] ?? json['about'] ?? json['description'],
      skills: _parseList(json['skills']),
      experiences: _parseExperiences(json['experiences'] ?? json['work_experience']),
      educations: _parseEducations(json['educations'] ?? json['education']),
      languages: _parseLanguages(json['languages']),
      isProfileComplete: json['is_profile_complete'] ?? json['is_complete'] ?? false,
    );
  }

  static List<String> _parseList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) return value.split(',').map((e) => e.trim()).toList();
    return [];
  }

  static List<ExperienceModel> _parseExperiences(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => ExperienceModel.fromJson(e)).toList();
    return [];
  }

  static List<EducationModel> _parseEducations(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => EducationModel.fromJson(e)).toList();
    return [];
  }

  static List<LanguageModel> _parseLanguages(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => LanguageModel.fromJson(e)).toList();
    return [];
  }
}

class ExperienceModel {
  const ExperienceModel({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.isCurrent,
    required this.description,
  });

  final String id;
  final String title;
  final String company;
  final String location;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final String? description;

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

  String get dateLabel {
    final start = '${startDate.month}/${startDate.year}';
    if (isCurrent) return '$start - Present';
    if (endDate != null) return '$start - ${endDate!.month}/${endDate!.year}';
    return start;
  }
}

class EducationModel {
  const EducationModel({
    required this.id,
    required this.degree,
    required this.institution,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.fieldOfStudy,
    required this.grade,
  });

  final String id;
  final String degree;
  final String institution;
  final String location;
  final DateTime startDate;
  final DateTime? endDate;
  final String? fieldOfStudy;
  final String? grade;

  factory EducationModel.fromJson(Map<String, dynamic> json) {
    return EducationModel(
      id: json['id']?.toString() ?? '',
      degree: json['degree'] ?? json['diploma'] ?? '',
      institution: json['institution'] ?? json['school'] ?? json['university'] ?? '',
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

class LanguageModel {
  const LanguageModel({
    required this.id,
    required this.name,
    required this.level,
  });

  final String id;
  final String name;
  final String level;

  factory LanguageModel.fromJson(Map<String, dynamic> json) {
    return LanguageModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['language'] ?? '',
      level: json['level'] ?? json['proficiency'] ?? 'Intermediate',
    );
  }
}

class CvModel {
  const CvModel({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.fileSize,
    required this.uploadedAt,
    required this.isDefault,
  });

  final String id;
  final String fileName;
  final String fileUrl;
  final int fileSize;
  final DateTime uploadedAt;
  final bool isDefault;

  factory CvModel.fromJson(Map<String, dynamic> json) {
    return CvModel(
      id: json['id']?.toString() ?? '',
      fileName: json['file_name'] ?? json['name'] ?? 'CV.pdf',
      fileUrl: json['file_url'] ?? json['url'] ?? '',
      fileSize: json['file_size'] ?? json['size'] ?? 0,
      uploadedAt: _parseDate(json['uploaded_at'] ?? json['created_at']),
      isDefault: json['is_default'] ?? json['default'] ?? false,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  String get sizeLabel {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class PortfolioProjectModel {
  const PortfolioProjectModel({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.images,
    required this.tags,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String? url;
  final List<String> images;
  final List<String> tags;
  final DateTime createdAt;

  factory PortfolioProjectModel.fromJson(Map<String, dynamic> json) {
    return PortfolioProjectModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? json['link'] ?? json['website'],
      images: _parseImages(json['images'] ?? json['screenshots']),
      tags: _parseList(json['tags'] ?? json['technologies']),
      createdAt: _parseDate(json['created_at']),
    );
  }

  static List<String> _parseImages(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  static List<String> _parseList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }
}

class SettingsModel {
  const SettingsModel({
    required this.notificationsEnabled,
    required this.emailNotifications,
    required this.smsNotifications,
    required this.pushNotifications,
    required this.language,
    required this.theme,
    required this.isPrivateProfile,
  });

  final bool notificationsEnabled;
  final bool emailNotifications;
  final bool smsNotifications;
  final bool pushNotifications;
  final String language;
  final String theme;
  final bool isPrivateProfile;

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      notificationsEnabled: json['notifications_enabled'] ?? true,
      emailNotifications: json['email_notifications'] ?? true,
      smsNotifications: json['sms_notifications'] ?? false,
      pushNotifications: json['push_notifications'] ?? true,
      language: json['language'] ?? 'fr',
      theme: json['theme'] ?? 'light',
      isPrivateProfile: json['is_private_profile'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notifications_enabled': notificationsEnabled,
      'email_notifications': emailNotifications,
      'sms_notifications': smsNotifications,
      'push_notifications': pushNotifications,
      'language': language,
      'theme': theme,
      'is_private_profile': isPrivateProfile,
    };
  }
}