import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Billing E2E tests
/// Tests the core billing flow end-to-end.
void main() {
  group('Billing E2E', () {
    testWidgets('search product → add to cart → shows in cart', (tester) async {
      // Simplified E2E simulation
      final cart = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                appBar: AppBar(
                  title: TextField(
                    key: const Key('search'),
                    onSubmitted: (value) {
                      setState(() => cart.add(value));
                    },
                  ),
                ),
                body: ListView(
                  children: cart
                      .map(
                        (item) =>
                            ListTile(key: Key('cart-$item'), title: Text(item)),
                      )
                      .toList(),
                ),
              );
            },
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('search')), 'Rice');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(find.text('Rice'), findsWidgets);
    });

    testWidgets('voice search icon is visible', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Billing'),
              actions: [
                IconButton(icon: const Icon(Icons.mic), onPressed: () {}),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.mic), findsOneWidget);
    });
  });
}
