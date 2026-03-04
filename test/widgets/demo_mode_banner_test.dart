import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/features/auth/widgets/demo_mode_banner.dart';

void main() {
  Widget buildBanner({required bool isDemoMode}) {
    return ProviderScope(
      overrides: [
        isDemoModeProvider.overrideWithValue(isDemoMode),
      ],
      child: const MaterialApp(
        home: Scaffold(body: DemoModeBanner()),
      ),
    );
  }

  group('DemoModeBanner', () {
    testWidgets('shows banner when demo mode is active', (tester) async {
      await tester.pumpWidget(buildBanner(isDemoMode: true));
      expect(find.text('Demo Mode - Register to save your data'),
          findsOneWidget);
      expect(find.byIcon(Icons.science_outlined), findsOneWidget);
    });

    testWidgets('shows Register button in demo mode', (tester) async {
      await tester.pumpWidget(buildBanner(isDemoMode: true));
      expect(find.text('Register'), findsOneWidget);
    });

    testWidgets('shows close icon in demo mode', (tester) async {
      await tester.pumpWidget(buildBanner(isDemoMode: true));
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('hidden when demo mode is off', (tester) async {
      await tester.pumpWidget(buildBanner(isDemoMode: false));
      expect(find.text('Demo Mode - Register to save your data'),
          findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });
  });
}
