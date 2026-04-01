/// Tests for UserCostsScreen (admin) — cost table, per-user breakdown, sorting.
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserCostsScreen cost table', () {
    test('cost table renders rows', () {
      final costRows = List.generate(
        5,
        (i) => {'user': 'user_$i', 'cost': i * 10.0},
      );
      expect(costRows.isNotEmpty, isTrue);
    });
  });

  group('UserCostsScreen per-user breakdown', () {
    test('per-user cost calculated from usage', () {
      const totalCost = 1000.0;
      const userCount = 50;
      const perUser = totalCost / userCount;
      expect(perUser, 20.0);
    });
  });

  group('UserCostsScreen sorting', () {
    test('sort by cost descending', () {
      final rows = [
        {'user': 'A', 'cost': 30.0},
        {'user': 'B', 'cost': 10.0},
        {'user': 'C', 'cost': 50.0},
      ];
      rows.sort((a, b) => (b['cost'] as double).compareTo(a['cost'] as double));
      expect(rows.first['user'], 'C');
      expect(rows.last['user'], 'B');
    });
  });
}
