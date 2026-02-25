/// Reports providers for sales data (Firestore-based)
/// Supports demo mode with local in-memory data
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/services/demo_data_service.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/models/bill_model.dart';
import 'package:retaillite/models/expense_model.dart';
import 'package:retaillite/models/sales_summary_model.dart';

/// Currently selected report period
final selectedPeriodProvider = StateProvider<ReportPeriod>(
  (ref) => ReportPeriod.today,
);

/// Offset for period navigation (0 = current, -1 = previous, +1 = next)
final periodOffsetProvider = StateProvider<int>((ref) => 0);

/// Custom date range for custom period
final customDateRangeProvider = StateProvider<DateRange?>((ref) => null);

/// Computed date range based on period and offset
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

/// Helper to get bills stream for a date range (supports demo mode)
Stream<List<BillModel>> _getBillsStreamForRange(
  DateRange range,
  bool isDemoMode,
) {
  if (isDemoMode) {
    return Stream.value(
      DemoDataService.getBillsInRange(range.start, range.end),
    );
  }
  return OfflineStorageService.billsInRangeStream(range.start, range.end);
}

/// Sales summary provider — real-time stream from Firestore
final salesSummaryProvider = StreamProvider.autoDispose<SalesSummary>((ref) {
  final isDemoMode = ref.watch(isDemoModeProvider);
  final period = ref.watch(selectedPeriodProvider);
  final offset = ref.watch(periodOffsetProvider);
  final customRange = ref.watch(customDateRangeProvider);

  // Get effective date range based on period, offset, and custom range
  final range = getEffectiveDateRange(period, offset, customRange);
  final billsStream = _getBillsStreamForRange(range, isDemoMode);

  // Combine bills stream with on-demand expenses fetch
  return billsStream.asyncMap((bills) async {
    double totalSales = 0;
    double cashAmount = 0;
    double upiAmount = 0;
    double udharAmount = 0;

    for (final bill in bills) {
      totalSales += bill.total;
      switch (bill.paymentMethod) {
        case PaymentMethod.cash:
          cashAmount += bill.total;
          break;
        case PaymentMethod.upi:
          upiAmount += bill.total;
          break;
        case PaymentMethod.udhar:
          udharAmount += bill.total;
          break;
        case PaymentMethod.unknown:
          break;
      }
    }

    // Compute expenses for the same period
    double totalExpenses = 0;
    try {
      List<ExpenseModel> expenses;
      if (isDemoMode) {
        expenses = DemoDataService.getExpenses();
      } else {
        expenses = await OfflineStorageService.getCachedExpensesAsync();
      }
      for (final expense in expenses) {
        if (!expense.createdAt.isBefore(range.start) &&
            !expense.createdAt.isAfter(range.end)) {
          totalExpenses += expense.amount;
        }
      }
    } catch (_) {
      // Expense fetch failure shouldn't break the summary
    }

    return SalesSummary(
      totalSales: totalSales,
      billCount: bills.length,
      cashAmount: cashAmount,
      upiAmount: upiAmount,
      udharAmount: udharAmount,
      avgBillValue: bills.isNotEmpty ? totalSales / bills.length : 0,
      totalExpenses: totalExpenses,
      startDate: range.start,
      endDate: range.end,
    );
  });
});

/// Bills for the selected period — real-time stream from Firestore
final periodBillsProvider = StreamProvider.autoDispose<List<BillModel>>((ref) {
  final isDemoMode = ref.watch(isDemoModeProvider);
  final period = ref.watch(selectedPeriodProvider);
  final offset = ref.watch(periodOffsetProvider);
  final customRange = ref.watch(customDateRangeProvider);

  final range = getEffectiveDateRange(period, offset, customRange);
  return _getBillsStreamForRange(range, isDemoMode);
});

/// Top products for the selected period — derives from period bills stream
final topProductsProvider = Provider<AsyncValue<List<ProductSale>>>((ref) {
  final periodBillsAsync = ref.watch(periodBillsProvider);

  return periodBillsAsync.whenData((bills) {
    // Aggregate product sales
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

    // Sort by quantity and return top 10
    final sorted = productSales.values.toList()
      ..sort((a, b) => b.quantitySold.compareTo(a.quantitySold));

    return sorted.take(10).toList();
  });
});

/// Dashboard bills provider — real-time stream for last 7 days
final dashboardBillsProvider = StreamProvider.autoDispose<List<BillModel>>((
  ref,
) {
  final isDemoMode = ref.watch(isDemoModeProvider);
  final now = DateTime.now();
  final end = now;
  final start = now.subtract(const Duration(days: 7));
  return _getBillsStreamForRange(DateRange(start: start, end: end), isDemoMode);
});
