import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/theme/adaptive_layout.dart';

void main() {
  group('AdaptiveLayout', () {
    testWidgets('shows mobile layout at narrow width', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveLayout(
            mobile: (_) => const Text('Mobile'),
            tablet: (_) => const Text('Tablet'),
            desktop: (_) => const Text('Desktop'),
          ),
        ),
      );
      expect(find.text('Mobile'), findsOneWidget);
      expect(find.text('Tablet'), findsNothing);
    });

    testWidgets('shows tablet layout at medium width', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveLayout(
            mobile: (_) => const Text('Mobile'),
            tablet: (_) => const Text('Tablet'),
            desktop: (_) => const Text('Desktop'),
          ),
        ),
      );
      expect(find.text('Tablet'), findsOneWidget);
    });

    testWidgets('shows desktop layout at wide width', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveLayout(
            mobile: (_) => const Text('Mobile'),
            tablet: (_) => const Text('Tablet'),
            desktop: (_) => const Text('Desktop'),
          ),
        ),
      );
      expect(find.text('Desktop'), findsOneWidget);
    });

    testWidgets('falls back to mobile when tablet not provided', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveLayout(
            mobile: (_) => const Text('Mobile'),
          ),
        ),
      );
      expect(find.text('Mobile'), findsOneWidget);
    });
  });

  group('AdaptiveLayoutStatic', () {
    testWidgets('shows mobile widget at narrow width', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: AdaptiveLayoutStatic(
            mobile: Text('Static Mobile'),
            tablet: Text('Static Tablet'),
          ),
        ),
      );
      expect(find.text('Static Mobile'), findsOneWidget);
    });

    testWidgets('falls back to mobile when tablet and desktop null', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: AdaptiveLayoutStatic(
            mobile: Text('Only Mobile'),
          ),
        ),
      );
      expect(find.text('Only Mobile'), findsOneWidget);
    });
  });
}
