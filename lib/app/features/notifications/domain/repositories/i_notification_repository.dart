import '../entities/notification.dart';

/// Page de notifications + métadonnées de pagination (cf. backend
/// NotificationApiController@index : `{items, unread_count, total, has_more}`).
typedef NotificationsPage = ({
  List<AppNotification> items,
  bool hasMore,
  int unreadCount,
});

abstract class INotificationRepository {
  Future<NotificationsPage> getNotifications({int page = 1});
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();

  /// Supprime une notification (DELETE /notifications/{id}).
  Future<void> delete(String id);
}
