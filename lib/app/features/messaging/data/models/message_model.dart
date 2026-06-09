import '../../domain/entities/message.dart';

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.text,
    required super.sentAt,
    required super.isMine,
    required super.senderName,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>?;
    final firstName = sender?['first_name'] as String? ?? '';
    final lastName = sender?['last_name'] as String? ?? '';
    return MessageModel(
      id: json['id']?.toString() ?? '',
      text: json['content'] ?? json['text'] ?? '',
      sentAt: DateTime.tryParse(json['sent_at']?.toString() ?? json['created_at']?.toString() ?? '') ?? DateTime.now(),
      isMine: json['is_mine'] == true,
      senderName: '$firstName $lastName'.trim(),
    );
  }
}
