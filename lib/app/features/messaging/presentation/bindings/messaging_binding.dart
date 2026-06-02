import 'package:get/get.dart';
import 'package:opportune_bf/app/core/network/api_provider.dart';
import '../../data/repositories/messaging_repository_impl.dart';
import '../../domain/repositories/i_messaging_repository.dart';
import '../controllers/messages_controller.dart';

class MessagingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<IMessagingRepository>(
      () => MessagingRepositoryImpl(apiProvider: Get.find<ApiProvider>()),
    );
    Get.lazyPut(() => MessagesController(Get.find<IMessagingRepository>()));
  }
}
