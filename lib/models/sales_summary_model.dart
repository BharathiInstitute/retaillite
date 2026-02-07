/// Sales summary models for reports
library;

/// Sales summary for a period
class SalesSummary {
  final double totalSales;
  final int billCount;
  final double cashAmount;
  final double upiAmount;
  final double udharAmount;
  final double avgBillValue;
  final DateTime startDate;
  final DateTime endDate;

  const SalesSummary({
    required this.totalSales,
    required this.billCount,
    required this.cashAmount,
    required this.upiAmount,
    required this.udharAmount,
    required this.avgBillValue,
    required this.startDate,
    required this.endDate,
  });

  factory SalesSummary.empty() => SalesSummary(
    totalSales: 0,
    billCount: 0,
    cashAmount: 0,
    upiAmount: 0,
    udharAmount: 0,
    avgBillValue: 0,
    startDate: DateTime.now(),
    endDate: DateTime.now(),
  );

  /// Percentage of cash payments
  double get cashPercentage =>
      totalSales > 0 ? (cashAmount / totalSales) * 100 : 0;

  /// Percentage of UPI payments
  double get upiPercentage =>
      totalSales > 0 ? (upiAmount / totalSales) * 100 : 0;

  /// Percentage of credit payments
  double get udharPercentage =>
      totalSales > 0 ? (udharAmount / totalSales) * 100 : 0;
}

/// Product sales data
class ProductSale {
  final String productId;
  final String productName;
  final int quantitySold;
  final double revenue;

  const ProductSale({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.revenue,
  });
}

/// Date range for filtering reports
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({required this.start, required this.end});

  /// Today
  factory DateRange.today() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return DateRange(start: start, end: end);
  }

  /// This week (Monday to Sunday)
  factory DateRange.thisWeek() {
    final now = DateTime.now();
    final weekday = now.weekday;
    final start = DateTime(now.year, now.month, now.day - (weekday - 1));
    final end = DateTime(
      now.year,
      now.month,
      now.day + (7 - weekday),
      23,
      59,
      59,
    );
    return DateRange(start: start, end: end);
  }

  /// This month
  factory DateRange.thisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final end = DateTime(now.year, now.month, lastDay, 23, 59, 59);
    return DateRange(start: start, end: end);
  }

  /// Custom range
  factory DateRange.custom(DateTime start, DateTime end) {
    return DateRange(
      start: DateTime(start.year, start.month, start.day),
      end: DateTime(end.year, end.month, end.day, 23, 59, 59),
    );
  }

  /// Format date as string for Firestore queries
  String get startStr =>
      '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';

  String get endStr =>
      '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
}

/// Report period enum for UI
enum ReportPeriod {
  today('Today', 'आज'),
  week('This Week', 'इस सप्ताह'),
  month('This Month', 'इस महीने'),
  custom('Custom', 'कस्टम');

  final String displayName;
  final String hindiName;

  const ReportPeriod(this.displayName, this.hindiName);

  /// Get date range for period with optional offset (for navigation)
  DateRange getDateRange({int offset = 0}) {
    switch (this) {
      case ReportPeriod.today:
        final now = DateTime.now();
        final date = now.add(Duration(days: offset));
        return DateRange(
          start: DateTime(date.year, date.month, date.day),
          end: DateTime(date.year, date.month, date.day, 23, 59, 59),
        );
      case ReportPeriod.week:
        final now = DateTime.now();
        final weekday = now.weekday;
        final startOfWeek = DateTime(
          now.year,
          now.month,
          now.day - (weekday - 1),
        );
        final adjustedStart = startOfWeek.add(Duration(days: offset * 7));
        final adjustedEnd = adjustedStart.add(const Duration(days: 6));
        return DateRange(
          start: adjustedStart,
          end: DateTime(
            adjustedEnd.year,
            adjustedEnd.month,
            adjustedEnd.day,
            23,
            59,
            59,
          ),
        );
      case ReportPeriod.month:
        final now = DateTime.now();
        final targetMonth = DateTime(now.year, now.month + offset, 1);
        final lastDay = DateTime(
          targetMonth.year,
          targetMonth.month + 1,
          0,
        ).day;
        return DateRange(
          start: targetMonth,
          end: DateTime(
            targetMonth.year,
            targetMonth.month,
            lastDay,
            23,
            59,
            59,
          ),
        );
      case ReportPeriod.custom:
        return DateRange.today(); // Custom uses separate provider
    }
  }

  /// Get date range (backwards compatible)
  DateRange get dateRange => getDateRange();
}
