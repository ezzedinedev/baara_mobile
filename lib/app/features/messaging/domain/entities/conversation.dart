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

  /// Intitulé du poste rattaché à la candidature (`application.offer.title`).
  ///
  /// Un candidat peut avoir plusieurs conversations avec le même employeur —
  /// une par candidature. [title] valant alors le nom de la société pour
  /// toutes, c'est ce champ qui les distingue dans la liste. Null pour les DM
  /// directs et pour les conversations sans candidature liée.
  final String? offerTitle;

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

  Conversation copyWith({
    String? title,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isOnline,
    String? avatar,
    DateTime? lastSeenAt,
    String? peerUserId,
    bool? isRequest,
    bool? isRequester,
    String? offerTitle,
  }) {
    return Conversation(
      id: id,
      title: title ?? this.title,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
      avatar: avatar ?? this.avatar,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      peerUserId: peerUserId ?? this.peerUserId,
      isRequest: isRequest ?? this.isRequest,
      isRequester: isRequester ?? this.isRequester,
      offerTitle: offerTitle ?? this.offerTitle,
    );
  }

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
    this.offerTitle,
  });
}
