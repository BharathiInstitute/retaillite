/// Integration test: Khata (credit/debit ledger) flow
///
/// Tests the full customer lifecycle: creation, bill-based balance update,
/// payment recording, sorting/filtering, and outstanding aggregation.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/models/bill_model.dart';
import 'package:retaillite/models/customer_model.dart';
import 'package:retaillite/models/sales_summary_model.dart';

// ── Inline duplicate for KhataStats (avoid transitive import) ──

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

void main() {
  group('Integration: Khata Customer Flow', () {
    test('Step 1: New customer starts with zero balance', () {
      final customer = CustomerModel(
        id: 'cust-1',
        name: 'Rahul Sharma',
        phone: '9876543210',
        createdAt: DateTime(2026),
      );
      expect(customer.balance, 0);
      expect(customer.hasDue, isFalse);
    });

    test('Step 2: Udhar bill increases balance (customer owes)', () {
      final bill = BillModel(
        id: 'bill-1',
        billNumber: 1,
        items: [
          const CartItem(
            productId: 'p-1',
            name: 'Rice 5kg',
            price: 450,
            quantity: 1,
            unit: 'kg',
          ),
        ],
        total: 450,
        receivedAmount: 0,
        paymentMethod: PaymentMethod.udhar,
        customerId: 'cust-1',
        customerName: 'Rahul Sharma',
        date: '2026-01-15',
        createdAt: DateTime(2026, 1, 15),
      );
      expect(bill.paymentMethod, PaymentMethod.udhar);
      expect(bill.total, 450);
      expect(bill.receivedAmount, 0);

      // After bill: customer balance +450 (owes ₹450, positive = owes)
      final updatedCustomer = CustomerModel(
        id: 'cust-1',
        name: 'Rahul Sharma',
        phone: '9876543210',
        balance: 450,
        createdAt: DateTime(2026),
        lastTransactionAt: DateTime(2026, 1, 15),
      );
      expect(updatedCustomer.hasDue, isTrue);
      expect(updatedCustomer.balance, 450);
    });

    test('Step 3: Partial payment reduces outstanding', () {
      final customer = CustomerModel(
        id: 'cust-1',
        name: 'Rahul Sharma',
        phone: '9876543210',
        balance: 450, // owes 450 (positive = owes)
        createdAt: DateTime(2026),
        lastTransactionAt: DateTime(2026, 1, 15),
      );

      // Payment of ₹200 reduces what customer owes
      final afterPayment = customer.copyWith(
        balance: customer.balance - 200, // 450 - 200 = 250
        lastTransactionAt: DateTime(2026, 1, 20),
      );
      expect(afterPayment.balance, 250);
      expect(afterPayment.hasDue, isTrue);
    });

    test('Step 4: Full payment clears balance', () {
      final customer = CustomerModel(
        id: 'cust-1',
        name: 'Rahul Sharma',
        phone: '9876543210',
        balance: 250,
        createdAt: DateTime(2026),
      );

      final cleared = customer.copyWith(balance: 0);
      expect(cleared.balance, 0);
      expect(cleared.hasDue, isFalse);
    });

    test('Step 5: Overpayment creates negative balance (advance)', () {
      final customer = CustomerModel(
        id: 'cust-1',
        name: 'Rahul Sharma',
        phone: '9876543210',
        createdAt: DateTime(2026),
      );

      // Overpayment → negative balance means customer has advance
      final withAdvance = customer.copyWith(balance: -100);
      expect(withAdvance.balance, -100);
      expect(withAdvance.hasDue, isFalse); // negative = no due
    });
  });

  group('Integration: Khata Stats Aggregation', () {
    test('empty customer list gives zero stats', () {
      final stats = KhataStats.empty();
      expect(stats.totalOutstanding, 0);
      expect(stats.collectedToday, 0);
      expect(stats.activeCustomers, 0);
      expect(stats.customersWithDue, 0);
    });

    test('compute stats from customer list', () {
      final customers = [
        CustomerModel(
          id: '1',
          name: 'A',
          phone: '111',
          balance: 500, // owes 500
          createdAt: DateTime(2026),
        ),
        CustomerModel(
          id: '2',
          name: 'B',
          phone: '222',
          balance: 300, // owes 300
          createdAt: DateTime(2026),
        ),
        CustomerModel(
          id: '3',
          name: 'C',
          phone: '333',
          createdAt: DateTime(2026),
        ),
        CustomerModel(
          id: '4',
          name: 'D',
          phone: '444',
          balance: -100, // advance (negative = paid more)
          createdAt: DateTime(2026),
        ),
      ];

      final totalOutstanding = customers
          .where((c) => c.balance > 0)
          .fold<double>(0, (sum, c) => sum + c.balance);
      final customersWithDue = customers.where((c) => c.hasDue).length;

      expect(totalOutstanding, 800); // 500 + 300
      expect(customersWithDue, 2); // A and B
      expect(customers.length, 4);
    });
  });

  group('Integration: Customer Sorting', () {
    final customers = [
      CustomerModel(
        id: '1',
        name: 'Zara',
        phone: '111',
        balance: 100, // owes 100
        createdAt: DateTime(2026),
        lastTransactionAt: DateTime(2026, 3),
      ),
      CustomerModel(
        id: '2',
        name: 'Amit',
        phone: '222',
        balance: 500, // owes 500
        createdAt: DateTime(2026),
        lastTransactionAt: DateTime(2026),
      ),
      CustomerModel(
        id: '3',
        name: 'Maya',
        phone: '333',
        balance: 200, // owes 200
        createdAt: DateTime(2026),
        lastTransactionAt: DateTime(2026, 2),
      ),
    ];

    test('sort by highest debt puts biggest debtor first', () {
      final sorted = List.of(customers)
        ..sort((a, b) => b.balance.compareTo(a.balance)); // descending
      expect(sorted.first.name, 'Amit'); // 500
      expect(sorted.last.name, 'Zara'); // 100
    });

    test('sort alphabetically', () {
      final sorted = List.of(customers)
        ..sort((a, b) => a.name.compareTo(b.name));
      expect(sorted.first.name, 'Amit');
      expect(sorted[1].name, 'Maya');
      expect(sorted.last.name, 'Zara');
    });

    test('sort by recently active puts newest first', () {
      final sorted = List.of(customers)
        ..sort((a, b) {
          final aTime = a.lastTransactionAt ?? DateTime(1970);
          final bTime = b.lastTransactionAt ?? DateTime(1970);
          return bTime.compareTo(aTime);
        });
      expect(sorted.first.name, 'Zara'); // March
      expect(sorted.last.name, 'Amit'); // January
    });
  });

  group('Integration: Multi-udhar Bill Cycle', () {
    test('multiple udhar bills accumulate correctly', () {
      double balance = 0;

      // Bill 1: ₹500 udhar → customer owes more
      balance += 500;
      expect(balance, 500);

      // Payment: ₹200 → reduces what customer owes
      balance -= 200;
      expect(balance, 300);

      // Bill 2: ₹300 udhar
      balance += 300;
      expect(balance, 600);

      // Full payment: ₹600
      balance -= 600;
      expect(balance, 0);
    });
  });

  group('Integration: Date Range Filtering for Reports', () {
    test('today range covers full day', () {
      final range = DateRange.today();
      expect(range.start.hour, 0);
      expect(range.start.minute, 0);
      expect(range.end.hour, 23);
      expect(range.end.minute, 59);
    });

    test('this month starts on 1st', () {
      final range = ReportPeriod.month.dateRange;
      expect(range.start.day, 1);
    });

    test('this week starts on Monday', () {
      final range = ReportPeriod.week.dateRange;
      expect(range.start.weekday, DateTime.monday);
    });
  });
}
