import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:baara/app/core/widgets/common/month_year_picker_sheet.dart';

void main() {
  testWidgets('le sélecteur mois / année s\'ouvre et renvoie la date',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);

    String? result;
    await tester.pumpWidget(GetMaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showMonthYearPickerSheet(
                context: context,
                title: 'Fin',
                initial: '2023',
                allowPresent: true,
              );
            },
            child: const Text('ouvrir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Valider'), findsOneWidget);

    await tester.tap(find.text('mars'));
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    expect(result, 'mars 2023');
  });
}
