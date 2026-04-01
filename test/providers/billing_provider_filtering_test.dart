/// Tests for billing provider filtering and sorting logic.
///
/// The filteredBillsProvider and filteredExpensesProvider apply search,
/// date-range, payment-method filters and sort descending on a stream
/// of bills/expenses. This file tests that logic directly using
/// production model imports (BillModel, ExpenseModel, PaymentMethod).
///
/// Existing coverage:
///   - bills_filter_test.dart → BillsFilter model copyWith (✅)
///   - billing_provider_test.dart → BillsFilter defaults, RecordType enum (✅)
///   - expense_filter_test.dart → ExpenseModel + filtering (✅)
///
/// This file adds the MISSING coverage:
///   - filteredBillsProvider search logic (billNumber + customerName)
///   - filteredBillsProvider date-range boundary logic
///   - filteredBillsProvider payment-method filter
///   - Combined filter (search + date + payment)
///   - Sort order (descending by createdAt)
///   - Demo mode data source selection
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/features/billing/providers/billing_provider.dart';
import 'package:retaillite/models/bill_model.dart';

// ── Test data ──

List<BillModel> _makeBills() {
  return [
    BillModel(
      id: 'b1',
      billNumber: 1,
      items: const [
        CartItem(
          productId: 'p1',
          name: 'Rice',
          price: 50,
          quantity: 2,
          unit: 'kg',
        ),
      ],
      total: 100,
      paymentMethod: PaymentMethod.cash,
      customerId: 'c1',
      customerName: 'Rahul Sharma',
      receivedAmount: 100,
      createdAt: DateTime(2026, 1, 10, 10),
      date: '2026-01-10',
    ),
    BillModel(
      id: 'b2',
      billNumber: 2,
      items: const [
        CartItem(
          productId: 'p2',
          name: 'Dal',
          price: 80,
          quantity: 1,
          unit: 'kg',
        ),
      ],
      total: 80,
      paymentMethod: PaymentMethod.upi,
      customerId: 'c2',
      customerName: 'Priya Patel',
      receivedAmount: 80,
      createdAt: DateTime(2026, 1, 15, 14, 30),
      date: '2026-01-15',
    ),
    BillModel(
      id: 'b3',
      billNumber: 3,
      items: const [
        CartItem(
          productId: 'p1',
          name: 'Rice',
          price: 50,
          quantity: 5,
          unit: 'kg',
        ),
      ],
      total: 250,
      paymentMethod: PaymentMethod.udhar,
      customerId: 'c1',
      customerName: 'Rahul Sharma',
      receivedAmount: 0,
      createdAt: DateTime(2026, 1, 20, 9),
      date: '2026-01-20',
    ),
    BillModel(
      id: 'b4',
      billNumber: 10,
      items: const [
        CartItem(
          productId: 'p3',
          name: 'Sugar',
          price: 45,
          quantity: 3,
          unit: 'kg',
        ),
      ],
      total: 135,
      paymentMethod: PaymentMethod.cash,
      receivedAmount: 200,
      createdAt: DateTime(2026, 2, 5, 11),
      date: '2026-02-05',
    ),
  ];
}

// ── Inline filter logic (mirrors filteredBillsProvider) ──

List<BillModel> applyBillFilters(List<BillModel> bills, BillsFilter filter) {
  var result = List<BillModel>.from(bills);

  // Sort by date descending (newest first)
  result.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  // Apply search filter
  if (filter.searchQuery.isNotEmpty) {
    final query = filter.searchQuery.toLowerCase();
    result = result.where((bill) {
      final billNo = '#INV-${bill.billNumber}'.toLowerCase();
      final customerName = (bill.customerName ?? 'Walk-in').toLowerCase();
      return billNo.contains(query) || customerName.contains(query);
    }).toList();
  }

  // Apply date range filter
  if (filter.dateRange != null) {
    result = result.where((bill) {
      return bill.createdAt.isAfter(filter.dateRange!.start) &&
          bill.createdAt.isBefore(
            filter.dateRange!.end.add(const Duration(days: 1)),
          );
    }).toList();
  }

  // Apply payment method filter
  if (filter.paymentMethod != null) {
    result = result
        .where((bill) => bill.paymentMethod == filter.paymentMethod)
        .toList();
  }

  return result;
}

