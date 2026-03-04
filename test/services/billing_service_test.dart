/// Tests for billing service — today's summary aggregation logic
///
/// Tests the payment bucketing and total calculation logic.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/models/bill_model.dart';

/// Extracted from todaySummaryProvider — pure aggregation logic
Map<String, dynamic> _computeSummary(List<BillModel> bills) {
  double totalSales = 0;
  double cashAmount = 0;
  double upiAmount = 0;
  double udharAmount = 0;

  for (final bill in bills) {
    totalSales += bill.total;
    switch (bill.paymentMethod) {
      case PaymentMethod.cash:
        cashAmount += bill.total;
      case PaymentMethod.upi:
        upiAmount += bill.total;
      case PaymentMethod.udhar:
        udharAmount += bill.total;
      case PaymentMethod.unknown:
        break;
    }
  }

  return {
    'totalSales': totalSales,
    'billCount': bills.length,
    'cashAmount': cashAmount,
    'upiAmount': upiAmount,
    'udharAmount': udharAmount,
  };
}

BillModel _bill({
  required String id,
  required double total,
  required PaymentMethod method,
}) {
  return BillModel(
    id: id,
    billNumber: 1,
    items: const [
      CartItem(
        productId: 'p1',
        name: 'Test',
        price: 100,
        quantity: 1,
        unit: 'pc',
      ),
    ],
    total: total,
    paymentMethod: method,
    receivedAmount: total,
    createdAt: DateTime(2024),
    date: '2024-01-01',
  );
}

void main() {
  group('Today summary aggregation', () {
    test('empty bills gives zero summary', () {
      final summary = _computeSummary([]);
      expect(summary['totalSales'], 0.0);
      expect(summary['billCount'], 0);
      expect(summary['cashAmount'], 0.0);
      expect(summary['upiAmount'], 0.0);
      expect(summary['udharAmount'], 0.0);
    });

    test('single cash bill', () {
      final summary = _computeSummary([
        _bill(id: 'b1', total: 250, method: PaymentMethod.cash),
      ]);
      expect(summary['totalSales'], 250.0);
      expect(summary['billCount'], 1);
      expect(summary['cashAmount'], 250.0);
    });

    test('mixed payment methods', () {
      final summary = _computeSummary([
        _bill(id: 'b1', total: 100, method: PaymentMethod.cash),
        _bill(id: 'b2', total: 200, method: PaymentMethod.upi),
        _bill(id: 'b3', total: 300, method: PaymentMethod.udhar),
        _bill(id: 'b4', total: 150, method: PaymentMethod.cash),
      ]);
      expect(summary['totalSales'], 750.0);
      expect(summary['billCount'], 4);
      expect(summary['cashAmount'], 250.0);
      expect(summary['upiAmount'], 200.0);
      expect(summary['udharAmount'], 300.0);
    });

    test('unknown payment method adds to total but not buckets', () {
      final summary = _computeSummary([
        _bill(id: 'b1', total: 500, method: PaymentMethod.unknown),
      ]);
      expect(summary['totalSales'], 500.0);
      expect(summary['cashAmount'], 0.0);
      expect(summary['upiAmount'], 0.0);
      expect(summary['udharAmount'], 0.0);
    });

    test('large number of bills', () {
      final bills = List.generate(100, (i) {
        return _bill(
          id: 'b$i',
          total: 100.0,
          method: PaymentMethod.values[i % 3], // cash, upi, udhar rotation
        );
      });
      final summary = _computeSummary(bills);
      expect(summary['totalSales'], 10000.0);
      expect(summary['billCount'], 100);
    });
  });
}
