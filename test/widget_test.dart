import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titepo_app/main.dart';
import 'package:titepo_app/screens/main_navigation.dart';

/// Offline smoke test: flutter_test stubs all HTTP (every request fails), so
/// this also checks the app degrades gracefully without a connection.
/// Live Shopify integration is covered by commerce_test.dart.
void main() {
  testWidgets('Titepo app boots from splash into the main navigation', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const TitepoApp());

    for (var i = 0; i < 30 && find.byType(MainNavigation).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.byType(MainNavigation), findsOneWidget);
    expect(find.text('Gift Bags'), findsOneWidget);

    // Switch through every tab to make sure each screen builds.
    for (final label in ['Shop', 'Gift Bags', 'Cart', 'Account', 'Home']) {
      await tester.tap(find.text(label).last);
      await tester.pump(const Duration(milliseconds: 300));
      if (label == 'Cart') expect(find.text('Your cart is empty'), findsOneWidget);
      if (label == 'Account') expect(find.text('Sign in to titepo.com'), findsOneWidget);
    }

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  });
}
