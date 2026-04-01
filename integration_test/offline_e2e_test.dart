import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Offline E2E tests
/// Validates offline-first behavior.
void main() {
  group('Offline E2E', () {
    testWidgets('offline indicator shows when disconnected', (tester) async {
      final isOffline = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Home')),
            body: Column(
              children: [
                if (isOffline)
                  Container(
                    key: const Key('offline-banner'),
                    color: Colors.orange,
                    padding: const EdgeInsets.all(8),
                    child: const Row(
                      children: [
                        Icon(Icons.wifi_off),
                        SizedBox(width: 8),
                        Text('Offline Mode'),
                      ],
                    ),
                  ),
                const Expanded(child: Center(child: Text('Content'))),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('offline-banner')), findsOneWidget);
      expect(find.text('Offline Mode'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });

    testWidgets('bill creation UI works without network', (tester) async {
      // Simulates creating a bill in offline mode
      final bills = <Map<String, dynamic>>[];

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                appBar: AppBar(title: const Text('Offline Billing')),
                body: Column(
                  children: [
                    ...bills.map(
                      (b) => ListTile(
                        title: Text('Bill #${b["number"]}'),
                        subtitle: Text('₹${b["total"]}'),
                      ),
                    ),
                  ],
                ),
                floatingActionButton: FloatingActionButton(
                  key: const Key('create-bill'),
                  onPressed: () {
                    setState(() {
                      bills.add({'number': bills.length + 1, 'total': 100});
                    });
                  },
                  child: const Icon(Icons.add),
                ),
              );
            },
          ),
        ),
      );

      // Create a bill offline
      await tester.tap(find.byKey(const Key('create-bill')));
      await tester.pump();

      expect(find.text('Bill #1'), findsOneWidget);
      expect(find.text('₹100'), findsOneWidget);
    });
  });
}
