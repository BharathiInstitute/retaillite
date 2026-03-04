import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/widgets/splash_screen.dart';

void main() {
  group('SplashScreen', () {
    testWidgets('renders app name', (tester) async {
      await tester.pumpWidget(const SplashScreen());
      expect(find.text('RetailLite'), findsOneWidget);
    });

    testWidgets('renders Hindi tagline', (tester) async {
      await tester.pumpWidget(const SplashScreen());
      expect(
        find.text('भारत का सबसे आसान बिलिंग ऐप'),
        findsOneWidget,
      );
    });

    testWidgets('shows point_of_sale icon', (tester) async {
      await tester.pumpWidget(const SplashScreen());
      expect(find.byIcon(Icons.point_of_sale), findsOneWidget);
    });

    testWidgets('shows message text when provided', (tester) async {
      await tester.pumpWidget(
        const SplashScreen(message: 'Loading data...'),
      );
      expect(find.text('Loading data...'), findsOneWidget);
    });

    testWidgets('shows error state with retry button', (tester) async {
      await tester.pumpWidget(
        SplashScreen(
          showError: true,
          errorMessage: 'Connection failed',
          onRetry: () {},
        ),
      );
      expect(find.text('Connection failed'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry button fires callback', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        SplashScreen(
          showError: true,
          errorMessage: 'Error',
          onRetry: () => retried = true,
        ),
      );
      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });

    testWidgets('does not show error state by default', (tester) async {
      await tester.pumpWidget(const SplashScreen());
      expect(find.text('Retry'), findsNothing);
    });
  });
}
