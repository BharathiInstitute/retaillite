import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/shared/widgets/upgrade_prompt_modal.dart';

void main() {
  group('UpgradeTrigger', () {
    test('has 4 values', () {
      expect(UpgradeTrigger.values.length, 4);
    });

    test('contains expected triggers', () {
      expect(UpgradeTrigger.values, contains(UpgradeTrigger.productLimit));
      expect(UpgradeTrigger.values, contains(UpgradeTrigger.billLimit));
      expect(UpgradeTrigger.values, contains(UpgradeTrigger.customerLimit));
      expect(UpgradeTrigger.values, contains(UpgradeTrigger.featureGated));
    });
  });

  group('UpgradePromptModal.show', () {
    testWidgets('shows dialog with product limit message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => UpgradePromptModal.show(
                context,
                trigger: UpgradeTrigger.productLimit,
              ),
              child: const Text('Trigger'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      expect(find.text('Upgrade Your Plan'), findsOneWidget);
      expect(find.textContaining('product limit'), findsOneWidget);
    });

    testWidgets('shows dialog with bill limit message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => UpgradePromptModal.show(
                context,
                trigger: UpgradeTrigger.billLimit,
              ),
              child: const Text('Trigger'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      expect(find.textContaining('bill limit'), findsOneWidget);
    });

    testWidgets('shows dialog with customer limit message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => UpgradePromptModal.show(
                context,
                trigger: UpgradeTrigger.customerLimit,
              ),
              child: const Text('Trigger'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      expect(find.textContaining('customer limit'), findsOneWidget);
    });

    testWidgets('shows Later and View Plans buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => UpgradePromptModal.show(
                context,
                trigger: UpgradeTrigger.featureGated,
              ),
              child: const Text('Trigger'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      expect(find.text('Later'), findsOneWidget);
      expect(find.text('View Plans'), findsOneWidget);
    });

    testWidgets('Later button dismisses dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => UpgradePromptModal.show(
                context,
                trigger: UpgradeTrigger.productLimit,
              ),
              child: const Text('Trigger'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();
      expect(find.text('Upgrade Your Plan'), findsOneWidget);

      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();
      expect(find.text('Upgrade Your Plan'), findsNothing);
    });

    testWidgets('shows star icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => UpgradePromptModal.show(
                context,
                trigger: UpgradeTrigger.featureGated,
              ),
              child: const Text('Trigger'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });
}
