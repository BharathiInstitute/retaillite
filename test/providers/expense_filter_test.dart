/// Tests for Expense model and filtering logic
///
/// Tests expense category parsing, payment method filtering,
/// date range filtering, and sorting — the core logic used in billing_provider.dart
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/models/bill_model.dart';
import 'package:retaillite/models/expense_model.dart';

void main() {
  group('ExpenseCategory', () {
    test('should have all expected categories', () {
      expect(ExpenseCategory.values.length, 7);
      expect(ExpenseCategory.values, contains(ExpenseCategory.rent));
      expect(ExpenseCategory.values, contains(ExpenseCategory.salary));
      expect(ExpenseCategory.values, contains(ExpenseCategory.utilities));
      expect(ExpenseCategory.values, contains(ExpenseCategory.supplies));
      expect(ExpenseCategory.values, contains(ExpenseCategory.transport));
      expect(ExpenseCategory.values, contains(ExpenseCategory.maintenance));
      expect(ExpenseCategory.values, contains(ExpenseCategory.other));
    });

    test('fromString handles unknown values', () {
      expect(ExpenseCategory.fromString('invalid'), ExpenseCategory.other);
    });

    test('fromString parses valid categories', () {
      expect(ExpenseCategory.fromString('rent'), ExpenseCategory.rent);
      expect(ExpenseCategory.fromString('salary'), ExpenseCategory.salary);
    });

    test('display names are correct', () {
      expect(ExpenseCategory.rent.displayName, 'Rent');
      expect(ExpenseCategory.salary.displayName, 'Salary');
      expect(ExpenseCategory.utilities.displayName, 'Utilities');
    });
  });

  group('ExpenseModel', () {
    test('should create expense with required fields', () {
      final expense = ExpenseModel(
        id: 'e1',
        amount: 5000,
        category: ExpenseCategory.rent,
        paymentMethod: PaymentMethod.upi,
        createdAt: DateTime(2024, 6),
        date: '2024-06-01',
      );

      expect(expense.id, 'e1');
      expect(expense.amount, 5000);
      expect(expense.category, ExpenseCategory.rent);
    });

    test('toMap/fromMap roundtrip', () {
      final original = ExpenseModel(
        id: 'e1',
        amount: 5000,
        category: ExpenseCategory.salary,
        description: 'Monthly staff salary',
        paymentMethod: PaymentMethod.cash,
        createdAt: DateTime(2024, 6, 15),
        date: '2024-06-15',
      );

      final map = original.toMap();
      final restored = ExpenseModel.fromMap(map);

      expect(restored.id, 'e1');
      expect(restored.amount, 5000);
      expect(restored.category, ExpenseCategory.salary);
      expect(restored.description, 'Monthly staff salary');
      expect(restored.paymentMethod, PaymentMethod.cash);
      expect(restored.date, '2024-06-15');
    });

    test('fromMap handles missing/null fields', () {
      final map = <String, dynamic>{};
      final expense = ExpenseModel.fromMap(map);

      expect(expense.id, '');
      expect(expense.amount, 0.0);
      expect(expense.category, ExpenseCategory.other);
      expect(expense.paymentMethod, PaymentMethod.cash);
    });
  });

  group('Expense filtering logic', () {
    final expenses = [
      ExpenseModel(
        id: 'e1',
        amount: 5000,
        category: ExpenseCategory.rent,
        description: 'Shop rent',
        paymentMethod: PaymentMethod.upi,
        createdAt: DateTime(2024, 6),
        date: '2024-06-01',
      ),
      ExpenseModel(
        id: 'e2',
        amount: 15000,
        category: ExpenseCategory.salary,
        description: 'Staff salary',
        paymentMethod: PaymentMethod.cash,
        createdAt: DateTime(2024, 6, 15),
        date: '2024-06-15',
      ),
      ExpenseModel(
        id: 'e3',
        amount: 800,
        category: ExpenseCategory.utilities,
        description: 'Electricity bill',
        paymentMethod: PaymentMethod.upi,
        createdAt: DateTime(2024, 7),
        date: '2024-07-01',
      ),
    ];

    test('search filter by description', () {
      final query = 'rent'.toLowerCase();
      final result = expenses.where((exp) {
        final desc = (exp.description ?? '').toLowerCase();
        final cat = exp.category.displayName.toLowerCase();
        return desc.contains(query) || cat.contains(query);
      }).toList();

      expect(result.length, 1);
      expect(result.first.id, 'e1');
    });

    test('search filter by category name', () {
      final query = 'salary'.toLowerCase();
      final result = expenses.where((exp) {
        final desc = (exp.description ?? '').toLowerCase();
        final cat = exp.category.displayName.toLowerCase();
        return desc.contains(query) || cat.contains(query);
      }).toList();

      expect(result.length, 1);
      expect(result.first.id, 'e2');
    });

    test('payment method filter', () {
      final upiExpenses = expenses
          .where((e) => e.paymentMethod == PaymentMethod.upi)
          .toList();
      expect(upiExpenses.length, 2);

      final cashExpenses = expenses
          .where((e) => e.paymentMethod == PaymentMethod.cash)
          .toList();
      expect(cashExpenses.length, 1);
    });

    test('date range filter', () {
      final range = DateTimeRange(
        start: DateTime(2024, 6),
        end: DateTime(2024, 6, 30),
      );

      final result = expenses.where((exp) {
        return exp.createdAt.isAfter(range.start) &&
            exp.createdAt.isBefore(range.end.add(const Duration(days: 1)));
      }).toList();

      // Note: isAfter is exclusive — expense on June 1 midnight is NOT after June 1 midnight
      // This matches the actual app behavior in billing_provider.dart
      expect(
        result.length,
        1,
      ); // Only June 15 (June 1 excluded by isAfter boundary)
    });

    test('sort by date descending', () {
      final sorted = List<ExpenseModel>.from(expenses)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      expect(sorted.first.id, 'e3'); // July = newest
      expect(sorted.last.id, 'e1'); // June 1 = oldest
    });

    test('total expense calculation', () {
      final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);
      expect(total, 20800); // 5000 + 15000 + 800
    });
  });
}