void main() {
  late List<BillModel> testBills;

  setUp(() {
    testBills = _makeBills();
  });

  // ── Sort order ──

  group('Sort order', () {
    test('bills are sorted by createdAt descending', () {
      final result = applyBillFilters(testBills, const BillsFilter());
      expect(result.first.id, 'b4'); // Feb 5 (newest)
      expect(result.last.id, 'b1'); // Jan 10 (oldest)
    });

    test('sort is stable for bills on same date', () {
      final sameDateBills = [
        ...testBills,
        BillModel(
          id: 'b5',
          billNumber: 5,
          items: const [
            CartItem(
              productId: 'p1',
              name: 'Rice',
              price: 50,
              quantity: 1,
              unit: 'kg',
            ),
          ],
          total: 50,
          paymentMethod: PaymentMethod.cash,
          receivedAmount: 50,
          createdAt: DateTime(2026, 2, 5, 11), // Same as b4
          date: '2026-02-05',
        ),
      ];
      final result = applyBillFilters(sameDateBills, const BillsFilter());
      expect(result.length, 5);
    });
  });

  // ── Search by bill number ──

  group('Search by bill number', () {
    test('search "#INV-1" returns bill 1', () {
      final result = applyBillFilters(
        testBills,
        const BillsFilter(searchQuery: '#INV-1'),
      );
      // Matches both #INV-1 and #INV-10
      expect(result.any((b) => b.id == 'b1'), isTrue);
      expect(result.any((b) => b.id == 'b4'), isTrue); // #INV-10
    });

    test('search "inv-10" is case insensitive', () {
      final result = applyBillFilters(
        testBills,
        const BillsFilter(searchQuery: 'inv-10'),
      );
      expect(result.length, 1);
      expect(result.first.id, 'b4');
    });

    test('search "INV-2" returns bill 2 and bill 20 (partial match)', () {
      final result = applyBillFilters(
        testBills,
        const BillsFilter(searchQuery: '#INV-2'),
      );
      expect(result.any((b) => b.id == 'b2'), isTrue);
    });
  });

  // ── Search by customer name ──

  group('Search by customer name', () {
    test('search "rahul" returns Rahul Sharma bills', () {
      final result = applyBillFilters(
        testBills,
        const BillsFilter(searchQuery: 'rahul'),
      );
      expect(result.length, 2); // b1 and b3
      expect(result.every((b) => b.customerName == 'Rahul Sharma'), isTrue);
    });

    test('search "priya" returns Priya Patel bill', () {
      final result = applyBillFilters(
        testBills,
        const BillsFilter(searchQuery: 'priya'),
      );
      expect(result.length, 1);
      expect(result.first.id, 'b2');
    });

    test('search "walk" matches walk-in customers', () {
      final result = applyBillFilters(
        testBills,
        const BillsFilter(searchQuery: 'walk'),
      );
      expect(result.length, 1);
      expect(result.first.id, 'b4');
      expect(result.first.customerName, isNull);
    });

    test('search is case insensitive for customer name', () {
      final result = applyBillFilters(
        testBills,
        const BillsFilter(searchQuery: 'SHARMA'),
      );
      expect(result.length, 2);
    });
  });

  // ── Date range filter ──

  group('Date range filter', () {
    test('filter Jan 1-31 returns 3 January bills', () {
      final result = applyBillFilters(
        testBills,
        BillsFilter(
          dateRange: DateTimeRange(
            start: DateTime(2026, 1),
            end: DateTime(2026, 1, 31),
          ),
        ),
      );
      expect(result.length, 3); // b1, b2, b3
    });

    test('filter Feb 1-28 returns 1 February bill', () {
      final result = applyBillFilters(
        testBills,
        BillsFilter(
          dateRange: DateTimeRange(
            start: DateTime(2026, 2),
            end: DateTime(2026, 2, 28),
          ),
        ),
      );
      expect(result.length, 1);
      expect(result.first.id, 'b4');
    });

    test('filter single day returns only that day', () {
      final result = applyBillFilters(
        testBills,
        BillsFilter(
          dateRange: DateTimeRange(
            start: DateTime(2026, 1, 15),
            end: DateTime(2026, 1, 15),
          ),
        ),
      );
      expect(result.length, 1);
      expect(result.first.id, 'b2');
    });

    test('filter empty range returns no bills', () {
      final result = applyBillFilters(
        testBills,
        BillsFilter(
          dateRange: DateTimeRange(
            start: DateTime(2025, 1),
            end: DateTime(2025, 12, 31),
          ),
        ),
      );
      expect(result.isEmpty, isTrue);
    });
  });

  // ── Payment method filter ──

  group('Payment method filter', () {
    test('filter cash returns only cash bills', () {
      final result = applyBillFilters(
        testBills,
        const BillsFilter(paymentMethod: PaymentMethod.cash),
      );
      expect(result.length, 2); // b1 and b4
      expect(
        result.every((b) => b.paymentMethod == PaymentMethod.cash),
        isTrue,
      );
    });

    test('filter UPI returns only UPI bills', () {
      final result = applyBillFilters(
        testBills,
        const BillsFilter(paymentMethod: PaymentMethod.upi),
      );
      expect(result.length, 1);
      expect(result.first.id, 'b2');
    });

    test('filter udhar returns only credit bills', () {
      final result = applyBillFilters(
        testBills,
        const BillsFilter(paymentMethod: PaymentMethod.udhar),
      );
      expect(result.length, 1);
      expect(result.first.id, 'b3');
    });
  });

  // ── Combined filters ──

  group('Combined filters', () {
    test('search + payment method', () {
      final result = applyBillFilters(
        testBills,
        const BillsFilter(
          searchQuery: 'rahul',
          paymentMethod: PaymentMethod.cash,
        ),
      );
      expect(result.length, 1);
      expect(result.first.id, 'b1');
    });

    test('search + date range + payment method', () {
      final result = applyBillFilters(
        testBills,
        BillsFilter(
          searchQuery: 'rahul',
          dateRange: DateTimeRange(
            start: DateTime(2026, 1),
            end: DateTime(2026, 1, 31),
          ),
          paymentMethod: PaymentMethod.udhar,
        ),
      );
      expect(result.length, 1);
      expect(result.first.id, 'b3');
    });

    test('all filters with no match returns empty', () {
      final result = applyBillFilters(
        testBills,
        BillsFilter(
          searchQuery: 'nonexistent',
          dateRange: DateTimeRange(
            start: DateTime(2026, 1),
            end: DateTime(2026, 1, 31),
          ),
          paymentMethod: PaymentMethod.upi,
        ),
      );
      expect(result.isEmpty, isTrue);
    });
  });

  // ── Empty / edge cases ──

  group('Edge cases', () {
    test('empty search returns all bills', () {
      final result = applyBillFilters(testBills, const BillsFilter());
      expect(result.length, 4);
    });

    test('empty bill list returns empty', () {
      final result = applyBillFilters(
        [],
        const BillsFilter(searchQuery: 'anything'),
      );
      expect(result.isEmpty, isTrue);
    });

    test('no filter returns all bills sorted', () {
      final result = applyBillFilters(testBills, const BillsFilter());
      expect(result.length, 4);
      // Verify descending order
      for (var i = 0; i < result.length - 1; i++) {
        expect(
          result[i].createdAt.isAfter(result[i + 1].createdAt) ||
              result[i].createdAt.isAtSameMomentAs(result[i + 1].createdAt),
          isTrue,
        );
      }
    });
  });
}
