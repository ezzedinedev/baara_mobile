/// Entité représentant l'expérience professionnelle.
class Experience {
  final String id;
  final String title;
  final String company;
  final String location;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final String? description;

  const Experience({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.startDate,
    this.endDate,
    required this.isCurrent,
    this.description,
  });
}

/// Entité représentant le parcours académique.
class Education {
  final String id;
  final String degree;
  final String institution;
  final String location;
  final DateTime startDate;
  final DateTime? endDate;
  final String? fieldOfStudy;
  final String? grade;

  const Education({
    required this.id,
    required this.degree,
    required this.institution,
    required this.location,
    required this.startDate,
    this.endDate,
    this.fieldOfStudy,
    this.grade,
  });
}

/// Entité représentant une langue maîtrisée.
class Language {
  final String id;
  final String name;
  final String level;

  const Language({
    required this.id,
    required this.name,
    required this.level,
  });
}

/// Entité centrale du profil utilisateur.
class Profile {
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
  final List<Experience> experiences;
  final List<Education> educations;
  final List<Language> languages;
  final bool isProfileComplete;
  final DateTime? dateOfBirth;
  final String? nationality;
  final String? countryResidence;
  final String? linkedinUrl;
  final String? githubUrl;
  final String? portfolioUrl;
  final String? desiredRole;

  const Profile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.country,
    required this.city,
    required this.userType,
    this.avatarUrl,
    this.headline,
    this.bio,
    required this.skills,
    required this.experiences,
    required this.educations,
    required this.languages,
    required this.isProfileComplete,
    this.dateOfBirth,
    this.nationality,
    this.countryResidence,
    this.linkedinUrl,
    this.githubUrl,
    this.portfolioUrl,
    this.desiredRole,
  });

  String get fullName => '$firstName $lastName';
}
