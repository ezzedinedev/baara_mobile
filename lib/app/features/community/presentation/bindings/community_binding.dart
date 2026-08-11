import 'package:get/get.dart';
import 'package:baara/app/core/network/api_provider.dart';
import '../../data/repositories/community_repository_impl.dart';
import '../../domain/repositories/i_community_repository.dart';
import '../controllers/community_controller.dart';
import '../controllers/story_controller.dart';

class CommunityBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ICommunityRepository>()) {
      Get.lazyPut<ICommunityRepository>(
        () => CommunityRepositoryImpl(apiProvider: Get.find<ApiProvider>()),
      );
    }
    if (!Get.isRegistered<CommunityController>()) {
      Get.lazyPut(() => CommunityController(Get.find<ICommunityRepository>()));
    }
    if (!Get.isRegistered<StoryController>()) {
      Get.lazyPut(
        () => StoryController(Get.find<ICommunityRepository>()),
        fenix: true,
      );
    }
  }
}
