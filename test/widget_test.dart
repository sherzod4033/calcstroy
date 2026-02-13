import 'package:flutter_test/flutter_test.dart';
import 'package:buildcalc/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BuildCalcApp());

    // Verify the home screen renders with the title
    expect(find.text('Главная'), findsOneWidget);

    // Verify bottom nav has expected items
    expect(find.text('История'), findsOneWidget);
    expect(find.text('Настройки'), findsOneWidget);
  });
}
