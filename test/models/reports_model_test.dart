/// Sales summary & report model tests
///
/// Tests date range calculations, period navigation, summary computations.
/// Critical for dashboard accuracy at scale.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/models/sales_summary_model.dart';

void main() {
  // ── SalesSummary ──

  group('SalesSummary', () {
    test('profit = totalSales - totalExpenses', () {
      final summary = SalesSummary(
        totalSales: 10000,
        billCount: 50,
        cashAmount: 6000,
        upiAmount: 3000,
        udharAmount: 1000,
        avgBillValue: 200,
        totalExpenses: 3000,
        startDate: DateTime(2024),
        endDate: DateTime(2024),
      );
      expect(summary.profit, 7000);
    });

    test('profit is totalSales when no expenses', () {
      final summary = SalesSummary(
        totalSales: 5000,
        billCount: 10,
        cashAmount: 5000,
        upiAmount: 0,
        udharAmount: 0,
        avgBillValue: 500,
        startDate: DateTime(2024),
        endDate: DateTime(2024),
      );
      expect(summary.profit, 5000);
    });

    test('cashPercentage calculates correctly', () {
      final summary = SalesSummary(
        totalSales: 10000,
        billCount: 50,
        cashAmount: 6000,
        upiAmount: 3000,
        udharAmount: 1000,
        avgBillValue: 200,
        startDate: DateTime(2024),
        endDate: DateTime(2024),
      );
      expect(summary.cashPercentage, 60.0);
      expect(summary.upiPercentage, 30.0);
      expect(summary.udharPercentage, 10.0);
    });

    test('percentages sum to ~100 when all accounted', () {
      final summary = SalesSummary(
        totalSales: 1000,
        billCount: 5,
        cashAmount: 700,
        upiAmount: 200,
        udharAmount: 100,
        avgBillValue: 200,
        startDate: DateTime(2024),
        endDate: DateTime(2024),
      );
      final total =
          summary.cashPercentage +
          summary.upiPercentage +
          summary.udharPercentage;
      expect(total, closeTo(100.0, 0.01));
    });

    test('percentages are 0 when totalSales is 0', () {
      final summary = SalesSummary.empty();
      expect(summary.cashPercentage, 0);
      expect(summary.upiPercentage, 0);
      expect(summary.udharPercentage, 0);
    });

    test('empty() creates zeroed summary', () {
      final summary = SalesSummary.empty();
      expect(summary.totalSales, 0);
      expect(summary.billCount, 0);
      expect(summary.cashAmount, 0);
      expect(summary.upiAmount, 0);
      expect(summary.udharAmount, 0);
      expect(summary.avgBillValue, 0);
      expect(summary.profit, 0);
    });
  });

  // ── ProductSale ──

  group('ProductSale', () {
    test('creates correctly', () {
      const ps = ProductSale(
        productId: 'p1',
        productName: 'Rice',
        quantitySold: 100,
        revenue: 5000,
      );
      expect(ps.productId, 'p1');
      expect(ps.productName, 'Rice');
      expect(ps.quantitySold, 100);
      expect(ps.revenue, 5000);
    });
  });

  // ── DateRange ──

  group('DateRange', () {
    test('today() starts at midnight and ends at 23:59:59', () {
      final range = DateRange.today();
      expect(range.start.hour, 0);
      expect(range.start.minute, 0);
      expect(range.end.hour, 23);
      expect(range.end.minute, 59);
      expect(range.end.second, 59);
    });

    test('today() start and end are same calendar day', () {
      final range = DateRange.today();
      expect(range.start.year, range.end.year);
      expect(range.start.month, range.end.month);
      expect(range.start.day, range.end.day);
    });

    test('thisWeek() spans 7 days', () {
      final range = DateRange.thisWeek();
      final days = range.end.difference(range.start).inDays;
      expect(days, greaterThanOrEqualTo(6));
      expect(days, lessThanOrEqualTo(7));
    });

    test('thisWeek() starts on Monday', () {
      final range = DateRange.thisWeek();
      expect(range.start.weekday, DateTime.monday);
    });

    test('thisMonth() starts on day 1', () {
      final range = DateRange.thisMonth();
      expect(range.start.day, 1);
    });

    test('thisMonth() ends on last day of month', () {
      final range = DateRange.thisMonth();
      final now = DateTime.now();
      final lastDay = DateTime(now.year, now.month + 1, 0).day;
      expect(range.end.day, lastDay);
    });

    test('custom() normalizes to day boundaries', () {
      final range = DateRange.custom(
        DateTime(2024, 3, 15, 14, 30),
        DateTime(2024, 3, 20, 8, 15),
      );
      expect(range.start.hour, 0);
      expect(range.start.minute, 0);
      expect(range.end.hour, 23);
      expect(range.end.minute, 59);
    });

    test('startStr and endStr format correctly', () {
      final range = DateRange.custom(
        DateTime(2024, 3, 5),
        DateTime(2024, 3, 15),
      );
      expect(range.startStr, '2024-03-05');
      expect(range.endStr, '2024-03-15');
    });

    test('startStr pads single-digit month/day', () {
      final range = DateRange.custom(
        DateTime(2024),
        DateTime(2024, 1, 9),
      );
      expect(range.startStr, '2024-01-01');
      expect(range.endStr, '2024-01-09');
    });
  });

  // ── ReportPeriod ──

  group('ReportPeriod', () {
    test('all periods have display names', () {
      for (final period in ReportPeriod.values) {
        expect(period.displayName, isNotEmpty);
        expect(period.hindiName, isNotEmpty);
      }
    });

    test('today dateRange is today', () {
      final range = ReportPeriod.today.dateRange;
      final now = DateTime.now();
      expect(range.start.day, now.day);
      expect(range.start.month, now.month);
    });

    test('today with offset -1 is yesterday', () {
      final range = ReportPeriod.today.getDateRange(offset: -1);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(range.start.day, yesterday.day);
    });

    test('today with offset +1 is tomorrow', () {
      final range = ReportPeriod.today.getDateRange(offset: 1);
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(range.start.day, tomorrow.day);
    });

    test('week with offset -1 is previous week', () {
      final thisWeek = ReportPeriod.week.getDateRange();
      final lastWeek = ReportPeriod.week.getDateRange(offset: -1);
      expect(lastWeek.start.isBefore(thisWeek.start), true);
      final diff = thisWeek.start.difference(lastWeek.start).inDays;
      expect(diff, 7);
    });

    test('month with offset -1 is previous month', () {
      final thisMonth = ReportPeriod.month.getDateRange();
      final lastMonth = ReportPeriod.month.getDateRange(offset: -1);
      expect(lastMonth.start.month != thisMonth.start.month, true);
    });

    test('month starts on day 1 for any offset', () {
      for (int i = -3; i <= 3; i++) {
        final range = ReportPeriod.month.getDateRange(offset: i);
        expect(range.start.day, 1, reason: 'offset=$i should start on day 1');
      }
    });

    test('custom returns today as fallback', () {
      final range = ReportPeriod.custom.dateRange;
      final today = DateRange.today();
      expect(range.start.day, today.start.day);
    });

    test('backward compatible dateRange getter works', () {
      const period = ReportPeriod.today;
      final range1 = period.dateRange;
      final range2 = period.getDateRange();
      expect(range1.startStr, range2.startStr);
      expect(range1.endStr, range2.endStr);
    });
  });

  // ── High-scale report scenarios ──

  group('Scale: 10K subscriber report accuracy', () {
    test('summary with 10K bills computes correctly', () {
      final summary = SalesSummary(
        totalSales: 5000000, // ₹50 lakh
        billCount: 10000,
        cashAmount: 3000000,
        upiAmount: 1500000,
        udharAmount: 500000,
        avgBillValue: 500,
        totalExpenses: 1000000,
        startDate: DateTime(2024),
        endDate: DateTime(2024, 12, 31),
      );
      expect(summary.profit, 4000000);
      expect(summary.cashPercentage, 60.0);
      expect(summary.upiPercentage, 30.0);
      expect(summary.udharPercentage, 10.0);
    });

    test('zero-bill summary edge case', () {
      final summary = SalesSummary.empty();
      expect(summary.cashPercentage, 0);
      expect(summary.profit, 0);
    });
  });
}
