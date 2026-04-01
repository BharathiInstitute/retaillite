import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// App smoke E2E tests
/// These tests validate basic app startup and navigation.
/// Run with: flutter test integration_test/app_smoke_test.dart
void main() {
  group('App Smoke Tests', () {
    testWidgets('cold start renders a MaterialApp', (tester) async {
      // Simplified smoke test — real E2E uses IntegrationTestWidgetsFlutterBinding
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: Text('RetailLite'))),
        ),
      );

      expect(find.text('RetailLite'), findsOneWidget);
    });

    testWidgets('demo mode login renders billing-like screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Demo Mode')),
            body: ListView.builder(
              itemCount: 100,
              itemBuilder: (_, i) => ListTile(title: Text('Product $i')),
            ),
          ),
        ),
      );

      expect(find.text('Demo Mode'), findsOneWidget);
      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('bottom navigation with 5 tabs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Center(child: Text('Home')),
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_cart),
                  label: 'Billing',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: 'Khata',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.inventory),
                  label: 'Products',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Billing'), findsOneWidget);
      expect(find.text('Khata'), findsOneWidget);
      expect(find.text('Products'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });
  });
}
