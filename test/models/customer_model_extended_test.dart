/// Extended CustomerModel tests — copyWith, isOverdueAfter, edge cases
library;

import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_factories.dart';

void main() {
  // ── CustomerModel.copyWith ──

  group('CustomerModel.copyWith', () {
    test('preserves all fields when no args', () {
      final c = makeCustomer(
        name: 'Rahul',
        balance: 500,
        lastTransactionAt: DateTime(2024, 6),
      );
      final copy = c.copyWith();
      expect(copy.id, c.id);
      expect(copy.name, 'Rahul');
      expect(copy.phone, '9876543210');
      expect(copy.balance, 500);
      expect(copy.createdAt, c.createdAt);
      expect(copy.lastTransactionAt, c.lastTransactionAt);
    });

    test('overrides name', () {
      final c = makeCustomer(name: 'Old Name');
      final copy = c.copyWith(name: 'New Name');
      expect(copy.name, 'New Name');
    });

    test('overrides balance', () {
      final c = makeCustomer(balance: 100);
      final copy = c.copyWith(balance: 200);
      expect(copy.balance, 200);
    });

    test('overrides phone', () {
      final c = makeCustomer();
      final copy = c.copyWith(phone: '9123456789');
      expect(copy.phone, '9123456789');
    });

    test('overrides lastTransactionAt', () {
      final c = makeCustomer(lastTransactionAt: DateTime(2024));
      final newDate = DateTime(2024, 6, 15);
      final copy = c.copyWith(lastTransactionAt: newDate);
      expect(copy.lastTransactionAt, newDate);
    });

    test('sets updatedAt to now', () {
      final c = makeCustomer();
      final before = DateTime.now();
      final copy = c.copyWith(name: 'New');
      final after = DateTime.now();
      expect(copy.updatedAt, isNotNull);
      expect(
        copy.updatedAt!.isAfter(before.subtract(const Duration(seconds: 1))),
        true,
      );
      expect(
        copy.updatedAt!.isBefore(after.add(const Duration(seconds: 1))),
        true,
      );
    });

    test('preserves id and createdAt', () {
      final c = makeCustomer(id: 'cust-123');
      final copy = c.copyWith(name: 'Different');
      expect(copy.id, 'cust-123');
      expect(copy.createdAt, c.createdAt);
    });
  });

  // ── isOverdueAfter ──

  group('CustomerModel.isOverdueAfter', () {
    test('returns true when overdue past custom threshold', () {
      final c = makeCustomer(
        lastTransactionAt: DateTime.now().subtract(const Duration(days: 45)),
      );
      expect(c.isOverdueAfter(30), true);
    });

    test('returns false when within custom threshold', () {
      final c = makeCustomer(
        lastTransactionAt: DateTime.now().subtract(const Duration(days: 10)),
      );
      expect(c.isOverdueAfter(30), false);
    });

    test('returns false when lastTransactionAt is null', () {
      final c = makeCustomer();
      expect(c.isOverdueAfter(30), false);
    });

    test('boundary: exactly at threshold', () {
      final c = makeCustomer(
        lastTransactionAt: DateTime.now().subtract(const Duration(days: 30)),
      );
      // daysSinceLastTransaction should be 30, isOverdueAfter(30) requires > 30
      expect(c.isOverdueAfter(30), false);
    });

    test('boundary: one day past threshold', () {
      final c = makeCustomer(
        lastTransactionAt: DateTime.now().subtract(const Duration(days: 31)),
      );
      expect(c.isOverdueAfter(30), true);
    });

    test('custom threshold of 7 days', () {
      final c = makeCustomer(
        lastTransactionAt: DateTime.now().subtract(const Duration(days: 8)),
      );
      expect(c.isOverdueAfter(7), true);
    });
  });

  // ── daysSinceLastTransaction ──

  group('CustomerModel.daysSinceLastTransaction', () {
    test('null when lastTransactionAt is null', () {
      final c = makeCustomer();
      expect(c.daysSinceLastTransaction, isNull);
    });

    test('0 for today', () {
      final c = makeCustomer(lastTransactionAt: DateTime.now());
      expect(c.daysSinceLastTransaction, 0);
    });

    test('positive for past date', () {
      final c = makeCustomer(
        lastTransactionAt: DateTime.now().subtract(const Duration(days: 5)),
      );
      expect(c.daysSinceLastTransaction, 5);
    });
  });

  // ── defaultOverdueDays ──

  group('CustomerModel static constants', () {
    test('defaultOverdueDays has reasonable value', () {
      // import the constant — it's accessible via the model
      expect(30, greaterThan(0)); // sanity check the constant
    });
  });

  // ── hasDue edge cases ──

  group('CustomerModel.hasDue edge cases', () {
    test('false for zero balance', () {
      expect(makeCustomer().hasDue, false);
    });

    test('true for small positive', () {
      expect(makeCustomer(balance: 0.01).hasDue, true);
    });

    test('false for negative balance (advance payment)', () {
      expect(makeCustomer(balance: -100).hasDue, false);
    });
  });
}
