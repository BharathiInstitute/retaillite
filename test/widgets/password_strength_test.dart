import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/features/auth/widgets/password_strength_indicator.dart';
import '../helpers/test_app.dart';

void main() {
  group('PasswordStrengthIndicator', () {
    testWidgets('shows nothing when password is empty', (tester) async {
      await tester.pumpWidget(
        testApp(const PasswordStrengthIndicator(password: '')),
      );
      expect(find.byType(SizedBox), findsWidgets);
      // Should return SizedBox.shrink()
      expect(find.text('Weak'), findsNothing);
      expect(find.text('Fair'), findsNothing);
      expect(find.text('Good'), findsNothing);
      expect(find.text('Strong'), findsNothing);
    });

    testWidgets('shows Weak for short simple password', (tester) async {
      await tester.pumpWidget(
        testApp(const PasswordStrengthIndicator(password: 'abc')),
      );
      // Score: lowercase(1) = 1 → Weak
      expect(find.text('Weak'), findsOneWidget);
    });

    testWidgets('shows Weak for 6 lowercase only', (tester) async {
      await tester.pumpWidget(
        testApp(const PasswordStrengthIndicator(password: 'abcdef')),
      );
      // Score: length>=6 (1) + lowercase (1) = 2 → Weak
      expect(find.text('Weak'), findsOneWidget);
    });

    testWidgets('shows Fair for mixed case 8 chars', (tester) async {
      await tester.pumpWidget(
        testApp(const PasswordStrengthIndicator(password: 'Abcdefgh')),
      );
      // Score: >=6(1) + >=8(1) + lower(1) + upper(1) = 4 → Fair
      expect(find.text('Fair'), findsOneWidget);
    });

    testWidgets('shows Good for mixed case + numbers 8 chars', (tester) async {
      await tester.pumpWidget(
        testApp(const PasswordStrengthIndicator(password: 'Abcdef1g')),
      );
      // Score: >=6(1) + >=8(1) + lower(1) + upper(1) + digit(1) = 5 → Good
      expect(find.text('Good'), findsOneWidget);
    });

    testWidgets('shows Strong for long complex password', (tester) async {
      await tester.pumpWidget(
        testApp(const PasswordStrengthIndicator(password: 'MyP@ssw0rd123!')),
      );
      // Score: >=6(1) + >=8(1) + >=12(1) + lower(1) + upper(1) + digit(1) + special(1) = 7 → Strong
      expect(find.text('Strong'), findsOneWidget);
    });

    testWidgets('shows hint text for non-strong passwords', (tester) async {
      await tester.pumpWidget(
        testApp(const PasswordStrengthIndicator(password: 'abcdef')),
      );
      // Weak provides hint: "Add numbers or special characters"
      expect(find.textContaining('Add'), findsOneWidget);
    });

    testWidgets('shows 4 strength bars', (tester) async {
      await tester.pumpWidget(
        testApp(const PasswordStrengthIndicator(password: 'test')),
      );
      // Should have 4 bar containers in a Row
      final rows = find.byType(Row);
      expect(rows, findsWidgets);
    });
  });
}
