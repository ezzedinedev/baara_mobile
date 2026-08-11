import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:baara/app/features/streak/presentation/controllers/streak_controller.dart';
import 'package:baara/app/features/streak/presentation/pages/streak_screen.dart';

void main() {
  testWidgets('StreakScreen builds without throwing', (tester) async {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
    Get.put(StreakController());

    await tester.pumpWidget(
      GetMaterialApp(home: const StreakScreen()),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(StreakScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    Get.reset();
  });
}
