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
    return ConversationModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['company_name'] ?? json['name'] ?? '',
      lastMessage: json['last_message'] ?? json['preview'] ?? '',
      lastMessageTime: _parseTime(json['last_message_time'] ?? json['updated_at']),
      unreadCount: json['unread_count'] ?? json['unread'] ?? 0,
      isOnline: json['is_online'] ?? json['online'] ?? false,
      avatar: json['avatar'] ?? json['logo'],
      type: json['type'] ?? 'company',
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
    return MessageModel(
      id: json['id']?.toString() ?? '',
      text: json['text'] ?? json['message'] ?? '',
      sentAt: _parseTime(json['sent_at'] ?? json['created_at']),
      isMine: isMine,
      status: json['status'] ?? 'sent',
      type: json['type'] ?? 'text',
      attachments: json['attachments'] != null
          ? (json['attachments'] as List)
              .map((e) => MessageAttachment.fromJson(e))
              .toList()
          : null,
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