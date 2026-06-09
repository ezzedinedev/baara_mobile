import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:opportune_bf/app/features/home/presentation/controllers/home_controller.dart';

void main() {
  late HomeController controller;

  setUp(() {
    Get.testMode = true;
    controller = HomeController();
    Get.put(controller);
  });

  tearDown(() {
    Get.reset();
  });

  test('changeTab updates currentTabIndex', () {
    expect(controller.currentTabIndex.value, 0);

    controller.changeTab(1);
    expect(controller.currentTabIndex.value, 1);

    controller.changeTab(4);
    expect(controller.currentTabIndex.value, 4);
  });

  test('activeConversationId can be set for FCM compatibility', () {
    controller.activeConversationId.value = 'conv-42';
    expect(controller.activeConversationId.value, 'conv-42');
  });
}
