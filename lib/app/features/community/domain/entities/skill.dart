/// Compétence professionnelle exposée sur un profil communauté, avec son
/// compteur de recommandations (endorsements) et l'état « recommandé par moi ».
class Skill {
  final String id;
  final String name;
  final int position;
  final int endorsementsCount;
  final bool endorsedByMe;

  const Skill({
    required this.id,
    required this.name,
    this.position = 0,
    this.endorsementsCount = 0,
    this.endorsedByMe = false,
  });

  factory Skill.fromJson(Map<String, dynamic> json) => Skill(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        position: (json['position'] as num?)?.toInt() ?? 0,
        endorsementsCount: (json['endorsements_count'] as num?)?.toInt() ?? 0,
        endorsedByMe: json['endorsed_by_me'] == true,
      );

  Skill copyWith({
    int? endorsementsCount,
    bool? endorsedByMe,
  }) =>
      Skill(
        id: id,
        name: name,
        position: position,
        endorsementsCount: endorsementsCount ?? this.endorsementsCount,
        endorsedByMe: endorsedByMe ?? this.endorsedByMe,
      );
}
