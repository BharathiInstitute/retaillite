/// Tests for BillsFilter model and filtering logic
///
/// These test pure business logic — no Firebase dependency.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/features/billing/providers/billing_provider.dart';
import 'package:retaillite/models/bill_model.dart';

void main() {
  group('BillsFilter', () {
    test('should have sensible defaults', () {
      const filter = BillsFilter();

      expect(filter.searchQuery, '');
      expect(filter.dateRange, isNull);
      expect(filter.paymentMethod, isNull);
      expect(filter.recordType, RecordType.all);
      expect(filter.page, 1);
      expect(filter.perPage, 10);
    });

    test('copyWith should update only specified fields', () {
      const original = BillsFilter(searchQuery: 'rice', page: 2);

      final updated = original.copyWith(searchQuery: 'sugar');

      expect(updated.searchQuery, 'sugar');
      expect(updated.page, 2); // unchanged
    });

    test('copyWith clearDateRange should set dateRange to null', () {
      final original = BillsFilter(
        dateRange: DateTimeRange(
          start: DateTime(2024),
          end: DateTime(2024, 1, 31),
        ),
      );

      final cleared = original.copyWith(clearDateRange: true);
      expect(cleared.dateRange, isNull);
    });

    test('copyWith clearPaymentMethod should set paymentMethod to null', () {
      const original = BillsFilter(paymentMethod: PaymentMethod.cash);

      final cleared = original.copyWith(clearPaymentMethod: true);
      expect(cleared.paymentMethod, isNull);
    });

    test('copyWith with recordType', () {
      const original = BillsFilter();

      final billsOnly = original.copyWith(recordType: RecordType.bills);
      expect(billsOnly.recordType, RecordType.bills);

      final expensesOnly = original.copyWith(recordType: RecordType.expenses);
      expect(expensesOnly.recordType, RecordType.expenses);
    });

    test('pagination should work correctly', () {
      const filter = BillsFilter();

      final nextPage = filter.copyWith(page: 2);
      expect(nextPage.page, 2);
      expect(nextPage.perPage, 10);
    });
  });

  group('RecordType', () {
    test('should have all expected values', () {
      expect(RecordType.values.length, 3);
      expect(RecordType.values, contains(RecordType.all));
      expect(RecordType.values, contains(RecordType.bills));
      expect(RecordType.values, contains(RecordType.expenses));
    });
  });

  group('Bill filtering logic', () {
    // Pure filtering logic tests using BillModel directly
    final bills = [
      BillModel(
        id: '1',
        billNumber: 101,
        items: const [
          CartItem(
            productId: 'p1',
            name: 'Rice',
            price: 60,
            quantity: 2,
            unit: 'kg',
          ),
        ],
        total: 120.0,
        paymentMethod: PaymentMethod.cash,
        customerName: 'Rahul',
        createdAt: DateTime(2024, 6, 15),
        date: '2024-06-15',
      ),
      BillModel(
        id: '2',
        billNumber: 102,
        items: const [
          CartItem(
            productId: 'p2',
            name: 'Sugar',
            price: 40,
            quantity: 1,
            unit: 'kg',
          ),
        ],
        total: 40.0,
        paymentMethod: PaymentMethod.upi,
        customerName: 'Priya',
        createdAt: DateTime(2024, 6, 16),
        date: '2024-06-16',
      ),
      BillModel(
        id: '3',
        billNumber: 103,
        items: const [],
        total: 200.0,
        paymentMethod: PaymentMethod.cash,
        createdAt: DateTime(2024, 7),
        date: '2024-07-01',
      ),
    ];

    test('search filter by bill number', () {
      final query = '#inv-101'.toLowerCase();
      final result = bills.where((bill) {
        final billNo = '#INV-${bill.billNumber}'.toLowerCase();
        return billNo.contains(query);
      }).toList();

      expect(result.length, 1);
      expect(result.first.billNumber, 101);
    });

    test('search filter by customer name', () {
      final query = 'rahul'.toLowerCase();
      final result = bills.where((bill) {
        final name = (bill.customerName ?? 'Walk-in').toLowerCase();
        return name.contains(query);
      }).toList();

      expect(result.length, 1);
      expect(result.first.customerName, 'Rahul');
    });

    test('walk-in bills should be searchable as Walk-in', () {
      final query = 'walk-in'.toLowerCase();
      final result = bills.where((bill) {
        final name = (bill.customerName ?? 'Walk-in').toLowerCase();
        return name.contains(query);
      }).toList();

      // Bill #103 has no customer name → defaults to Walk-in
      expect(result.length, 1);
      expect(result.first.billNumber, 103);
    });

    test('payment method filter', () {
      final cashBills = bills
          .where((b) => b.paymentMethod == PaymentMethod.cash)
          .toList();
      expect(cashBills.length, 2);

      final upiBills = bills
          .where((b) => b.paymentMethod == PaymentMethod.upi)
          .toList();
      expect(upiBills.length, 1);
    });

    test('date range filter', () {
      final range = DateTimeRange(
        start: DateTime(2024, 6),
        end: DateTime(2024, 6, 30),
      );

      final result = bills.where((bill) {
        return bill.createdAt.isAfter(range.start) &&
            bill.createdAt.isBefore(range.end.add(const Duration(days: 1)));
      }).toList();

      expect(result.length, 2); // June bills only
    });

    test('sort by date descending', () {
      final sorted = List<BillModel>.from(bills)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      expect(sorted.first.billNumber, 103); // July = newest
      expect(sorted.last.billNumber, 101); // June 15 = oldest
    });
  });
}
