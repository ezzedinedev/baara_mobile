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

  const Conversation({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.isOnline,
    this.avatar,
    this.lastSeenAt,
  });
}
