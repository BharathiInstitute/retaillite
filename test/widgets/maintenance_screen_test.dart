import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/widgets/maintenance_screen.dart';

void main() {
  group('MaintenanceScreen', () {
    testWidgets('renders Under Maintenance text', (tester) async {
      await tester.pumpWidget(const MaintenanceScreen());
      expect(find.text('Under Maintenance'), findsOneWidget);
    });

    testWidgets('renders description text', (tester) async {
      await tester.pumpWidget(const MaintenanceScreen());
      expect(
        find.textContaining('improving your experience'),
        findsOneWidget,
      );
    });

    testWidgets('shows construction icon', (tester) async {
      await tester.pumpWidget(const MaintenanceScreen());
      expect(find.byIcon(Icons.construction_rounded), findsOneWidget);
    });

    testWidgets('shows Try Again button when onRetry provided', (tester) async {
      await tester.pumpWidget(MaintenanceScreen(onRetry: () {}));
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('hides Try Again button when onRetry null', (tester) async {
      await tester.pumpWidget(const MaintenanceScreen());
      expect(find.text('Try Again'), findsNothing);
    });

    testWidgets('onRetry callback fires on tap', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaintenanceScreen(onRetry: () => retried = true),
      );
      await tester.tap(find.text('Try Again'));
      expect(retried, isTrue);
    });

    testWidgets('shows refresh icon in button', (tester) async {
      await tester.pumpWidget(MaintenanceScreen(onRetry: () {}));
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });
}
