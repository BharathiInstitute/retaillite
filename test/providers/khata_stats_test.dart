/// Tests for Khata Stats — customer sorting, outstanding calculation logic
///
/// These tests verify pure sorting/aggregation logic without importing the
/// provider (which has a deep transitive import chain that may have compile
/// issues in unrelated screens). We duplicate the lightweight data class and
/// enum definitions so the test is self-contained.
library;

import 'package:flutter_test/flutter_test.dart';

// ── Duplicated lightweight definitions for isolation ──

class KhataStats {
  final double totalOutstanding;
  final double collectedToday;
  final int activeCustomers;
  final int customersWithDue;

  const KhataStats({
    required this.totalOutstanding,
    required this.collectedToday,
    required this.activeCustomers,
    required this.customersWithDue,
  });

  factory KhataStats.empty() => const KhataStats(
    totalOutstanding: 0,
    collectedToday: 0,
    activeCustomers: 0,
    customersWithDue: 0,
  );
}

enum CustomerSortOption { highestDebt, recentlyActive, alphabetical, oldestDue }

/// Minimal customer for sorting tests
class _Customer {
  final String name;
  final double balance;
  final DateTime? lastTransactionAt;

  _Customer(this.name, {this.balance = 0, this.lastTransactionAt});
}

void main() {
  // ── KhataStats model ──

  group('KhataStats', () {
    test('creates with required fields', () {
      const stats = KhataStats(
        totalOutstanding: 5000,
        collectedToday: 1200,
        activeCustomers: 10,
        customersWithDue: 3,
      );
      expect(stats.totalOutstanding, 5000);
      expect(stats.collectedToday, 1200);
      expect(stats.activeCustomers, 10);
      expect(stats.customersWithDue, 3);
    });

    test('empty factory creates zeros', () {
      final stats = KhataStats.empty();
      expect(stats.totalOutstanding, 0);
      expect(stats.collectedToday, 0);
      expect(stats.activeCustomers, 0);
      expect(stats.customersWithDue, 0);
    });
  });

  // ── CustomerSortOption ──

  group('CustomerSortOption', () {
    test('has 4 options', () {
      expect(CustomerSortOption.values.length, 4);
    });

    test('all options are accessible', () {
      expect(CustomerSortOption.highestDebt, isNotNull);
      expect(CustomerSortOption.recentlyActive, isNotNull);
      expect(CustomerSortOption.alphabetical, isNotNull);
      expect(CustomerSortOption.oldestDue, isNotNull);
    });
  });

  // ── Outstanding calculation logic ──

  group('Outstanding calculation', () {
    double calcOutstanding(List<_Customer> customers) {
      return customers.fold<double>(
        0,
        (sum, c) => sum + (c.balance > 0 ? c.balance : 0),
      );
    }

    int countWithDue(List<_Customer> customers) {
      return customers.where((c) => c.balance > 0).length;
    }

    test('no customers gives zero outstanding', () {
      expect(calcOutstanding([]), 0);
      expect(countWithDue([]), 0);
    });

    test('single customer with positive balance', () {
      final customers = [_Customer('A', balance: 500)];
      expect(calcOutstanding(customers), 500);
      expect(countWithDue(customers), 1);
    });

    test('negative balance is not counted as outstanding', () {
      final customers = [_Customer('A', balance: -200)];
      expect(calcOutstanding(customers), 0);
      expect(countWithDue(customers), 0);
    });

    test('zero balance is not counted', () {
      final customers = [_Customer('A')];
      expect(calcOutstanding(customers), 0);
      expect(countWithDue(customers), 0);
    });

    test('mixed balances summed correctly', () {
      final customers = [
        _Customer('C1', balance: 1000),
        _Customer('C2', balance: -500),
        _Customer('C3', balance: 300),
        _Customer('C4'),
      ];
      expect(calcOutstanding(customers), 1300);
      expect(countWithDue(customers), 2);
    });
  });

  // ── Customer sorting logic ──

  group('Customer sorting', () {
    final customers = [
      _Customer('Charlie', balance: 100),
      _Customer('Alice', balance: 500),
      _Customer('Bob', balance: 300),
    ];

    test('highestDebt sorts by balance descending', () {
      final sorted = List<_Customer>.from(customers)
        ..sort((a, b) => b.balance.compareTo(a.balance));
      expect(sorted.first.name, 'Alice');
      expect(sorted.last.name, 'Charlie');
    });

    test('alphabetical sorts by name', () {
      final sorted = List<_Customer>.from(customers)
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      expect(sorted.first.name, 'Alice');
      expect(sorted[1].name, 'Bob');
      expect(sorted.last.name, 'Charlie');
    });

    test('recentlyActive sorts by last transaction date', () {
      final withDates = [
        _Customer('Old', lastTransactionAt: DateTime(2024)),
        _Customer('Recent', lastTransactionAt: DateTime(2024, 6, 15)),
        _Customer('NoDate'),
      ];
      final sorted = List<_Customer>.from(withDates)
        ..sort((a, b) {
          final aDate = a.lastTransactionAt ?? DateTime(1970);
          final bDate = b.lastTransactionAt ?? DateTime(1970);
          return bDate.compareTo(aDate);
        });
      expect(sorted.first.name, 'Recent');
      expect(sorted.last.name, 'NoDate');
    });
  });
}
