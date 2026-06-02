import 'package:opportune_bf/app/core/network/api_provider.dart';
import 'package:opportune_bf/app/core/constants/api_constants.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/i_notification_repository.dart';
import '../models/notification_model.dart';

class NotificationRepositoryImpl implements INotificationRepository {
  final ApiProvider _apiProvider;

  NotificationRepositoryImpl({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  @override
  Future<NotificationsPage> getNotifications({int page = 1}) async {
    final response =
        await _apiProvider.getJson('${ApiConstants.notifications}?page=$page');
    if (response['success'] == true && response['data'] is Map) {
      final data = response['data'] as Map<String, dynamic>;
      // Le backend renvoie la liste sous `items` (pas `data`).
      final List<dynamic> list = (data['items'] as List?) ?? const [];
      return (
        items: list.map((json) => NotificationModel.fromJson(json)).toList(),
        hasMore: data['has_more'] == true,
        unreadCount: (data['unread_count'] as num?)?.toInt() ?? 0,
      );
    }
    return (items: <AppNotification>[], hasMore: false, unreadCount: 0);
  }

  @override
  Future<void> markAsRead(String id) async {
    await _apiProvider.postJson(ApiConstants.notificationRead(id), {});
  }

  @override
  Future<void> markAllAsRead() async {
    await _apiProvider.postJson(ApiConstants.notificationsReadAll, {});
  }
}
