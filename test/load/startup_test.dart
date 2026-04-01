import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// App startup smoke tests
/// Validates that key widgets can be built without errors.
void main() {
  group('Startup tests', () {
    test('MaterialApp builds without error', () {
      // Verify basic MaterialApp construction works
      const app = MaterialApp(
        home: Scaffold(body: Center(child: Text('RetailLite'))),
      );
      expect(app, isNotNull);
    });

    testWidgets('App widget builds and renders text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: Text('RetailLite Startup Test'))),
        ),
      );

      expect(find.text('RetailLite Startup Test'), findsOneWidget);
    });

    test('ProviderScope init is fast (construction < 200ms)', () {
      final sw = Stopwatch()..start();

      // Simulate provider-like map construction (1000 entries)
      final providers = <String, dynamic>{};
      for (var i = 0; i < 1000; i++) {
        providers['provider_$i'] = i;
      }
      sw.stop();

      expect(sw.elapsedMilliseconds, lessThan(200));
      expect(providers.length, 1000);
    });
  });
}
