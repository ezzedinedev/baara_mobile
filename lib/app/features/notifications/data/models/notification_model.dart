import '../../domain/entities/notification.dart';

class NotificationModel extends AppNotification {
  const NotificationModel({
    required super.id,
    required super.title,
    required super.body,
    required super.category,
    required super.createdAt,
    required super.isRead,
    super.target,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: data['title'] ?? json['title'] ?? '',
      body: data['body'] ?? json['body'] ?? '',
      category: data['category'] ?? json['category'] ?? 'default',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      isRead: json['read_at'] != null || json['is_read'] == true,
      target: _parseTarget(json, data),
    );
  }

  /// Parse le bloc `target` (nouveau contrat). Tolérant : accepte le bloc à la
  /// racine ou dans `data`, et retombe sur l'ancien schéma `notifiable_*` si
  /// `target` est absent.
  static NotificationTarget? _parseTarget(
    Map<String, dynamic> json,
    Map<String, dynamic> data,
  ) {
    final raw = (json['target'] is Map<String, dynamic>)
        ? json['target'] as Map<String, dynamic>
        : (data['target'] is Map<String, dynamic>
            ? data['target'] as Map<String, dynamic>
            : null);

    if (raw != null) {
      return NotificationTarget(
        type: raw['type']?.toString(),
        targetType: raw['target_type']?.toString().toLowerCase(),
        targetId: raw['target_id']?.toString(),
      );
    }

    // Fallback : ancien schéma (rétro-compat, reste tolérant).
    final legacyType = data['notifiable_type']?.toString().toLowerCase();
    final legacyId = data['notifiable_id']?.toString();
    if (legacyType == null && legacyId == null) return null;
    return NotificationTarget(targetType: legacyType, targetId: legacyId);
  }
}
