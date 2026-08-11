import 'package:get/get.dart';
import 'package:baara/app/core/network/api_provider.dart';
import 'package:baara/app/core/services/onboarding_service.dart';
import 'package:baara/app/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:baara/app/features/profile/domain/repositories/i_profile_repository.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<IProfileRepository>()) {
      Get.lazyPut<IProfileRepository>(
        () => ProfileRepositoryImpl(apiProvider: Get.find<ApiProvider>()),
      );
    }
    Get.lazyPut(
      () => OnboardingController(
        Get.find<OnboardingService>(),
        Get.find<IProfileRepository>(),
      ),
    );
  }
}
