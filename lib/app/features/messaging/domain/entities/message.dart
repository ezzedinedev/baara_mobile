class Message {
  final String id;
  final String text;
  final DateTime sentAt;
  final bool isMine;
  final String senderName;
  final String messageType;
  final String? attachmentUrl;
  final String? fileName;
  final int? fileSize;

  // Contexte « réponse à une story » (FB/Telegram).
  final String? replyToStoryId;
  final StorySnapshot? storySnapshot;

  // Cluster B — temps réel.
  /// Date de lecture du message (côté pair). `null` = non lu.
  final DateTime? readAt;

  /// Récap des réactions par emoji → nombre. Ex: {"👍": 2, "❤️": 1}.
  final Map<String, int> reactionsSummary;

  /// Emoji posé par MOI sur ce message (`null` si aucune).
  final String? myEmoji;

  const Message({
    required this.id,
    required this.text,
    required this.sentAt,
    required this.isMine,
    required this.senderName,
    this.messageType = 'text',
    this.attachmentUrl,
    this.fileName,
    this.fileSize,
    this.replyToStoryId,
    this.storySnapshot,
    this.readAt,
    this.reactionsSummary = const <String, int>{},
    this.myEmoji,
  });

  bool get isStoryReply => replyToStoryId != null || storySnapshot != null;

  bool get isRead => readAt != null;

  /// Copie immuable utilisée pour les maj optimistes (réactions, accusés lus).
  Message copyWith({
    DateTime? readAt,
    bool clearReadAt = false,
    Map<String, int>? reactionsSummary,
    String? myEmoji,
    bool clearMyEmoji = false,
  }) {
    return Message(
      id: id,
      text: text,
      sentAt: sentAt,
      isMine: isMine,
      senderName: senderName,
      messageType: messageType,
      attachmentUrl: attachmentUrl,
      fileName: fileName,
      fileSize: fileSize,
      replyToStoryId: replyToStoryId,
      storySnapshot: storySnapshot,
      readAt: clearReadAt ? null : (readAt ?? this.readAt),
      reactionsSummary: reactionsSummary ?? this.reactionsSummary,
      myEmoji: clearMyEmoji ? null : (myEmoji ?? this.myEmoji),
    );
  }
}

/// Set d'emojis autorisés pour les réactions (parité backend).
const List<String> kReactionEmojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

/// Aperçu de la story à laquelle un message répond (gardé même après expiration).
class StorySnapshot {
  final String type; // image | video | text
  final String? url;
  final String? caption;
  final String? backgroundColor;

  const StorySnapshot({
    required this.type,
    this.url,
    this.caption,
    this.backgroundColor,
  });
}
