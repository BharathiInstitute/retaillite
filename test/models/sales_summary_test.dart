import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/models/bill_model.dart';
import 'package:retaillite/models/sales_summary_model.dart';

void main() {
  group('CartItem edge cases', () {
    test('should handle fromMap with missing fields gracefully', () {
      final item = CartItem.fromMap(<String, dynamic>{});

      expect(item.productId, '');
      expect(item.name, '');
      expect(item.price, 0.0);
      expect(item.quantity, 1);
      expect(item.unit, 'pcs');
    });

    test('should handle fromMap with null values gracefully', () {
      final item = CartItem.fromMap({
        'productId': null,
        'name': null,
        'price': null,
        'quantity': null,
        'unit': null,
      });

      expect(item.productId, '');
      expect(item.name, '');
      expect(item.price, 0.0);
      expect(item.quantity, 1);
      expect(item.unit, 'pcs');
    });

    test('should handle int price in fromMap', () {
      final item = CartItem.fromMap({
        'productId': 'p1',
        'name': 'Test',
        'price': 100, // int, not double
        'quantity': 2,
        'unit': 'kg',
      });

      expect(item.price, 100.0);
      expect(item.total, 200.0);
    });

    test('should compute total correctly for zero price', () {
      const item = CartItem(
        productId: 'p1',
        name: 'Free',
        price: 0.0,
        quantity: 5,
        unit: 'pcs',
      );

      expect(item.total, 0.0);
    });

    test('should round-trip through toMap/fromMap', () {
      const original = CartItem(
        productId: 'prod-rt',
        name: 'Round Trip Item',
        price: 99.95,
        quantity: 3,
        unit: 'kg',
      );

      final restored = CartItem.fromMap(original.toMap());

      expect(restored.productId, original.productId);
      expect(restored.name, original.name);
      expect(restored.price, original.price);
      expect(restored.quantity, original.quantity);
      expect(restored.unit, original.unit);
      expect(restored.total, original.total);
    });
  });

  group('BillModel edge cases', () {
    test('should handle empty items list', () {
      final bill = BillModel(
        id: 'bill-empty',
        billNumber: 0,
        items: const [],
        total: 0.0,
        paymentMethod: PaymentMethod.cash,
        createdAt: DateTime(2024),
        date: '2024-01-01',
      );

      expect(bill.itemCount, 0);
      expect(bill.changeAmount, isNull);
    });

    test('should handle negative change (underpayment)', () {
      final bill = BillModel(
        id: 'bill-under',
        billNumber: 1,
        items: const [],
        total: 500.0,
        paymentMethod: PaymentMethod.cash,
        receivedAmount: 300.0,
        createdAt: DateTime(2024),
        date: '2024-01-01',
      );

      expect(bill.changeAmount, -200.0);
    });

    test('should handle exact payment (zero change)', () {
      final bill = BillModel(
        id: 'bill-exact',
        billNumber: 2,
        items: const [],
        total: 500.0,
        paymentMethod: PaymentMethod.cash,
        receivedAmount: 500.0,
        createdAt: DateTime(2024),
        date: '2024-01-01',
      );

      expect(bill.changeAmount, 0.0);
    });

    test('should serialize to map and back correctly', () {
      final original = BillModel(
        id: 'bill-rt',
        billNumber: 42,
        items: const [
          CartItem(
            productId: 'p1',
            name: 'Item A',
            price: 100.0,
            quantity: 2,
            unit: 'pcs',
          ),
          CartItem(
            productId: 'p2',
            name: 'Item B',
            price: 50.0,
            quantity: 1,
            unit: 'kg',
          ),
        ],
        total: 250.0,
        paymentMethod: PaymentMethod.upi,
        customerId: 'cust-1',
        customerName: 'Test Customer',
        receivedAmount: 250.0,
        createdAt: DateTime(2024, 6, 15, 14, 30),
        date: '2024-06-15',
      );

      final map = original.toMap();
      expect(map['id'], 'bill-rt');
      expect(map['billNumber'], 42);
      expect(map['paymentMethod'], 'upi');
      expect(map['customerId'], 'cust-1');
      expect(map['customerName'], 'Test Customer');
      expect((map['items'] as List).length, 2);
    });

    test('should handle unknown payment method in fromString', () {
      expect(PaymentMethod.fromString('bitcoin'), PaymentMethod.unknown);
      expect(PaymentMethod.fromString(''), PaymentMethod.unknown);
    });
  });

  group('SalesSummary', () {
    test('should calculate percentages correctly', () {
      final summary = SalesSummary(
        totalSales: 1000.0,
        billCount: 10,
        cashAmount: 500.0,
        upiAmount: 300.0,
        udharAmount: 200.0,
        avgBillValue: 100.0,
        startDate: DateTime(2024),
        endDate: DateTime(2024, 1, 31),
      );

      expect(summary.cashPercentage, 50.0);
      expect(summary.upiPercentage, 30.0);
      expect(summary.udharPercentage, 20.0);
    });

    test('should return zero percentages when totalSales is zero', () {
      final summary = SalesSummary.empty();

      expect(summary.cashPercentage, 0.0);
      expect(summary.upiPercentage, 0.0);
      expect(summary.udharPercentage, 0.0);
    });

    test('should calculate profit correctly', () {
      final summary = SalesSummary(
        totalSales: 10000.0,
        billCount: 20,
        cashAmount: 5000.0,
        upiAmount: 3000.0,
        udharAmount: 2000.0,
        avgBillValue: 500.0,
        totalExpenses: 3000.0,
        startDate: DateTime(2024),
        endDate: DateTime(2024, 1, 31),
      );

      expect(summary.profit, 7000.0);
    });

    test('should handle negative profit (loss)', () {
      final summary = SalesSummary(
        totalSales: 5000.0,
        billCount: 10,
        cashAmount: 5000.0,
        upiAmount: 0,
        udharAmount: 0,
        avgBillValue: 500.0,
        totalExpenses: 8000.0,
        startDate: DateTime(2024),
        endDate: DateTime(2024, 1, 31),
      );

      expect(summary.profit, -3000.0);
    });

    test('should have zero expenses by default', () {
      final summary = SalesSummary.empty();

      expect(summary.totalExpenses, 0.0);
      expect(summary.profit, 0.0);
    });
  });

  group('DateRange', () {
    test('today should cover full day', () {
      final range = DateRange.today();
      final now = DateTime.now();

      expect(range.start.hour, 0);
      expect(range.start.minute, 0);
      expect(range.end.hour, 23);
      expect(range.end.minute, 59);
      expect(range.start.day, now.day);
      expect(range.end.day, now.day);
    });

    test('thisMonth should start on day 1', () {
      final range = DateRange.thisMonth();
      final now = DateTime.now();

      expect(range.start.day, 1);
      expect(range.start.month, now.month);
      expect(range.end.month, now.month);
    });

    test('custom should accept arbitrary dates', () {
      final range = DateRange.custom(
        DateTime(2024, 1, 15),
        DateTime(2024, 2, 28),
      );

      expect(range.start, DateTime(2024, 1, 15));
      expect(range.end.year, 2024);
      expect(range.end.month, 2);
      expect(range.end.day, 28);
      expect(range.end.hour, 23);
    });

    test('startStr and endStr should format correctly', () {
      final range = DateRange.custom(
        DateTime(2024, 3, 5),
        DateTime(2024, 12, 25),
      );

      expect(range.startStr, '2024-03-05');
      expect(range.endStr, '2024-12-25');
    });
  });

  group('ReportPeriod', () {
    test('should return correct date range for today', () {
      final range = ReportPeriod.today.getDateRange();
      final now = DateTime.now();

      expect(range.start.year, now.year);
      expect(range.start.month, now.month);
      expect(range.start.day, now.day);
    });

    test('should support offset for navigation', () {
      final yesterday = ReportPeriod.today.getDateRange(offset: -1);
      final now = DateTime.now();
      final expected = now.subtract(const Duration(days: 1));

      expect(yesterday.start.day, expected.day);
    });

    test('custom period should return today as fallback', () {
      final range = ReportPeriod.custom.getDateRange();
      final now = DateTime.now();

      expect(range.start.day, now.day);
    });
  });
}
