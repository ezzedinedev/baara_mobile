/// Entité métier pure représentant une offre d'emploi.
class Offer {
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
  final bool isRemote;
  final DateTime? createdAt;
  final String? experienceLabel;
  final String? deadlineLabel;

  /// Mise en avant (boost). [boostTier] : 0 = non boostée, 1 = Essentiel,
  /// 2 = Populaire, 3 = Pro. [boostLabel] = badge à afficher (distinct par plan).
  final bool isBoosted;
  final int boostTier;
  final String? boostLabel;

  /// État utilisateur injecté par le backend quand l'utilisateur est connecté.
  /// null = non authentifié ou endpoint public (liste sans auth).
  final bool? isSaved;
  final bool? isApplied;
  final String? applicationId;
  final String? applicationStatus;
  final List<ScreeningQuestion> screeningQuestions;

  const Offer({
    required this.id,
    required this.title,
    required this.company,
    this.companyLogo,
    required this.location,
    required this.salary,
    required this.contractType,
    required this.requiredSkills,
    required this.minYearsExperience,
    required this.description,
    required this.sector,
    required this.isRemote,
    this.createdAt,
    this.experienceLabel,
    this.deadlineLabel,
    this.isBoosted = false,
    this.boostTier = 0,
    this.boostLabel,
    this.isSaved,
    this.isApplied,
    this.applicationId,
    this.applicationStatus,
    this.screeningQuestions = const [],
  });

  bool get hasScreeningQuestions => screeningQuestions.isNotEmpty;
}

class ScreeningQuestion {
  final String id;
  final String label;
  final String type;
  final bool required;
  final List<String> options;

  const ScreeningQuestion({
    required this.id,
    required this.label,
    this.type = 'text',
    this.required = false,
    this.options = const [],
  });
}
