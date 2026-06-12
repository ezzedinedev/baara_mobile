import 'package:opportune_bf/app/core/constants/api_constants.dart';

/// Membre ayant consulté le profil de l'utilisateur courant
/// (« qui a vu mon profil »).
class ProfileViewer {
  final String id;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final String? headline;
  final DateTime? viewedAt;

  const ProfileViewer({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    this.headline,
    this.viewedAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory ProfileViewer.fromJson(Map<String, dynamic> json) => ProfileViewer(
        id: json['id']?.toString() ?? '',
        firstName: json['first_name']?.toString() ?? '',
        lastName: json['last_name']?.toString() ?? '',
        avatarUrl: ApiConstants.resolveMediaUrl(json['avatar_url']?.toString()),
        headline: json['headline']?.toString(),
        viewedAt: json['viewed_at'] != null
            ? DateTime.tryParse(json['viewed_at'].toString())
            : null,
      );
}

/// Résultat paginé/agrégé de l'écran « qui a vu mon profil ».
class ProfileViewsResult {
  final List<ProfileViewer> viewers;
  final int total;

  const ProfileViewsResult({required this.viewers, required this.total});
}
