import 'package:get/get.dart';
import 'package:jobaway/app/core/network/api_provider.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/repositories/i_notification_repository.dart';
import '../controllers/notifications_controller.dart';

class NotificationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<INotificationRepository>(
      () => NotificationRepositoryImpl(apiProvider: Get.find<ApiProvider>()),
    );
    Get.lazyPut(
        () => NotificationsController(Get.find<INotificationRepository>()));
  }
}
