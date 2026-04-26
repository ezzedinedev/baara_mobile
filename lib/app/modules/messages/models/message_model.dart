class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.isOnline,
    required this.avatar,
    required this.type,
  });

  final String id;
  final String title;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final String? avatar;
  final String type; // 'recruiter', 'company', 'system'

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    // Backend Laravel : id, employer_profile_id, candidate_profile_id,
    // last_message_at, unread_employer, unread_candidate, latestMessage{...},
    // candidate{user{...}}, employer{...}.
    final latest = json['latestMessage'] ?? json['latest_message'];
    final lastMsgText = latest is Map
        ? (latest['content'] ??
                latest['message'] ??
                latest['text'] ??
                '')
            .toString()
        : (json['last_message'] ?? json['preview'] ?? '').toString();

    final employer = json['employer'];
    final candidate = json['candidate'];
    final candidateUser =
        candidate is Map ? candidate['user'] : null;

    String resolvedTitle = '';
    String resolvedType = json['type']?.toString() ?? '';

    // L'app candidat affiche le recruteur en face — privilegier l'employeur.
    if (employer is Map) {
      resolvedTitle = (employer['company_name'] ??
              employer['name'] ??
              employer['display_name'] ??
              '')
          .toString();
      if (resolvedType.isEmpty) resolvedType = 'recruiter';
    }
    if (resolvedTitle.isEmpty && candidateUser is Map) {
      final first = (candidateUser['first_name'] ?? '').toString().trim();
      final last = (candidateUser['last_name'] ?? '').toString().trim();
      resolvedTitle = '$first $last'.trim();
      if (resolvedTitle.isEmpty) {
        resolvedTitle = (candidateUser['name'] ?? '').toString();
      }
    }
    if (resolvedTitle.isEmpty) {
      resolvedTitle = (json['title'] ??
              json['company_name'] ??
              json['name'] ??
              'Conversation')
          .toString();
    }
    if (resolvedType.isEmpty) resolvedType = 'company';

    final unread = json['unread_candidate'] ??
        json['unread_count'] ??
        json['unread_employer'] ??
        json['unread'] ??
        0;

    final time = json['last_message_at'] ??
        json['last_message_time'] ??
        (latest is Map ? latest['sent_at'] : null) ??
        json['updated_at'];

    return ConversationModel(
      id: json['id']?.toString() ?? '',
      title: resolvedTitle,
      lastMessage: lastMsgText,
      lastMessageTime: _parseTime(time),
      unreadCount: unread is num ? unread.toInt() : 0,
      isOnline: json['is_online'] ?? json['online'] ?? false,
      avatar: (employer is Map ? employer['logo_url'] : null) ??
          (candidateUser is Map ? candidateUser['avatar_url'] : null) ??
          json['avatar'] ??
          json['logo'],
      type: resolvedType,
    );
  }

  static DateTime _parseTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  String get timeLabel {
    final now = DateTime.now();
    final diff = now.difference(lastMessageTime);

    if (diff.inMinutes < 1) return 'Maintenant';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}j';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} sem';
    return '${lastMessageTime.day}/${lastMessageTime.month}';
  }
}

class MessageModel {
  const MessageModel({
    required this.id,
    required this.text,
    required this.sentAt,
    required this.isMine,
    required this.status,
    required this.type,
    this.attachments,
  });

  final String id;
  final String text;
  final DateTime sentAt;
  final bool isMine;
  final String status; // 'sent', 'delivered', 'read'
  final String type; // 'text', 'image', 'file', 'system'
  final List<MessageAttachment>? attachments;

  factory MessageModel.fromJson(Map<String, dynamic> json, {bool isMine = false}) {
    // Backend Laravel : content, message_type, sent_at, is_read, read_at,
    // attachment_url, file_name, file_size, sender_id, sender{user...}.
    final attachmentUrl = json['attachment_url']?.toString();
    final attachments = <MessageAttachment>[];
    if (attachmentUrl != null && attachmentUrl.isNotEmpty) {
      attachments.add(MessageAttachment(
        id: json['id']?.toString() ?? '',
        name: json['file_name']?.toString() ?? 'piece-jointe',
        url: attachmentUrl,
        type: (json['message_type']?.toString() ?? 'file') == 'image'
            ? 'image'
            : 'file',
        size: (json['file_size'] is num)
            ? (json['file_size'] as num).toInt()
            : 0,
      ));
    } else if (json['attachments'] is List) {
      attachments.addAll((json['attachments'] as List)
          .map((e) => MessageAttachment.fromJson(e)));
    }

    return MessageModel(
      id: json['id']?.toString() ?? '',
      text: (json['content'] ?? json['text'] ?? json['message'] ?? '').toString(),
      sentAt: _parseTime(json['sent_at'] ?? json['created_at']),
      isMine: isMine,
      status: (json['is_read'] == true)
          ? 'read'
          : (json['status']?.toString() ?? 'sent'),
      type: (json['message_type'] ?? json['type'] ?? 'text').toString(),
      attachments: attachments.isEmpty ? null : attachments,
    );
  }

  static DateTime _parseTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  String get timeLabel {
    return '${sentAt.hour.toString().padLeft(2, '0')}:${sentAt.minute.toString().padLeft(2, '0')}';
  }
}

class MessageAttachment {
  const MessageAttachment({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.size,
  });

  final String id;
  final String name;
  final String url;
  final String type; // 'image', 'file'
  final int size;

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['file_name'] ?? '',
      url: json['url'] ?? json['file_url'] ?? '',
      type: json['type'] ?? 'file',
      size: json['size'] ?? 0,
    );
  }

  String get sizeLabel {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class ChatSearchQuery {
  const ChatSearchQuery({
    this.keywords,
    this.conversationId,
    this.dateFrom,
    this.dateTo,
  });

  final String? keywords;
  final String? conversationId;
  final DateTime? dateFrom;
  final DateTime? dateTo;
}