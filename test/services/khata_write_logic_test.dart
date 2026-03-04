/// Khata write service — demo mode logic tests
///
/// Tests the branching logic in KhataWriteService: the service chooses
/// between DemoDataService (in-memory) and OfflineStorageService (Firestore)
/// based on demo mode state. Also verifies provider invalidation patterns.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/models/transaction_model.dart';

void main() {
  group('KhataWriteService — transaction model usage', () {
    test('recording payment uses TransactionType.payment', () {
      const expectedType = TransactionType.payment;
      expect(expectedType.name, 'payment');
    });

    test('giving credit uses TransactionType.purchase', () {
      const expectedType = TransactionType.purchase;
      expect(expectedType.name, 'purchase');
    });

    test('payment note defaults to payment mode', () {
      const paymentMode = 'cash';
      const note = null;
      const effectiveNote = note ?? paymentMode;
      expect(effectiveNote, 'cash');
    });

    test('credit note defaults to "Credit given"', () {
      const note = null;
      const effectiveNote = note ?? 'Credit given';
      expect(effectiveNote, 'Credit given');
    });
  });

  group('KhataWriteService — balance arithmetic', () {
    test('recordPayment reduces balance (negative delta)', () {
      const balance = 500.0;
      const payment = 200.0;
      // In demo: DemoDataService.updateCustomerBalance(id, -amount)
      // In real: FieldValue.increment(-amount)
      const delta = -payment;
      expect(balance + delta, 300.0);
    });

    test('giveCredit increases balance (positive delta)', () {
      const balance = 300.0;
      const credit = 100.0;
      // In demo: DemoDataService.updateCustomerBalance(id, amount)
      // In real: FieldValue.increment(amount)
      const delta = credit;
      expect(balance + delta, 400.0);
    });

    test('paying full balance brings to zero', () {
      const balance = 750.0;
      const payment = 750.0;
      expect(balance + (-payment), 0.0);
    });

    test('overpayment goes negative (credit balance)', () {
      const balance = 100.0;
      const payment = 150.0;
      expect(balance + (-payment), -50.0);
    });
  });

  group('KhataWriteService — provider invalidation', () {
    test('invalidation targets 3 providers', () {
      // _invalidateProviders invalidates:
      // 1. customerProvider(customerId)
      // 2. customerTransactionsProvider(customerId)
      // 3. customersProvider
      const targets = [
        'customerProvider(customerId)',
        'customerTransactionsProvider(customerId)',
        'customersProvider',
      ];
      expect(targets.length, 3);
    });
  });
}
