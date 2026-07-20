/// Une action proposée par un message structuré (`meta_json.actions`).
///
/// Les libellés du backend sont ceux du web : `accept_new_date` / `propose_other`
/// répondent à une contre-proposition de date, et se traduisent côté API
/// candidat par les actions `accept` / `reschedule` de `POST /interviews/{id}/respond`.
enum MessageAction {
  accept,
  decline,
  reschedule,
  acceptNewDate,
  proposeOther,
  negotiate,
  refuse;

  static MessageAction? fromWire(String raw) => switch (raw) {
        'accept' => MessageAction.accept,
        'decline' => MessageAction.decline,
        'reschedule' => MessageAction.reschedule,
        'accept_new_date' => MessageAction.acceptNewDate,
        'propose_other' => MessageAction.proposeOther,
        'negotiate' => MessageAction.negotiate,
        'refuse' => MessageAction.refuse,
        _ => null,
      };

  /// L'action demande-t-elle une date au candidat avant d'être envoyée ?
  bool get needsDate =>
      this == MessageAction.reschedule || this == MessageAction.proposeOther;
}

/// Charge utile structurée d'un message (`meta_json`). Portée par les messages
/// que le backend émet lors d'une invitation d'entretien, d'un report ou d'une
/// offre d'emploi. C'est elle qui fait apparaître les boutons sous la bulle.
class MessageMeta {
  /// `interview_invite` | `reschedule_request` | `reschedule_accepted` | `job_proposal`
  final String type;
  final String? interviewId;
  final String? proposalId;
  final DateTime? proposedDate;
  final List<MessageAction> actions;

  const MessageMeta({
    required this.type,
    this.interviewId,
    this.proposalId,
    this.proposedDate,
    this.actions = const <MessageAction>[],
  });

  bool get isInterview =>
      type == 'interview_invite' || type == 'reschedule_request';

  bool get isProposal => type == 'job_proposal';

  /// L'identifiant de l'entité visée par les actions.
  String? get targetId => isProposal ? proposalId : interviewId;
}

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

  /// Charge structurée (`meta_json`) : boutons d'action sous la bulle.
  final MessageMeta? meta;

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
    this.meta,
  });

  bool get isStoryReply => replyToStoryId != null || storySnapshot != null;

  /// Boutons à afficher : uniquement sur les messages reçus, et seulement si le
  /// backend a joint des actions (il les retire dès que l'entretien est clos).
  bool get hasActions => !isMine && (meta?.actions.isNotEmpty ?? false);

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
      meta: meta,
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
