import 'package:flutter_test/flutter_test.dart';
import 'package:chargesure/main.dart';

void main() {
  testWidgets('ChargeSure smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ChargeSureApp());
    expect(find.byType(ChargeSureApp), findsOneWidget);
  });
}
