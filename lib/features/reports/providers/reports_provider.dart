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

/// Helper to get bills for a date range (supports demo mode)
Future<List<BillModel>> _getBillsForRange(
  DateRange range,
  bool isDemoMode,
) async {
  if (isDemoMode) {
    return DemoDataService.getBillsInRange(range.start, range.end);
  }
  return OfflineStorageService.getCachedBillsInRange(range.start, range.end);
}

/// Sales summary provider for the selected period - supports demo mode
final salesSummaryProvider = FutureProvider<SalesSummary>((ref) async {
  final isDemoMode = ref.watch(isDemoModeProvider);
  final period = ref.watch(selectedPeriodProvider);
  final offset = ref.watch(periodOffsetProvider);
  final customRange = ref.watch(customDateRangeProvider);

  // Get effective date range based on period, offset, and custom range
  final range = getEffectiveDateRange(period, offset, customRange);
  final bills = await _getBillsForRange(range, isDemoMode);

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

/// Bills for the selected period - supports demo mode
final periodBillsProvider = FutureProvider<List<BillModel>>((ref) async {
  final isDemoMode = ref.watch(isDemoModeProvider);
  final period = ref.watch(selectedPeriodProvider);
  final offset = ref.watch(periodOffsetProvider);
  final customRange = ref.watch(customDateRangeProvider);

  final range = getEffectiveDateRange(period, offset, customRange);
  return _getBillsForRange(range, isDemoMode);
});

/// Top products for the selected period - supports demo mode
final topProductsProvider = FutureProvider<List<ProductSale>>((ref) async {
  final isDemoMode = ref.watch(isDemoModeProvider);
  final period = ref.watch(selectedPeriodProvider);
  final offset = ref.watch(periodOffsetProvider);
  final customRange = ref.watch(customDateRangeProvider);

  final range = getEffectiveDateRange(period, offset, customRange);
  final bills = await _getBillsForRange(range, isDemoMode);

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
