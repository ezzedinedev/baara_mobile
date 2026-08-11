import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:baara/app/features/home/presentation/controllers/home_controller.dart';

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

}
