import 'package:get/get.dart';
import 'package:opportune_bf/routes/app_routes.dart';
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

  /// Rafraîchit UNIQUEMENT le compteur non-lu (pour le badge de la cloche),
  /// sans toucher à la liste affichée — évite de casser le scroll/pagination
  /// en cours lors du polling périodique des badges.
  Future<void> refreshUnreadCount() async {
    try {
      final result = await _repository.getNotifications(page: 1);
      unreadCount.value = result.unreadCount;
    } catch (_) {}
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

  /// Tap sur une notification : marque lue puis deep-link selon
  /// `target.target_type`. Reste sans effet si la cible est absente/inconnue.
  ///
  /// Mapping :
  /// - `conversation` → fil de discussion (`AppRoutes.conversation`).
  /// - `profile`      → profil communauté (`AppRoutes.communityProfile`).
  /// - `connection`   → écran connexions (`AppRoutes.communityConnections`).
  /// - `post` / `mention_*` / `story` → fil communauté (best effort, faute
  ///   d'écran de détail de post / d'entrée directe story).
  /// - autre/null     → aucune navigation.
  Future<void> openNotification(AppNotification notification) async {
    await markAsRead(notification.id);

    final target = notification.target;
    if (target == null || !target.hasDestination) return;
    final id = target.targetId;

    switch (target.targetType) {
      case 'conversation':
        if (id != null && id.isNotEmpty) {
          Get.toNamed(AppRoutes.conversation.replaceFirst(':id', id));
        }
        break;
      case 'profile':
        if (id != null && id.isNotEmpty) {
          Get.toNamed(AppRoutes.communityProfile.replaceFirst(':id', id));
        }
        break;
      case 'connection':
        Get.toNamed(AppRoutes.communityConnections);
        break;
      case 'post':
      case 'story':
        // Pas d'écran de détail de post ni d'entrée directe « story » par id :
        // on retombe sur le fil communauté (meilleur effort).
        Get.toNamed(AppRoutes.community);
        break;
      default:
        // application / training / inconnu : pas de deep-link dédié ici.
        break;
    }
  }

  /// Supprime une notification (retrait optimiste + rollback si l'appel échoue).
  Future<void> delete(String id) async {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;
    final removed = notifications[index];
    final wasUnread = !removed.isRead;
    notifications.removeAt(index);
    if (wasUnread && unreadCount.value > 0) unreadCount.value--;
    try {
      await _repository.delete(id);
    } catch (_) {
      notifications.insert(index, removed);
      if (wasUnread) unreadCount.value++;
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
