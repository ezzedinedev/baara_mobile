import 'package:flutter_test/flutter_test.dart';
import 'package:opportune_bf/main.dart';

void main() {
  testWidgets('Affiche le splash OpporTune BF', (WidgetTester tester) async {
    await tester.pumpWidget(const OpportuneBFApp());

    expect(find.text('Votre carrière commence ici'), findsOneWidget);
  });
}
