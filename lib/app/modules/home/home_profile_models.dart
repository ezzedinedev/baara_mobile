class HomeProfilePreferences {
  const HomeProfilePreferences({
    required this.notificationsEnabled,
    required this.offerUpdates,
    required this.applicationUpdates,
    required this.matchAlerts,
    required this.messageAlerts,
    required this.trainingUpdates,
    required this.theme,
    required this.language,
  });

  const HomeProfilePreferences.defaults()
      : notificationsEnabled = true,
        offerUpdates = true,
        applicationUpdates = true,
        matchAlerts = true,
        messageAlerts = true,
        trainingUpdates = true,
        theme = 'light',
        language = 'fr';

  final bool notificationsEnabled;
  final bool offerUpdates;
  final bool applicationUpdates;
  final bool matchAlerts;
  final bool messageAlerts;
  final bool trainingUpdates;
  final String theme;
  final String language;

  HomeProfilePreferences copyWith({
    bool? notificationsEnabled,
    bool? offerUpdates,
    bool? applicationUpdates,
    bool? matchAlerts,
    bool? messageAlerts,
    bool? trainingUpdates,
    String? theme,
    String? language,
  }) {
    return HomeProfilePreferences(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      offerUpdates: offerUpdates ?? this.offerUpdates,
      applicationUpdates: applicationUpdates ?? this.applicationUpdates,
      matchAlerts: matchAlerts ?? this.matchAlerts,
      messageAlerts: messageAlerts ?? this.messageAlerts,
      trainingUpdates: trainingUpdates ?? this.trainingUpdates,
      theme: theme ?? this.theme,
      language: language ?? this.language,
    );
  }
}

class HomeUserProfile {
  const HomeUserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.city,
    required this.region,
    required this.userType,
    required this.headline,
    required this.summary,
    required this.skills,
    required this.memberSinceLabel,
    required this.referenceLabel,
    required this.isVerified,
  });

  const HomeUserProfile.empty()
      : id = '',
        firstName = '',
        lastName = '',
        email = '',
        phone = '',
        avatarUrl = '',
        city = '',
        region = '',
        userType = 'candidate',
        headline = '',
        summary = '',
        skills = const [],
        memberSinceLabel = '',
        referenceLabel = '',
        isVerified = false;

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String avatarUrl;
  final String city;
  final String region;
  final String userType;
  final String headline;
  final String summary;
  final List<String> skills;
  final String memberSinceLabel;
  final String referenceLabel;
  final bool isVerified;

  String get fullName {
    final value = '$firstName $lastName'.trim();
    return value.isEmpty ? 'Mon profil' : value;
  }

  bool get hasAvatar => avatarUrl.trim().isNotEmpty;

  String get locationLabel {
    final parts = [
      if (city.trim().isNotEmpty) city.trim(),
      if (region.trim().isNotEmpty) region.trim(),
    ];
    return parts.join(' • ');
  }

  HomeUserProfile copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? avatarUrl,
    String? city,
    String? region,
    String? userType,
    String? headline,
    String? summary,
    List<String>? skills,
    String? memberSinceLabel,
    String? referenceLabel,
    bool? isVerified,
  }) {
    return HomeUserProfile(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      city: city ?? this.city,
      region: region ?? this.region,
      userType: userType ?? this.userType,
      headline: headline ?? this.headline,
      summary: summary ?? this.summary,
      skills: skills ?? this.skills,
      memberSinceLabel: memberSinceLabel ?? this.memberSinceLabel,
      referenceLabel: referenceLabel ?? this.referenceLabel,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

class HomeUploadedCv {
  const HomeUploadedCv({
    required this.fileName,
    required this.url,
    required this.mimeType,
    required this.uploadedAt,
  });

  const HomeUploadedCv.empty()
      : fileName = '',
        url = '',
        mimeType = '',
        uploadedAt = null;

  final String fileName;
  final String url;
  final String mimeType;
  final DateTime? uploadedAt;

  bool get hasFile => fileName.trim().isNotEmpty || url.trim().isNotEmpty;
}

class HomeCvTemplateOption {
  const HomeCvTemplateOption({
    required this.id,
    required this.label,
    required this.description,
  });

  final String id;
  final String label;
  final String description;
}

class HomeCvSection {
  const HomeCvSection({
    required this.id,
    required this.sectionType,
    required this.title,
    required this.organization,
    required this.startDate,
    required this.endDate,
    required this.isCurrent,
    required this.description,
    required this.missions,
    required this.achievements,
    required this.level,
    required this.mention,
    required this.externalUrl,
    required this.displayOrder,
  });

  final String? id;
  final String sectionType;
  final String title;
  final String organization;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final String description;
  final List<String> missions;
  final List<String> achievements;
  final String level;
  final String mention;
  final String externalUrl;
  final int displayOrder;

  HomeCvSection copyWith({
    String? id,
    String? sectionType,
    String? title,
    String? organization,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCurrent,
    String? description,
    List<String>? missions,
    List<String>? achievements,
    String? level,
    String? mention,
    String? externalUrl,
    int? displayOrder,
  }) {
    return HomeCvSection(
      id: id ?? this.id,
      sectionType: sectionType ?? this.sectionType,
      title: title ?? this.title,
      organization: organization ?? this.organization,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrent: isCurrent ?? this.isCurrent,
      description: description ?? this.description,
      missions: missions ?? this.missions,
      achievements: achievements ?? this.achievements,
      level: level ?? this.level,
      mention: mention ?? this.mention,
      externalUrl: externalUrl ?? this.externalUrl,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }
}

class HomePortfolioItem {
  const HomePortfolioItem({
    required this.id,
    required this.itemType,
    required this.title,
    required this.description,
    required this.results,
    required this.externalUrl,
    required this.techStack,
    required this.mediaUrls,
    required this.displayOrder,
    required this.isVerified,
    required this.isPublic,
  });

  final String? id;
  final String itemType;
  final String title;
  final String description;
  final String results;
  final String externalUrl;
  final List<String> techStack;
  final List<String> mediaUrls;
  final int displayOrder;
  final bool isVerified;
  final bool isPublic;

  HomePortfolioItem copyWith({
    String? id,
    String? itemType,
    String? title,
    String? description,
    String? results,
    String? externalUrl,
    List<String>? techStack,
    List<String>? mediaUrls,
    int? displayOrder,
    bool? isVerified,
    bool? isPublic,
  }) {
    return HomePortfolioItem(
      id: id ?? this.id,
      itemType: itemType ?? this.itemType,
      title: title ?? this.title,
      description: description ?? this.description,
      results: results ?? this.results,
      externalUrl: externalUrl ?? this.externalUrl,
      techStack: techStack ?? this.techStack,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      displayOrder: displayOrder ?? this.displayOrder,
      isVerified: isVerified ?? this.isVerified,
      isPublic: isPublic ?? this.isPublic,
    );
  }
}
