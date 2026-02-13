/// Billing providers for managing bills and expenses data state
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/services/demo_data_service.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/models/bill_model.dart';
import 'package:retaillite/models/expense_model.dart';

/// Record type for filtering
enum RecordType { all, bills, expenses }

/// Filter state for bills and expenses
class BillsFilter {
  final String searchQuery;
  final DateTimeRange? dateRange;
  final PaymentMethod? paymentMethod;
  final RecordType recordType;
  final int page;
  final int perPage;

  const BillsFilter({
    this.searchQuery = '',
    this.dateRange,
    this.paymentMethod,
    this.recordType = RecordType.all,
    this.page = 1,
    this.perPage = 10,
  });

  BillsFilter copyWith({
    String? searchQuery,
    DateTimeRange? dateRange,
    PaymentMethod? paymentMethod,
    RecordType? recordType,
    int? page,
    int? perPage,
    bool clearDateRange = false,
    bool clearPaymentMethod = false,
  }) {
    return BillsFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      paymentMethod: clearPaymentMethod
          ? null
          : (paymentMethod ?? this.paymentMethod),
      recordType: recordType ?? this.recordType,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
    );
  }
}

/// Bills filter provider
final billsFilterProvider = StateProvider<BillsFilter>((ref) {
  return const BillsFilter();
});

/// Filtered expenses provider
final filteredExpensesProvider = FutureProvider<List<ExpenseModel>>((
  ref,
) async {
  final filter = ref.watch(billsFilterProvider);
  final isDemoMode = ref.watch(authNotifierProvider).isDemoMode;

  List<ExpenseModel> expenses;
  if (isDemoMode) {
    expenses = List.of(DemoDataService.getExpenses());
  } else {
    expenses = await OfflineStorageService.getCachedExpensesAsync();
  }

  // Sort by date descending
  expenses.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  // Apply search filter
  if (filter.searchQuery.isNotEmpty) {
    final query = filter.searchQuery.toLowerCase();
    expenses = expenses.where((exp) {
      final desc = (exp.description ?? '').toLowerCase();
      final cat = exp.category.displayName.toLowerCase();
      return desc.contains(query) || cat.contains(query);
    }).toList();
  }

  // Apply date range filter
  if (filter.dateRange != null) {
    expenses = expenses.where((exp) {
      return exp.createdAt.isAfter(filter.dateRange!.start) &&
          exp.createdAt.isBefore(
            filter.dateRange!.end.add(const Duration(days: 1)),
          );
    }).toList();
  }

  // Apply payment method filter
  if (filter.paymentMethod != null) {
    expenses = expenses
        .where((exp) => exp.paymentMethod == filter.paymentMethod)
        .toList();
  }

  return expenses;
});

/// Filtered bills provider
final filteredBillsProvider = FutureProvider<List<BillModel>>((ref) async {
  final filter = ref.watch(billsFilterProvider);
  final isDemoMode = ref.watch(authNotifierProvider).isDemoMode;

  List<BillModel> bills;
  if (isDemoMode) {
    bills = List.of(DemoDataService.getBills());
  } else {
    bills = await OfflineStorageService.getCachedBillsAsync();
  }

  // Sort by date descending (newest first)
  bills.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  // Apply search filter
  if (filter.searchQuery.isNotEmpty) {
    final query = filter.searchQuery.toLowerCase();
    bills = bills.where((bill) {
      final billNo = '#INV-${bill.billNumber}'.toLowerCase();
      final customerName = (bill.customerName ?? 'Walk-in').toLowerCase();
      return billNo.contains(query) || customerName.contains(query);
    }).toList();
  }

  // Apply date range filter
  if (filter.dateRange != null) {
    bills = bills.where((bill) {
      return bill.createdAt.isAfter(filter.dateRange!.start) &&
          bill.createdAt.isBefore(
            filter.dateRange!.end.add(const Duration(days: 1)),
          );
    }).toList();
  }

  // Apply payment method filter
  if (filter.paymentMethod != null) {
    bills = bills
        .where((bill) => bill.paymentMethod == filter.paymentMethod)
        .toList();
  }

  return bills;
});
