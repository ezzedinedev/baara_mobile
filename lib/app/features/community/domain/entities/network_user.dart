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

  /// Raison de la suggestion exposée par l'IA / le backend
  /// (`GET /community/suggestions`), ex. « 2 relations en commun »,
  /// « Même secteur ». Nul hors contexte suggestions (recherche, connexions).
  final String? reason;

  /// Nombre de relations en commun (signal de la suggestion).
  final int mutualCount;

  /// La suggestion partage le même secteur d'activité que l'utilisateur.
  final bool sameSector;

  /// La suggestion partage la même ville que l'utilisateur.
  final bool sameCity;

  /// Phrase d'accroche générée par l'IA pour cette suggestion
  /// (`GET /community/suggestions/insight`). Arrive après la liste, de façon
  /// non bloquante. Nul tant qu'aucun insight n'a été reçu.
  final String? insight;

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
    this.reason,
    this.mutualCount = 0,
    this.sameSector = false,
    this.sameCity = false,
    this.insight,
  });

  String get initial =>
      (firstName.isNotEmpty ? firstName[0] : 'U').toUpperCase();

  /// Compte vérifié (badge) : l'API expose les administrateurs comme tels.
  bool get isVerified => userType == 'admin';

  /// Une raison de suggestion exploitable est disponible.
  bool get hasReason => reason != null && reason!.trim().isNotEmpty;

  /// Une accroche IA exploitable est disponible.
  bool get hasInsight => insight != null && insight!.trim().isNotEmpty;

  NetworkUser copyWith({
    bool? isFollowing,
    String? connectionStatus,
    String? insight,
  }) =>
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
        reason: reason,
        mutualCount: mutualCount,
        sameSector: sameSector,
        sameCity: sameCity,
        insight: insight ?? this.insight,
      );
}
