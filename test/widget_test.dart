import 'package:flutter_test/flutter_test.dart';
import 'package:absensismkn8medan/main.dart';

void main() {
  testWidgets('App loads hello world', (WidgetTester tester) async {
    await tester.pumpWidget(const AbsensiApp());

    expect(find.text('Hello World'), findsOneWidget);
  });
}