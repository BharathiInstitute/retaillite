/// Reports providers for sales data (Firestore-based)
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';
import 'package:retaillite/models/bill_model.dart';
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

/// Sales summary provider for the selected period
final salesSummaryProvider = FutureProvider<SalesSummary>((ref) async {
  final period = ref.watch(selectedPeriodProvider);
  final offset = ref.watch(periodOffsetProvider);
  final customRange = ref.watch(customDateRangeProvider);

  // Get effective date range based on period, offset, and custom range
  final range = getEffectiveDateRange(period, offset, customRange);
  final bills = await OfflineStorageService.getCachedBillsInRange(
    range.start,
    range.end,
  );

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
    }
  }

  return SalesSummary(
    totalSales: totalSales,
    billCount: bills.length,
    cashAmount: cashAmount,
    upiAmount: upiAmount,
    udharAmount: udharAmount,
    avgBillValue: bills.isNotEmpty ? totalSales / bills.length : 0,
    startDate: range.start,
    endDate: range.end,
  );
});

/// Bills for the selected period
final periodBillsProvider = FutureProvider<List<BillModel>>((ref) async {
  final period = ref.watch(selectedPeriodProvider);
  final offset = ref.watch(periodOffsetProvider);
  final customRange = ref.watch(customDateRangeProvider);

  final range = getEffectiveDateRange(period, offset, customRange);
  final bills = await OfflineStorageService.getCachedBillsInRange(
    range.start,
    range.end,
  );
  return bills;
});

/// Top products for the selected period
final topProductsProvider = FutureProvider<List<ProductSale>>((ref) async {
  final period = ref.watch(selectedPeriodProvider);
  final offset = ref.watch(periodOffsetProvider);
  final customRange = ref.watch(customDateRangeProvider);

  final range = getEffectiveDateRange(period, offset, customRange);
  final bills = await OfflineStorageService.getCachedBillsInRange(
    range.start,
    range.end,
  );

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
