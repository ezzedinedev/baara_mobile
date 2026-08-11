import 'package:baara/app/core/network/api_provider.dart';
import 'package:baara/app/core/network/api_response.dart';
import 'package:baara/app/core/constants/api_constants.dart';
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
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de charger vos notifications.');

    final data = ApiResponse.dataMap(response);
    // Le backend renvoie la liste sous `items` (pas `data`).
    final list = ApiResponse.extractList(data);
    return (
      items: list.map((json) => NotificationModel.fromJson(json)).toList(),
      hasMore: data['has_more'] == true,
      unreadCount: (data['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<void> markAsRead(String id) async {
    final response =
        await _apiProvider.postJson(ApiConstants.notificationRead(id), {});
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de marquer cette notification comme lue.');
  }

  @override
  Future<void> markAllAsRead() async {
    final response =
        await _apiProvider.postJson(ApiConstants.notificationsReadAll, {});
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de tout marquer comme lu.');
  }

  @override
  Future<void> delete(String id) async {
    final response =
        await _apiProvider.deleteJson(ApiConstants.notification(id));
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de supprimer cette notification.');
  }
}
