/// Billing service for bills
/// Supports demo mode with local in-memory data
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/services/demo_data_service.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/models/bill_model.dart';

/// Today's bills provider - reads from demo data or Firestore
final todayBillsProvider = FutureProvider<List<BillModel>>((ref) async {
  final isDemoMode = ref.watch(isDemoModeProvider);
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  if (isDemoMode) {
    return DemoDataService.getBillsInRange(startOfDay, endOfDay);
  }

  final bills = await OfflineStorageService.getCachedBillsInRange(
    startOfDay,
    endOfDay,
  );
  return bills;
});

/// Today's summary provider
final todaySummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final isDemoMode = ref.watch(isDemoModeProvider);
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  List<BillModel> todayBills;
  if (isDemoMode) {
    todayBills = DemoDataService.getBillsInRange(startOfDay, endOfDay);
  } else {
    todayBills = await OfflineStorageService.getCachedBillsInRange(
      startOfDay,
      endOfDay,
    );
  }

  double totalSales = 0;
  double cashAmount = 0;
  double upiAmount = 0;
  double udharAmount = 0;

  for (final bill in todayBills) {
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

  return {
    'totalSales': totalSales,
    'billCount': todayBills.length,
    'cashAmount': cashAmount,
    'upiAmount': upiAmount,
    'udharAmount': udharAmount,
  };
});
