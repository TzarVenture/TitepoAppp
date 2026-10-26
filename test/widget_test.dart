import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titepo_app/main.dart';

class TestHttpOverrides extends HttpOverrides {}

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  testWidgets('Titepo App Smoke Test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const TitepoApp());
    // Advance timers so initial splash load and network timeouts complete
    await tester.pump(const Duration(seconds: 12));
    expect(find.byType(TitepoApp), findsOneWidget);
  });
}
