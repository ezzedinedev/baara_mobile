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
    return MessageModel(
      id: json['id']?.toString() ?? '',
      text: json['content'] ?? json['text'] ?? '',
      sentAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      isMine: json['is_mine'] == true,
      senderName: json['sender_name'] ?? '',
    );
  }
}
