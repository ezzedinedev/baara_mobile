import 'package:get/get.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/i_notification_repository.dart';

class NotificationsController extends GetxController {
  final INotificationRepository _repository;
  NotificationsController(this._repository);

  final notifications = <AppNotification>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = false.obs;
  final unreadCount = 0.obs;
  int _page = 1;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      isLoading.value = true;
      _page = 1;
      final result = await _repository.getNotifications(page: 1);
      notifications.assignAll(result.items);
      hasMore.value = result.hasMore;
      unreadCount.value = result.unreadCount;
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  /// Charge la page suivante et l'ajoute à la liste (scroll infini).
  Future<void> loadMore() async {
    if (isLoadingMore.value || isLoading.value || !hasMore.value) return;
    try {
      isLoadingMore.value = true;
      final result = await _repository.getNotifications(page: _page + 1);
      _page += 1;
      notifications.addAll(result.items);
      hasMore.value = result.hasMore;
      unreadCount.value = result.unreadCount;
    } catch (_) {
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> markAsRead(String id) async {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index == -1 || notifications[index].isRead) return;

    // Optimiste : la pastille "non lu" disparaît tout de suite, rollback si KO.
    final previous = notifications[index];
    notifications[index] = previous.copyWith(isRead: true);
    if (unreadCount.value > 0) unreadCount.value--;
    try {
      await _repository.markAsRead(id);
    } catch (_) {
      notifications[index] = previous;
      unreadCount.value++;
    }
  }

  Future<void> markAllRead() async {
    if (notifications.every((n) => n.isRead)) return;

    // Optimiste : tout passe en "lu" immédiatement, rollback si l'appel échoue.
    final snapshot = List<AppNotification>.from(notifications);
    final previousUnread = unreadCount.value;
    notifications.assignAll(
      notifications.map((n) => n.copyWith(isRead: true)),
    );
    unreadCount.value = 0;
    try {
      await _repository.markAllAsRead();
    } catch (_) {
      notifications.assignAll(snapshot);
      unreadCount.value = previousUnread;
    }
  }
}
