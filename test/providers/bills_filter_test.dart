import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/features/billing/providers/billing_provider.dart';
import 'package:retaillite/models/bill_model.dart';

void main() {
  // ── BillsFilter ──

  group('BillsFilter', () {
    test('defaults', () {
      const filter = BillsFilter();
      expect(filter.searchQuery, '');
      expect(filter.dateRange, isNull);
      expect(filter.paymentMethod, isNull);
      expect(filter.recordType, RecordType.all);
      expect(filter.page, 1);
      expect(filter.perPage, 10);
    });

    test('copyWith updates searchQuery', () {
      const filter = BillsFilter();
      final updated = filter.copyWith(searchQuery: 'rice');
      expect(updated.searchQuery, 'rice');
      expect(updated.recordType, RecordType.all); // unchanged
    });

    test('copyWith updates dateRange', () {
      const filter = BillsFilter();
      final range = DateTimeRange(
        start: DateTime(2026, 1),
        end: DateTime(2026, 1, 31),
      );
      final updated = filter.copyWith(dateRange: range);
      expect(updated.dateRange, range);
    });

    test('copyWith clearDateRange resets to null', () {
      final filter = BillsFilter(
        dateRange: DateTimeRange(
          start: DateTime(2026, 1),
          end: DateTime(2026, 1, 31),
        ),
      );
      final updated = filter.copyWith(clearDateRange: true);
      expect(updated.dateRange, isNull);
    });

    test('copyWith updates paymentMethod', () {
      const filter = BillsFilter();
      final updated = filter.copyWith(paymentMethod: PaymentMethod.cash);
      expect(updated.paymentMethod, PaymentMethod.cash);
    });

    test('copyWith clearPaymentMethod resets to null', () {
      const filter = BillsFilter(paymentMethod: PaymentMethod.upi);
      final updated = filter.copyWith(clearPaymentMethod: true);
      expect(updated.paymentMethod, isNull);
    });

    test('copyWith updates recordType', () {
      const filter = BillsFilter();
      final updated = filter.copyWith(recordType: RecordType.bills);
      expect(updated.recordType, RecordType.bills);
    });

    test('copyWith updates page', () {
      const filter = BillsFilter();
      final updated = filter.copyWith(page: 3);
      expect(updated.page, 3);
    });

    test('copyWith updates perPage', () {
      const filter = BillsFilter();
      final updated = filter.copyWith(perPage: 25);
      expect(updated.perPage, 25);
    });

    test('copyWith preserves all when no args', () {
      final filter = BillsFilter(
        searchQuery: 'test',
        dateRange: DateTimeRange(
          start: DateTime(2026, 1),
          end: DateTime(2026, 1, 31),
        ),
        paymentMethod: PaymentMethod.cash,
        recordType: RecordType.expenses,
        page: 2,
        perPage: 20,
      );
      final copy = filter.copyWith();
      expect(copy.searchQuery, 'test');
      expect(copy.dateRange, filter.dateRange);
      expect(copy.paymentMethod, PaymentMethod.cash);
      expect(copy.recordType, RecordType.expenses);
      expect(copy.page, 2);
      expect(copy.perPage, 20);
    });

    test('clearDateRange true ignores new dateRange', () {
      const filter = BillsFilter();
      final range = DateTimeRange(
        start: DateTime(2026, 2),
        end: DateTime(2026, 2, 28),
      );
      final updated = filter.copyWith(dateRange: range, clearDateRange: true);
      expect(updated.dateRange, isNull);
    });

    test('clearPaymentMethod true ignores new paymentMethod', () {
      const filter = BillsFilter();
      final updated = filter.copyWith(
        paymentMethod: PaymentMethod.upi,
        clearPaymentMethod: true,
      );
      expect(updated.paymentMethod, isNull);
    });
  });

  // ── RecordType enum ──

  group('RecordType', () {
    test('has all, bills, expenses', () {
      expect(RecordType.values.length, 3);
      expect(RecordType.values, contains(RecordType.all));
      expect(RecordType.values, contains(RecordType.bills));
      expect(RecordType.values, contains(RecordType.expenses));
    });
  });
}
