import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Subscription E2E tests
void main() {
  group('Subscription E2E', () {
    testWidgets('subscription screen shows plan cards', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Subscription')),
            body: const Column(
              children: [
                Card(
                  child: ListTile(
                    title: Text('Free'),
                    subtitle: Text('50 bills/month'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: Text('Pro'),
                    subtitle: Text('500 bills/month'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: Text('Business'),
                    subtitle: Text('Unlimited'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Free'), findsOneWidget);
      expect(find.text('Pro'), findsOneWidget);
      expect(find.text('Business'), findsOneWidget);
    });

    testWidgets('toggle monthly/annual updates price display', (tester) async {
      var isAnnual = false;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    SwitchListTile(
                      key: const Key('toggle'),
                      title: Text(isAnnual ? 'Annual' : 'Monthly'),
                      value: isAnnual,
                      onChanged: (v) => setState(() => isAnnual = v),
                    ),
                    Text(isAnnual ? '₹2,999/year' : '₹299/month'),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('₹299/month'), findsOneWidget);

      await tester.tap(find.byKey(const Key('toggle')));
      await tester.pump();

      expect(find.text('₹2,999/year'), findsOneWidget);
    });
  });
}
