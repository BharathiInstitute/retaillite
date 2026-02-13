/// Khata providers for customers and transactions
/// Supports demo mode with local in-memory data
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/services/demo_data_service.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/models/customer_model.dart';
import 'package:retaillite/models/transaction_model.dart';

/// Customers list provider - reads from demo data or Firestore
final customersProvider = FutureProvider<List<CustomerModel>>((ref) async {
  final isDemoMode = ref.watch(isDemoModeProvider);
  debugPrint(
    '🧾 customersProvider: isDemoMode=$isDemoMode, DemoDataService.isLoaded=${DemoDataService.isLoaded}',
  );

  if (isDemoMode) {
    final customers = DemoDataService.getCustomers().toList();
    debugPrint('🧾 Returning ${customers.length} demo customers');
    return customers;
  }

  final customers = await OfflineStorageService.getCachedCustomersAsync();
  return customers;
});

/// Single customer provider - reads from demo data or Firestore
final customerProvider = FutureProvider.family<CustomerModel?, String>((
  ref,
  customerId,
) async {
  final isDemoMode = ref.watch(isDemoModeProvider);

  if (isDemoMode) {
    return DemoDataService.getCustomer(customerId);
  }

  final customer = await OfflineStorageService.getCachedCustomerAsync(
    customerId,
  );
  return customer;
});

/// Customer transactions provider - reads from demo data or Firestore
final customerTransactionsProvider =
    FutureProvider.family<List<TransactionModel>, String>((
      ref,
      customerId,
    ) async {
      final isDemoMode = ref.watch(isDemoModeProvider);

      if (isDemoMode) {
        return DemoDataService.getCustomerTransactions(customerId);
      }

      final transactions = await OfflineStorageService.getCustomerTransactions(
        customerId,
      );
      return transactions;
    });

/// Khata service for CRUD operations
/// Automatically routes to demo data or Firestore based on mode
class KhataService {
  final bool _isDemoMode;

  KhataService({required bool isDemoMode}) : _isDemoMode = isDemoMode;

  /// Add new customer
  Future<String> addCustomer(CustomerModel customer) async {
    if (_isDemoMode) {
      return DemoDataService.addCustomer(customer);
    }

    final id = 'customer_${DateTime.now().millisecondsSinceEpoch}';
    final newCustomer = CustomerModel(
      id: id,
      name: customer.name,
      phone: customer.phone,
      address: customer.address,
      balance: customer.balance,
      createdAt: DateTime.now(),
    );
    await OfflineStorageService.saveCustomer(newCustomer);
    return id;
  }

  /// Update customer
  Future<void> updateCustomer(CustomerModel customer) async {
    if (_isDemoMode) {
      DemoDataService.updateCustomer(customer);
      return;
    }
    await OfflineStorageService.saveCustomer(customer);
  }

  /// Record payment from customer
  Future<void> recordPayment({
    required String customerId,
    required double amount,
    String? note,
    String paymentMode = 'cash',
  }) async {
    if (_isDemoMode) {
      // Update customer balance (subtract payment)
      DemoDataService.updateCustomerBalance(customerId, -amount);
      // Add transaction
      DemoDataService.addTransaction(
        customerId: customerId,
        type: TransactionType.payment,
        amount: amount,
        note: note ?? paymentMode,
      );
      return;
    }

    // Update customer balance (subtract payment)
    await OfflineStorageService.updateCustomerBalance(customerId, -amount);

    // Save payment transaction
    await OfflineStorageService.saveTransaction(
      customerId: customerId,
      type: 'payment',
      amount: amount,
      note: note ?? paymentMode,
    );
  }

  /// Add credit (udhar) for customer
  Future<void> addCredit({
    required String customerId,
    required double amount,
    String? billId,
  }) async {
    if (_isDemoMode) {
      // Update customer balance
      DemoDataService.updateCustomerBalance(customerId, amount);
      // Add transaction
      DemoDataService.addTransaction(
        customerId: customerId,
        type: TransactionType.purchase,
        amount: amount,
        billId: billId,
      );
      return;
    }

    // Update customer balance
    await OfflineStorageService.updateCustomerBalance(customerId, amount);

    // Save purchase transaction
    await OfflineStorageService.saveTransaction(
      customerId: customerId,
      type: 'purchase',
      amount: amount,
      billId: billId,
    );
  }

  /// Delete customer
  Future<void> deleteCustomer(String customerId) async {
    if (_isDemoMode) {
      DemoDataService.deleteCustomer(customerId);
      return;
    }
    await OfflineStorageService.deleteCustomer(customerId);
  }
}

/// Khata service provider - auto-detects demo mode
final khataServiceProvider = Provider<KhataService>((ref) {
  final isDemoMode = ref.watch(isDemoModeProvider);
  return KhataService(isDemoMode: isDemoMode);
});
