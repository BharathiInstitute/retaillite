/// Khata providers for customers and transactions (Firestore-based)
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';
import 'package:retaillite/models/customer_model.dart';
import 'package:retaillite/models/transaction_model.dart';

/// Customers list provider - reads from Firestore (async)
final customersProvider = FutureProvider<List<CustomerModel>>((ref) async {
  final customers = await OfflineStorageService.getCachedCustomersAsync();
  return customers;
});

/// Single customer provider - reads from Firestore (async)
final customerProvider = FutureProvider.family<CustomerModel?, String>((
  ref,
  customerId,
) async {
  final customer = await OfflineStorageService.getCachedCustomerAsync(
    customerId,
  );
  return customer;
});

/// Customer transactions provider - reads from Firestore (async)
final customerTransactionsProvider =
    FutureProvider.family<List<TransactionModel>, String>((
      ref,
      customerId,
    ) async {
      final transactions = await OfflineStorageService.getCustomerTransactions(
        customerId,
      );
      return transactions;
    });

/// Khata service for local CRUD operations
class KhataService {
  /// Add new customer
  Future<String> addCustomer(CustomerModel customer) async {
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
    await OfflineStorageService.saveCustomer(customer);
  }

  /// Record payment from customer
  Future<void> recordPayment({
    required String customerId,
    required double amount,
    String? note,
    String paymentMode = 'cash',
  }) async {
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
    await OfflineStorageService.deleteCustomer(customerId);
  }
}

/// Khata service provider (singleton)
final khataServiceProvider = Provider<KhataService>((ref) {
  return KhataService();
});
