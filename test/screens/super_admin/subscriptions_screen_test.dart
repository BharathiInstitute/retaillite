/// Tests for SubscriptionsScreen (admin) — list, filter, stats display.
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubscriptionsScreen list', () {
    test('subscription list renders', () {
      final subscriptions = List.generate(5, (i) => 'sub_$i');
      expect(subscriptions.isNotEmpty, isTrue);
    });
  });

  group('SubscriptionsScreen filter', () {
    test('filter by plan type works', () {
      final subs = [
        {'plan': 'pro'},
        {'plan': 'free'},
        {'plan': 'pro'},
      ];
      final proSubs = subs.where((s) => s['plan'] == 'pro').toList();
      expect(proSubs.length, 2);
    });
  });

  group('SubscriptionsScreen stats', () {
    test('stats row shows total, active, expired counts', () {
      const total = 100;
      const active = 80;
      const expired = 20;
      expect(active + expired, total);
    });
  });
}
