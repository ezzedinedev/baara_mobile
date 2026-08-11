import 'package:baara/app/core/constants/api_constants.dart';
import '../../domain/entities/message.dart';

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.text,
    required super.sentAt,
    required super.isMine,
    required super.senderName,
    super.messageType = 'text',
    super.attachmentUrl,
    super.fileName,
    super.fileSize,
    super.replyToStoryId,
    super.storySnapshot,
    super.readAt,
    super.reactionsSummary,
    super.myEmoji,
    super.meta,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>?;
    final firstName = sender?['first_name'] as String? ?? '';
    final lastName = sender?['last_name'] as String? ?? '';
    return MessageModel(
      id: json['id']?.toString() ?? '',
      text: json['content'] ?? json['text'] ?? '',
      sentAt: DateTime.tryParse(json['sent_at']?.toString() ??
              json['created_at']?.toString() ??
              '') ??
          DateTime.now(),
      isMine: json['is_mine'] == true,
      senderName: '$firstName $lastName'.trim(),
      messageType: json['message_type']?.toString() ?? 'text',
      attachmentUrl:
          ApiConstants.resolveMediaUrl(json['attachment_url']?.toString()),
      fileName: json['file_name']?.toString(),
      fileSize: int.tryParse(json['file_size']?.toString() ?? ''),
      replyToStoryId: json['reply_to_story_id']?.toString(),
      storySnapshot: _snapshot(json['story_snapshot']),
      readAt: DateTime.tryParse(json['read_at']?.toString() ?? ''),
      reactionsSummary: _reactions(json['reactions_summary']),
      myEmoji: (json['my_emoji'] as String?)?.isEmpty == true
          ? null
          : json['my_emoji'] as String?,
      meta: _meta(json['meta_json']),
    );
  }

  static MessageMeta? _meta(dynamic raw) {
    if (raw is! Map) return null;
    final type = raw['type']?.toString();
    if (type == null || type.isEmpty) return null;

    final actions = (raw['actions'] is List)
        ? (raw['actions'] as List)
            .map((a) => MessageAction.fromWire(a.toString()))
            .whereType<MessageAction>()
            .toList()
        : const <MessageAction>[];

    return MessageMeta(
      type: type,
      interviewId: raw['interview_id']?.toString(),
      proposalId: raw['proposal_id']?.toString(),
      proposedDate: DateTime.tryParse(raw['proposed_date']?.toString() ?? ''),
      actions: actions,
    );
  }

  static Map<String, int> _reactions(dynamic raw) {
    if (raw is! Map) return const <String, int>{};
    final result = <String, int>{};
    raw.forEach((key, value) {
      final count = (value is num)
          ? value.toInt()
          : int.tryParse(value?.toString() ?? '') ?? 0;
      if (count > 0) result[key.toString()] = count;
    });
    return result;
  }

  static StorySnapshot? _snapshot(dynamic raw) {
    if (raw is! Map) return null;
    return StorySnapshot(
      type: raw['type']?.toString() ?? 'text',
      url: ApiConstants.resolveMediaUrl(raw['url']?.toString()),
      caption: raw['caption']?.toString(),
      backgroundColor: raw['background_color']?.toString(),
    );
  }
}
