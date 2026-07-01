class Conversation {
  final String id;
  final String title;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final String? avatar;

  /// Dernière activité connue de l'interlocuteur (depuis `direct_user`).
  /// Utilisé pour « Vu il y a … » quand `isOnline` est faux.
  final DateTime? lastSeenAt;

  /// Identifiant de l'interlocuteur (direct_user.id) — utile pour (r)ouvrir un
  /// DM depuis un profil. Null pour les conversations de recrutement.
  final String? peerUserId;

  /// Conversation en attente d'acceptation (demande de message). Backend:
  /// `is_request` (statut 'pending').
  final bool isRequest;

  /// L'utilisateur courant est l'émetteur de la demande (`is_requester`).
  /// Si false et [isRequest] true → je suis le destinataire : je peux
  /// accepter/refuser.
  final bool isRequester;

  /// Demande de message reçue (à accepter/refuser) : en attente ET je ne suis
  /// pas le demandeur.
  bool get isIncomingRequest => isRequest && !isRequester;

  const Conversation({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.isOnline,
    this.avatar,
    this.lastSeenAt,
    this.peerUserId,
    this.isRequest = false,
    this.isRequester = false,
  });
}
