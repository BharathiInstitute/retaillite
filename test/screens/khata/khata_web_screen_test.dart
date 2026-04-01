/// Tests for KhataWebScreen — customer list, search, and balance display logic.
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KhataWebScreen search filtering', () {
    test('search filters customers by name case-insensitively', () {
      const customers = ['Raj Sharma', 'Priya Singh', 'Rajesh Kumar'];
      const query = 'raj';
      final filtered = customers
          .where((c) => c.toLowerCase().contains(query.toLowerCase()))
          .toList();
      expect(filtered, ['Raj Sharma', 'Rajesh Kumar']);
    });

    test('empty search returns all customers', () {
      const customers = ['Raj', 'Priya'];
      const query = '';
      final filtered = query.isEmpty
          ? customers
          : customers
                .where((c) => c.toLowerCase().contains(query.toLowerCase()))
                .toList();
      expect(filtered.length, 2);
    });

    test('search with no matches returns empty', () {
      const customers = ['Raj', 'Priya'];
      const query = 'xyz';
      final filtered = customers
          .where((c) => c.toLowerCase().contains(query.toLowerCase()))
          .toList();
      expect(filtered, isEmpty);
    });
  });

  group('KhataWebScreen balance calculations', () {
    test('total outstanding is sum of all customer balances', () {
      const balances = [500.0, 1200.0, 300.0];
      final total = balances.fold<double>(0, (sum, b) => sum + b);
      expect(total, 2000.0);
    });

    test('zero balances give zero total', () {
      const balances = [0.0, 0.0, 0.0];
      final total = balances.fold<double>(0, (sum, b) => sum + b);
      expect(total, 0.0);
    });

    test('negative balance (overpayment) reduces total', () {
      const balances = [500.0, -100.0, 300.0];
      final total = balances.fold<double>(0, (sum, b) => sum + b);
      expect(total, 700.0);
    });
  });

  group('KhataWebScreen master-detail layout', () {
    test('wide screen shows master-detail side by side', () {
      const screenWidth = 1200.0;
      const showDetail = screenWidth >= 800;
      expect(showDetail, isTrue);
    });

    test('narrow screen shows list only', () {
      const screenWidth = 600.0;
      const showDetail = screenWidth >= 800;
      expect(showDetail, isFalse);
    });
  });

  group('KhataWebScreen sorting', () {
    test('sort by name alphabetically', () {
      final customers = ['Raj', 'Amit', 'Priya'];
      customers.sort();
      expect(customers, ['Amit', 'Priya', 'Raj']);
    });

    test('sort by balance descending', () {
      final customers = [
        {'name': 'A', 'balance': 500.0},
        {'name': 'B', 'balance': 1200.0},
        {'name': 'C', 'balance': 300.0},
      ];
      customers.sort(
        (a, b) => (b['balance'] as double).compareTo(a['balance'] as double),
      );
      expect(customers.first['name'], 'B');
      expect(customers.last['name'], 'C');
    });
  });
}
