/// Utilisateur tel qu'exposé par l'API Communauté (auteur de post, membre…).
class NetworkUser {
  final String id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String userType; // candidate | employer | admin
  final String role; // headline ou nom d'entreprise
  final String? avatarUrl;

  /// L'utilisateur courant suit déjà ce membre (exposé par le feed/suggestions).
  final bool isFollowing;

  /// Ce membre est l'utilisateur courant (pas de bouton « Suivre »).
  final bool isSelf;

  /// État de connexion réseau avec l'utilisateur courant :
  /// `none` | `pending_sent` | `pending_received` | `connected`.
  final String connectionStatus;

  const NetworkUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.userType,
    required this.role,
    this.avatarUrl,
    this.isFollowing = false,
    this.isSelf = false,
    this.connectionStatus = 'none',
  });

  String get initial =>
      (firstName.isNotEmpty ? firstName[0] : 'U').toUpperCase();

  /// Compte vérifié (badge) : l'API expose les administrateurs comme tels.
  bool get isVerified => userType == 'admin';

  NetworkUser copyWith({bool? isFollowing, String? connectionStatus}) =>
      NetworkUser(
        id: id,
        firstName: firstName,
        lastName: lastName,
        fullName: fullName,
        userType: userType,
        role: role,
        avatarUrl: avatarUrl,
        isFollowing: isFollowing ?? this.isFollowing,
        isSelf: isSelf,
        connectionStatus: connectionStatus ?? this.connectionStatus,
      );
}
