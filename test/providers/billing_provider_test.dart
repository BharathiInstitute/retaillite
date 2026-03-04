import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/features/billing/providers/billing_provider.dart';
import 'package:retaillite/models/bill_model.dart';

void main() {
  group('RecordType enum', () {
    test('has 3 values', () {
      expect(RecordType.values.length, 3);
    });

    test('contains all, bills, expenses', () {
      expect(RecordType.values, contains(RecordType.all));
      expect(RecordType.values, contains(RecordType.bills));
      expect(RecordType.values, contains(RecordType.expenses));
    });
  });

  group('BillsFilter', () {
    test('default constructor has sensible defaults', () {
      const filter = BillsFilter();
      expect(filter.searchQuery, '');
      expect(filter.dateRange, isNull);
      expect(filter.paymentMethod, isNull);
      expect(filter.recordType, RecordType.all);
      expect(filter.page, 1);
      expect(filter.perPage, 10);
    });

    test('copyWith preserves values when no args given', () {
      const filter = BillsFilter(
        searchQuery: 'Rice',
        paymentMethod: PaymentMethod.cash,
        recordType: RecordType.bills,
        page: 3,
        perPage: 25,
      );
      final copy = filter.copyWith();
      expect(copy.searchQuery, 'Rice');
      expect(copy.paymentMethod, PaymentMethod.cash);
      expect(copy.recordType, RecordType.bills);
      expect(copy.page, 3);
      expect(copy.perPage, 25);
    });

    test('copyWith overrides searchQuery', () {
      const filter = BillsFilter(searchQuery: 'old');
      final copy = filter.copyWith(searchQuery: 'new');
      expect(copy.searchQuery, 'new');
    });

    test('copyWith overrides paymentMethod', () {
      const filter = BillsFilter(paymentMethod: PaymentMethod.cash);
      final copy = filter.copyWith(paymentMethod: PaymentMethod.upi);
      expect(copy.paymentMethod, PaymentMethod.upi);
    });

    test('copyWith overrides dateRange', () {
      const filter = BillsFilter();
      final range = DateTimeRange(
        start: DateTime(2026),
        end: DateTime(2026, 1, 31),
      );
      final copy = filter.copyWith(dateRange: range);
      expect(copy.dateRange, range);
    });

    test('copyWith clearDateRange removes dateRange', () {
      final filter = BillsFilter(
        dateRange: DateTimeRange(
          start: DateTime(2026),
          end: DateTime(2026, 1, 31),
        ),
      );
      final copy = filter.copyWith(clearDateRange: true);
      expect(copy.dateRange, isNull);
    });

    test('copyWith clearPaymentMethod removes paymentMethod', () {
      const filter = BillsFilter(paymentMethod: PaymentMethod.cash);
      final copy = filter.copyWith(clearPaymentMethod: true);
      expect(copy.paymentMethod, isNull);
    });

    test('copyWith overrides page and perPage', () {
      const filter = BillsFilter();
      final copy = filter.copyWith(page: 5, perPage: 50);
      expect(copy.page, 5);
      expect(copy.perPage, 50);
    });

    test('copyWith overrides recordType', () {
      const filter = BillsFilter();
      final copy = filter.copyWith(recordType: RecordType.expenses);
      expect(copy.recordType, RecordType.expenses);
    });

    test('clearDateRange takes precedence over dateRange', () {
      final range = DateTimeRange(
        start: DateTime(2026),
        end: DateTime(2026, 1, 31),
      );
      final filter = BillsFilter(dateRange: range);
      // Even if dateRange is passed, clearDateRange should win
      final copy = filter.copyWith(
        dateRange: DateTimeRange(
          start: DateTime(2026, 2),
          end: DateTime(2026, 2, 28),
        ),
        clearDateRange: true,
      );
      expect(copy.dateRange, isNull);
    });

    test('clearPaymentMethod takes precedence over paymentMethod', () {
      const filter = BillsFilter(paymentMethod: PaymentMethod.cash);
      final copy = filter.copyWith(
        paymentMethod: PaymentMethod.upi,
        clearPaymentMethod: true,
      );
      expect(copy.paymentMethod, isNull);
    });
  });
}
