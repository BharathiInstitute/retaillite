/// Tests for Reports Provider — getEffectiveDateRange, SalesSummary, DateRange
///
/// Tests pure logic: date range computation, sales aggregation, product ranking.
/// Uses inline duplicate of getEffectiveDateRange to avoid transitive Firebase
/// import chain from reports_provider.dart.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/models/bill_model.dart';
import 'package:retaillite/models/sales_summary_model.dart';

// ── Inline duplicate (avoid reports_provider → error_logging → main → billing_screen) ──

DateRange getEffectiveDateRange(
  ReportPeriod period,
  int offset,
  DateRange? customRange,
) {
  if (period == ReportPeriod.custom && customRange != null) {
    return customRange;
  }
  return period.getDateRange(offset: offset);
}

void main() {
  // ── ReportPeriod enum ──

  group('ReportPeriod', () {
    test('has 4 values', () {
      expect(ReportPeriod.values.length, 4);
    });

    test('all have display names', () {
      for (final p in ReportPeriod.values) {
        expect(p.displayName, isNotEmpty);
        expect(p.hindiName, isNotEmpty);
      }
    });

    test('today.dateRange covers today', () {
      final range = ReportPeriod.today.dateRange;
      final now = DateTime.now();
      expect(range.start.year, now.year);
      expect(range.start.month, now.month);
      expect(range.start.day, now.day);
      expect(range.end.hour, 23);
      expect(range.end.minute, 59);
    });

    test('month.dateRange starts on 1st', () {
      final range = ReportPeriod.month.dateRange;
      expect(range.start.day, 1);
    });

    test('today.getDateRange offset=-1 gives yesterday', () {
      final range = ReportPeriod.today.getDateRange(offset: -1);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(range.start.day, yesterday.day);
    });

    test('week.getDateRange starts on Monday', () {
      final range = ReportPeriod.week.dateRange;
      expect(range.start.weekday, DateTime.monday);
    });
  });

  // ── DateRange ──

  group('DateRange', () {
    test('today factory covers current day', () {
      final range = DateRange.today();
      final now = DateTime.now();
      expect(range.start.day, now.day);
      expect(range.end.hour, 23);
    });

    test('thisMonth factory starts on 1st', () {
      final range = DateRange.thisMonth();
      expect(range.start.day, 1);
    });

    test('custom factory sets correct bounds', () {
      final range = DateRange.custom(
        DateTime(2024, 3, 10),
        DateTime(2024, 3, 20),
      );
      expect(range.start, DateTime(2024, 3, 10));
      expect(range.end.day, 20);
      expect(range.end.hour, 23);
    });

    test('startStr formats correctly', () {
      final range = DateRange(
        start: DateTime(2024, 1, 5),
        end: DateTime(2024, 1, 31),
      );
      expect(range.startStr, '2024-01-05');
    });

    test('endStr formats correctly', () {
      final range = DateRange(
        start: DateTime(2024, 12),
        end: DateTime(2024, 12, 31),
      );
      expect(range.endStr, '2024-12-31');
    });
  });

  // ── getEffectiveDateRange ──

  group('getEffectiveDateRange', () {
    test('uses period date range when not custom', () {
      final range = getEffectiveDateRange(ReportPeriod.today, 0, null);
      final now = DateTime.now();
      expect(range.start.day, now.day);
    });

    test('uses custom range when period is custom', () {
      final custom = DateRange(
        start: DateTime(2024, 3),
        end: DateTime(2024, 3, 31),
      );
      final range = getEffectiveDateRange(ReportPeriod.custom, 0, custom);
      expect(range.start, DateTime(2024, 3));
      expect(range.end, DateTime(2024, 3, 31));
    });

    test('falls back to today when custom range is null', () {
      final range = getEffectiveDateRange(ReportPeriod.custom, 0, null);
      final now = DateTime.now();
      expect(range.start.day, now.day);
    });

    test('applies offset to period', () {
      final range = getEffectiveDateRange(ReportPeriod.today, -1, null);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(range.start.day, yesterday.day);
    });
  });

  // ── SalesSummary ──

  group('SalesSummary', () {
    test('empty factory creates zeros', () {
      final s = SalesSummary.empty();
      expect(s.totalSales, 0);
      expect(s.billCount, 0);
      expect(s.cashAmount, 0);
      expect(s.upiAmount, 0);
      expect(s.udharAmount, 0);
      expect(s.avgBillValue, 0);
      expect(s.totalExpenses, 0);
    });

    test('profit is sales minus expenses', () {
      final s = SalesSummary(
        totalSales: 10000,
        billCount: 10,
        cashAmount: 6000,
        upiAmount: 3000,
        udharAmount: 1000,
        avgBillValue: 1000,
        totalExpenses: 2500,
        startDate: DateTime(2024),
        endDate: DateTime(2024, 1, 31),
      );
      expect(s.profit, 7500);
    });

    test('cashPercentage calculation', () {
      final s = SalesSummary(
        totalSales: 1000,
        billCount: 5,
        cashAmount: 500,
        upiAmount: 300,
        udharAmount: 200,
        avgBillValue: 200,
        startDate: DateTime(2024),
        endDate: DateTime(2024),
      );
      expect(s.cashPercentage, 50.0);
      expect(s.upiPercentage, 30.0);
      expect(s.udharPercentage, 20.0);
    });

    test('percentages are 0 when no sales', () {
      final s = SalesSummary.empty();
      expect(s.cashPercentage, 0);
      expect(s.upiPercentage, 0);
      expect(s.udharPercentage, 0);
    });
  });

  // ── ProductSale ──

  group('ProductSale', () {
    test('creates correctly', () {
      const ps = ProductSale(
        productId: 'p1',
        productName: 'Rice',
        quantitySold: 50,
        revenue: 2500.0,
      );
      expect(ps.productId, 'p1');
      expect(ps.productName, 'Rice');
      expect(ps.quantitySold, 50);
      expect(ps.revenue, 2500.0);
    });
  });

  // ── Sales aggregation logic (extracted from salesSummaryProvider) ──

  group('Sales aggregation logic', () {
    SalesSummary aggregateBills(List<BillModel> bills) {
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

      return SalesSummary(
        totalSales: totalSales,
        billCount: bills.length,
        cashAmount: cashAmount,
        upiAmount: upiAmount,
        udharAmount: udharAmount,
        avgBillValue: bills.isNotEmpty ? totalSales / bills.length : 0,
        startDate: DateTime(2024),
        endDate: DateTime(2024, 1, 31),
      );
    }

    test('empty bill list gives zero summary', () {
      final summary = aggregateBills([]);
      expect(summary.totalSales, 0);
      expect(summary.billCount, 0);
      expect(summary.avgBillValue, 0);
    });

    test('single cash bill aggregates correctly', () {
      final bills = [
        BillModel(
          id: 'b1',
          billNumber: 1,
          items: const [
            CartItem(
              productId: 'p1',
              name: 'Rice',
              price: 100,
              quantity: 1,
              unit: 'kg',
            ),
          ],
          total: 100,
          paymentMethod: PaymentMethod.cash,
          receivedAmount: 100,
          createdAt: DateTime(2024, 1, 15),
          date: '2024-01-15',
        ),
      ];
      final summary = aggregateBills(bills);
      expect(summary.totalSales, 100);
      expect(summary.billCount, 1);
      expect(summary.cashAmount, 100);
      expect(summary.upiAmount, 0);
      expect(summary.udharAmount, 0);
      expect(summary.avgBillValue, 100);
    });

    test('mixed payment methods bucketize correctly', () {
      final bills = [
        BillModel(
          id: 'b1',
          billNumber: 1,
          items: const [
            CartItem(
              productId: 'p1',
              name: 'A',
              price: 100,
              quantity: 1,
              unit: 'pc',
            ),
          ],
          total: 100,
          paymentMethod: PaymentMethod.cash,
          receivedAmount: 100,
          createdAt: DateTime(2024),
          date: '2024-01-01',
        ),
        BillModel(
          id: 'b2',
          billNumber: 2,
          items: const [
            CartItem(
              productId: 'p2',
              name: 'B',
              price: 200,
              quantity: 1,
              unit: 'pc',
            ),
          ],
          total: 200,
          paymentMethod: PaymentMethod.upi,
          receivedAmount: 200,
          createdAt: DateTime(2024),
          date: '2024-01-01',
        ),
        BillModel(
          id: 'b3',
          billNumber: 3,
          items: const [
            CartItem(
              productId: 'p3',
              name: 'C',
              price: 300,
              quantity: 1,
              unit: 'pc',
            ),
          ],
          total: 300,
          paymentMethod: PaymentMethod.udhar,
          receivedAmount: 0,
          createdAt: DateTime(2024),
          date: '2024-01-01',
        ),
      ];
      final summary = aggregateBills(bills);
      expect(summary.totalSales, 600);
      expect(summary.billCount, 3);
      expect(summary.cashAmount, 100);
      expect(summary.upiAmount, 200);
      expect(summary.udharAmount, 300);
      expect(summary.avgBillValue, 200);
    });

    test('unknown payment method is not bucketed', () {
      final bills = [
        BillModel(
          id: 'b1',
          billNumber: 1,
          items: const [
            CartItem(
              productId: 'p1',
              name: 'X',
              price: 500,
              quantity: 1,
              unit: 'pc',
            ),
          ],
          total: 500,
          paymentMethod: PaymentMethod.unknown,
          receivedAmount: 500,
          createdAt: DateTime(2024),
          date: '2024-01-01',
        ),
      ];
      final summary = aggregateBills(bills);
      expect(summary.totalSales, 500);
      expect(summary.cashAmount, 0);
      expect(summary.upiAmount, 0);
      expect(summary.udharAmount, 0);
    });
  });

  // ── Top products aggregation logic ──

  group('Top products aggregation', () {
    List<ProductSale> aggregateTopProducts(List<BillModel> bills) {
      final Map<String, ProductSale> productSales = {};
      for (final bill in bills) {
        for (final item in bill.items) {
          if (productSales.containsKey(item.productId)) {
            final existing = productSales[item.productId]!;
            productSales[item.productId] = ProductSale(
              productId: item.productId,
              productName: item.name,
              quantitySold: existing.quantitySold + item.quantity,
              revenue: existing.revenue + (item.price * item.quantity),
            );
          } else {
            productSales[item.productId] = ProductSale(
              productId: item.productId,
              productName: item.name,
              quantitySold: item.quantity,
              revenue: item.price * item.quantity,
            );
          }
        }
      }
      final sorted = productSales.values.toList()
        ..sort((a, b) => b.quantitySold.compareTo(a.quantitySold));
      return sorted.take(10).toList();
    }

    test('empty bills gives empty products', () {
      expect(aggregateTopProducts([]), isEmpty);
    });

    test('single bill with 2 items aggregates correctly', () {
      final bills = [
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
            CartItem(
              productId: 'p2',
              name: 'Dal',
              price: 80,
              quantity: 1,
              unit: 'kg',
            ),
          ],
          total: 180,
          paymentMethod: PaymentMethod.cash,
          receivedAmount: 180,
          createdAt: DateTime(2024),
          date: '2024-01-01',
        ),
      ];
      final products = aggregateTopProducts(bills);
      expect(products.length, 2);
      // Rice: qty=2, revenue=100
      expect(products.first.productId, 'p1');
      expect(products.first.quantitySold, 2);
      expect(products.first.revenue, 100);
    });

    test('same product across multiple bills is merged', () {
      final bills = [
        BillModel(
          id: 'b1',
          billNumber: 1,
          items: const [
            CartItem(
              productId: 'p1',
              name: 'Rice',
              price: 50,
              quantity: 3,
              unit: 'kg',
            ),
          ],
          total: 150,
          paymentMethod: PaymentMethod.cash,
          receivedAmount: 150,
          createdAt: DateTime(2024),
          date: '2024-01-01',
        ),
        BillModel(
          id: 'b2',
          billNumber: 2,
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
          paymentMethod: PaymentMethod.upi,
          receivedAmount: 250,
          createdAt: DateTime(2024, 1, 2),
          date: '2024-01-02',
        ),
      ];
      final products = aggregateTopProducts(bills);
      expect(products.length, 1);
      expect(products.first.quantitySold, 8);
      expect(products.first.revenue, 400); // 3*50 + 5*50
    });

    test('returns top 10 sorted by quantity', () {
      final items = List.generate(
        15,
        (i) => CartItem(
          productId: 'p$i',
          name: 'Product $i',
          price: 100,
          quantity: i + 1, // p0=1, p1=2, ..., p14=15
          unit: 'pc',
        ),
      );
      final bills = [
        BillModel(
          id: 'b1',
          billNumber: 1,
          items: items,
          total: 12000,
          paymentMethod: PaymentMethod.cash,
          receivedAmount: 12000,
          createdAt: DateTime(2024),
          date: '2024-01-01',
        ),
      ];
      final products = aggregateTopProducts(bills);
      expect(products.length, 10);
      // Should be p14, p13, p12, ..., p5 (top 10 by quantity desc)
      expect(products.first.productId, 'p14');
      expect(products.first.quantitySold, 15);
      expect(products.last.productId, 'p5');
      expect(products.last.quantitySold, 6);
    });
  });
}
