/// Billing service for local bills (Firestore-based storage)
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';
import 'package:retaillite/models/bill_model.dart';

/// Today's bills provider - reads from Firestore storage (async)
final todayBillsProvider = FutureProvider<List<BillModel>>((ref) async {
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  final bills = await OfflineStorageService.getCachedBillsInRange(
    startOfDay,
    endOfDay,
  );
  return bills;
});

/// Today's summary provider
final todaySummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  final todayBills = await OfflineStorageService.getCachedBillsInRange(
    startOfDay,
    endOfDay,
  );

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
