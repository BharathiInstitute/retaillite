/// Tests for SettingsWebScreen — controller initialization safety
///
/// Regression test for LateInitializationError on _receiptFooterController.
/// Ensures all TextEditingControllers are eagerly initialized so the screen
/// can build even before initState completes (e.g. during GoRouter transitions).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/features/settings/screens/settings_web_screen.dart';
import 'package:retaillite/models/user_model.dart';
import '../helpers/test_factories.dart';

void main() {
  group('SettingsWebScreen controller initialization', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Widget buildScreen({UserModel? user, String initialTab = 'general'}) {
      return ProviderScope(
        overrides: [currentUserProvider.overrideWithValue(user ?? makeUser())],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1366,
              height: 768,
              child: SettingsWebScreen(initialTab: initialTab),
            ),
          ),
        ),
      );
    }

    testWidgets('builds without LateInitializationError', (tester) async {
      await tester.pumpWidget(
        buildScreen(
          user: makeUser(ownerName: 'Owner', phone: '9999999999'),
        ),
      );

      // Pump past the ThemeSettingsNotifier cloud-load timer (3 s)
      await tester.pump(const Duration(seconds: 4));

      // If controllers were `late`, pumpWidget itself would throw
      // LateInitializationError. With eager init, it renders fine.
      expect(find.byType(SettingsWebScreen), findsOneWidget);
    });

    testWidgets('builds with null user without crash', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [currentUserProvider.overrideWithValue(null)],
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 1366,
                height: 768,
                child: SettingsWebScreen(),
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 4));
      expect(find.byType(SettingsWebScreen), findsOneWidget);
    });

    testWidgets('builds with initialTab=hardware', (tester) async {
      await tester.pumpWidget(buildScreen(initialTab: 'hardware'));

      await tester.pump(const Duration(seconds: 4));
      expect(find.byType(SettingsWebScreen), findsOneWidget);
    });
  });
}
