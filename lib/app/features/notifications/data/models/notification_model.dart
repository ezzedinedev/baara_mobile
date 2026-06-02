import '../../domain/entities/notification.dart';

class NotificationModel extends AppNotification {
  const NotificationModel({
    required super.id,
    required super.title,
    required super.body,
    required super.category,
    required super.createdAt,
    required super.isRead,
    super.targetType,
    super.targetId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['data']?['title'] ?? json['title'] ?? '',
      body: json['data']?['body'] ?? json['body'] ?? '',
      category: json['data']?['category'] ?? json['category'] ?? 'default',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      isRead: json['read_at'] != null || json['is_read'] == true,
      targetType: json['data']?['notifiable_type']?.toString().toLowerCase(),
      targetId: json['data']?['notifiable_id']?.toString(),
    );
  }
}
