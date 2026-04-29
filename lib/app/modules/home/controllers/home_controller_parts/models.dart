part of '../home_controller.dart';

class HomeNavItem {
  const HomeNavItem({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

class HomeOfferPreview {
  const HomeOfferPreview({
    required this.id,
    required this.title,
    required this.company,
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
  });

  final String id;
  final String title;
  final String company;
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
}

class HomeCandidateProfile {
  const HomeCandidateProfile({
    required this.headline,
    required this.experienceYears,
    required this.preferredLocations,
    required this.preferredContracts,
    required this.skills,
  });

  final String headline;
  final int experienceYears;
  final List<String> preferredLocations;
  final List<String> preferredContracts;
  final List<String> skills;
}

class HomeOfferMatchResult {
  const HomeOfferMatchResult({
    required this.offer,
    required this.score,
  });

  final HomeOfferPreview offer;
  final int score;
}

class HomeFormationPreview {
  const HomeFormationPreview({
    required this.id,
    required this.title,
    required this.providerName,
    required this.location,
    required this.formatLabel,
    required this.level,
    required this.lessons,
    required this.rating,
    required this.enrolledCount,
    required this.status,
    required this.priceLabel,
    required this.priceAmount,
    required this.sector,
    required this.description,
    required this.durationLabel,
    required this.startDateLabel,
    required this.deadlineLabel,
    required this.certificationLabel,
    required this.languageLabel,
    required this.contactLabel,
    required this.objectives,
    required this.requirements,
    required this.modules,
    required this.isEnrolled,
    this.coverUrl = '',
  });

  final String id;
  final String title;
  final String providerName;
  final String location;
  final String formatLabel;
  final String level;
  final int lessons;
  final double rating;
  final int enrolledCount;
  final String status;
  final String priceLabel;
  final num priceAmount;
  final String sector;
  final String description;
  final String durationLabel;
  final String startDateLabel;
  final String deadlineLabel;
  final String certificationLabel;
  final String languageLabel;
  final String contactLabel;
  final List<String> objectives;
  final List<String> requirements;
  final List<HomeTrainingLesson> modules;
  final bool isEnrolled;
  final String coverUrl;

  bool get isPaid => priceAmount > 0;

  double get progressRatio {
    if (modules.isEmpty) {
      return 0;
    }

    final completedCount = modules.where((module) => module.isCompleted).length;
    return completedCount / modules.length;
  }

  int get progressPercent => (progressRatio * 100).round();

  HomeFormationPreview copyWith({
    String? id,
    String? title,
    String? providerName,
    String? location,
    String? formatLabel,
    String? level,
    int? lessons,
    double? rating,
    int? enrolledCount,
    String? status,
    String? priceLabel,
    num? priceAmount,
    String? sector,
    String? description,
    String? durationLabel,
    String? startDateLabel,
    String? deadlineLabel,
    String? certificationLabel,
    String? languageLabel,
    String? contactLabel,
    List<String>? objectives,
    List<String>? requirements,
    List<HomeTrainingLesson>? modules,
    bool? isEnrolled,
    String? coverUrl,
  }) {
    return HomeFormationPreview(
      id: id ?? this.id,
      title: title ?? this.title,
      providerName: providerName ?? this.providerName,
      location: location ?? this.location,
      formatLabel: formatLabel ?? this.formatLabel,
      level: level ?? this.level,
      lessons: lessons ?? this.lessons,
      rating: rating ?? this.rating,
      enrolledCount: enrolledCount ?? this.enrolledCount,
      status: status ?? this.status,
      priceLabel: priceLabel ?? this.priceLabel,
      priceAmount: priceAmount ?? this.priceAmount,
      sector: sector ?? this.sector,
      description: description ?? this.description,
      durationLabel: durationLabel ?? this.durationLabel,
      startDateLabel: startDateLabel ?? this.startDateLabel,
      deadlineLabel: deadlineLabel ?? this.deadlineLabel,
      certificationLabel: certificationLabel ?? this.certificationLabel,
      languageLabel: languageLabel ?? this.languageLabel,
      contactLabel: contactLabel ?? this.contactLabel,
      objectives: objectives ?? this.objectives,
      requirements: requirements ?? this.requirements,
      modules: modules ?? this.modules,
      isEnrolled: isEnrolled ?? this.isEnrolled,
      coverUrl: coverUrl ?? this.coverUrl,
    );
  }
}

class HomeTrainingLesson {
  const HomeTrainingLesson({
    required this.id,
    required this.backendId,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.type,
    required this.typeLabel,
    required this.durationLabel,
    required this.assetUrl,
    required this.thumbnailUrl,
    required this.fileName,
    required this.isCompleted,
  });

  final String id;
  final String backendId;
  final String title;
  final String subtitle;
  final String description;
  final String type;
  final String typeLabel;
  final String durationLabel;
  final String assetUrl;
  final String thumbnailUrl;
  final String fileName;
  final bool isCompleted;

  bool get isVideo => type == 'video';
  bool get isPdf => type == 'pdf';
  bool get isImage => type == 'image';

  HomeTrainingLesson copyWith({
    String? id,
    String? backendId,
    String? title,
    String? subtitle,
    String? description,
    String? type,
    String? typeLabel,
    String? durationLabel,
    String? assetUrl,
    String? thumbnailUrl,
    String? fileName,
    bool? isCompleted,
  }) {
    return HomeTrainingLesson(
      id: id ?? this.id,
      backendId: backendId ?? this.backendId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      type: type ?? this.type,
      typeLabel: typeLabel ?? this.typeLabel,
      durationLabel: durationLabel ?? this.durationLabel,
      assetUrl: assetUrl ?? this.assetUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fileName: fileName ?? this.fileName,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class HomeConversationPreview {
  const HomeConversationPreview({
    required this.id,
    required this.title,
    required this.preview,
    required this.timeLabel,
    required this.unreadCount,
    required this.online,
  });

  final String id;
  final String title;
  final String preview;
  final String timeLabel;
  final int unreadCount;
  final bool online;
}

class HomeChatMessage {
  const HomeChatMessage({
    required this.text,
    required this.sentAt,
    required this.isMine,
  });

  final String text;
  final DateTime sentAt;
  final bool isMine;
}

class HomeNotificationPreview {
  const HomeNotificationPreview({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.createdAt,
    required this.icon,
    required this.isRead,
    this.targetType,
    this.targetId,
  });

  final String id;
  final String title;
  final String body;
  final String category;
  final DateTime createdAt;
  final IconData icon;
  final bool isRead;
  /// Cible deeplink — alimentee par `notifiable_type`/`notifiable_id` cote
  /// backend. Ex: targetType='conversation', targetId='<uuid>'. Utilise
  /// par l'ecran notifications pour ouvrir directement la ressource au
  /// lieu de juste switcher d'onglet.
  final String? targetType;
  final String? targetId;

  HomeNotificationPreview copyWith({
    String? id,
    String? title,
    String? body,
    String? category,
    DateTime? createdAt,
    IconData? icon,
    bool? isRead,
    String? targetType,
    String? targetId,
  }) {
    return HomeNotificationPreview(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      icon: icon ?? this.icon,
      isRead: isRead ?? this.isRead,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
    );
  }
}

