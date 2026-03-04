/// Consolidated Khata write service (2.14)
/// Extracts shared demo/real branching + provider invalidation patterns
/// from RecordPaymentModal and GiveUdhaarModal.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/services/demo_data_service.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/features/khata/providers/khata_provider.dart';
import 'package:retaillite/models/transaction_model.dart';

/// Shared service for Khata write operations (payment + credit).
class KhataWriteService {
  /// Record a payment (reduces customer balance).
  static Future<void> recordPayment({
    required WidgetRef ref,
    required String customerId,
    required double amount,
    required String paymentMode,
    String? note,
  }) async {
    final isDemoMode = ref.read(isDemoModeProvider);

    if (isDemoMode) {
      DemoDataService.updateCustomerBalance(customerId, -amount);
      DemoDataService.addTransaction(
        customerId: customerId,
        type: TransactionType.payment,
        amount: amount,
        note: note ?? paymentMode,
      );
    } else {
      await OfflineStorageService.recordPaymentAtomic(
        customerId: customerId,
        amount: amount,
        paymentMode: paymentMode,
        note: note,
      );
    }

    _invalidateProviders(ref, customerId);
  }

  /// Give credit/udhaar (increases customer balance).
  static Future<void> giveCredit({
    required WidgetRef ref,
    required String customerId,
    required double amount,
    String? note,
  }) async {
    final isDemoMode = ref.read(isDemoModeProvider);

    if (isDemoMode) {
      DemoDataService.updateCustomerBalance(customerId, amount);
      DemoDataService.addTransaction(
        customerId: customerId,
        type: TransactionType.purchase,
        amount: amount,
        note: note ?? 'Credit given',
      );
    } else {
      await OfflineStorageService.addCreditAtomic(
        customerId: customerId,
        amount: amount,
        note: note,
      );
    }

    _invalidateProviders(ref, customerId);
  }

  /// Invalidate all relevant Khata providers after a write.
  static void _invalidateProviders(WidgetRef ref, String customerId) {
    ref.invalidate(customerProvider(customerId));
    ref.invalidate(customerTransactionsProvider(customerId));
    ref.invalidate(customersProvider);
  }
}
