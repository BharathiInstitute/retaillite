/// Khata statistics providers for aggregated data
/// Supports demo mode with local in-memory data
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/services/demo_data_service.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/models/customer_model.dart';
import 'package:retaillite/models/transaction_model.dart';

/// Khata statistics model
class KhataStats {
  final double totalOutstanding;
  final double collectedToday;
  final int activeCustomers;
  final int customersWithDue;

  const KhataStats({
    required this.totalOutstanding,
    required this.collectedToday,
    required this.activeCustomers,
    required this.customersWithDue,
  });

  factory KhataStats.empty() => const KhataStats(
    totalOutstanding: 0,
    collectedToday: 0,
    activeCustomers: 0,
    customersWithDue: 0,
  );
}

/// Provider for khata statistics - supports demo mode
final khataStatsProvider = FutureProvider<KhataStats>((ref) async {
  final isDemoMode = ref.watch(isDemoModeProvider);
  debugPrint('📊 khataStatsProvider: isDemoMode=$isDemoMode');

  List<CustomerModel> customers;
  if (isDemoMode) {
    customers = DemoDataService.getCustomers().toList();
  } else {
    customers = await OfflineStorageService.getCachedCustomersAsync();
  }

  // Calculate total outstanding (sum of positive balances)
  final totalOutstanding = customers.fold<double>(
    0,
    (sum, c) => sum + (c.balance > 0 ? c.balance : 0),
  );

  // Count customers with due
  final customersWithDue = customers.where((c) => c.balance > 0).length;

  // Calculate collected today
  double collectedToday = 0;
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);

  for (final customer in customers) {
    List<TransactionModel> transactions;
    if (isDemoMode) {
      transactions = DemoDataService.getCustomerTransactions(customer.id);
    } else {
      transactions = await OfflineStorageService.getCustomerTransactions(
        customer.id,
      );
    }
    for (final tx in transactions) {
      if (tx.type == TransactionType.payment &&
          tx.createdAt.isAfter(startOfDay)) {
        collectedToday += tx.amount;
      }
    }
  }

  debugPrint(
    '📊 KhataStats: ${customers.length} customers, outstanding: $totalOutstanding',
  );

  return KhataStats(
    totalOutstanding: totalOutstanding,
    collectedToday: collectedToday,
    activeCustomers: customers.length,
    customersWithDue: customersWithDue,
  );
});

/// Selected customer provider for master-detail view
final selectedCustomerIdProvider = StateProvider<String?>((ref) => null);

/// Sort option for customer list
enum CustomerSortOption { highestDebt, recentlyActive, alphabetical, oldestDue }

final customerSortProvider = StateProvider<CustomerSortOption>(
  (ref) => CustomerSortOption.highestDebt,
);

/// Sorted and filtered customers provider - supports demo mode
final sortedCustomersProvider = FutureProvider<List<CustomerModel>>((
  ref,
) async {
  final isDemoMode = ref.watch(isDemoModeProvider);
  debugPrint('📋 sortedCustomersProvider: isDemoMode=$isDemoMode');

  List<CustomerModel> customers;
  if (isDemoMode) {
    customers = DemoDataService.getCustomers().toList();
    debugPrint('📋 Got ${customers.length} demo customers');
  } else {
    customers = await OfflineStorageService.getCachedCustomersAsync();
  }

  final sortOption = ref.watch(customerSortProvider);
  final sorted = List<CustomerModel>.from(customers);

  switch (sortOption) {
    case CustomerSortOption.highestDebt:
      sorted.sort((a, b) => b.balance.compareTo(a.balance));
      break;
    case CustomerSortOption.recentlyActive:
      sorted.sort((a, b) {
        final aDate = a.lastTransactionAt ?? DateTime(1970);
        final bDate = b.lastTransactionAt ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });
      break;
    case CustomerSortOption.alphabetical:
      sorted.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      break;
    case CustomerSortOption.oldestDue:
      sorted.sort((a, b) {
        final aDate = a.lastTransactionAt ?? DateTime.now();
        final bDate = b.lastTransactionAt ?? DateTime.now();
        return aDate.compareTo(bDate);
      });
      break;
  }

  return sorted;
});
