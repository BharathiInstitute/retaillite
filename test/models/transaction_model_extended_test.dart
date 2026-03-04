/// Extended TransactionModel tests — copyWith, edge cases
library;

import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_factories.dart';
import 'package:retaillite/models/transaction_model.dart';

void main() {
  // ── TransactionModel.copyWith ──

  group('TransactionModel.copyWith', () {
    test('preserves all fields when no args', () {
      final t = makeTransaction(
        customerId: 'c1',
        type: TransactionType.purchase,
        billId: 'bill-1',
        note: 'Monthly supply',
      );
      final copy = t.copyWith();
      expect(copy.id, 'txn-1');
      expect(copy.customerId, 'c1');
      expect(copy.type, TransactionType.purchase);
      expect(copy.amount, 500);
      expect(copy.billId, 'bill-1');
      expect(copy.note, 'Monthly supply');
      expect(copy.paymentMode, 'cash');
      expect(copy.createdAt, t.createdAt);
    });

    test('overrides id', () {
      final t = makeTransaction();
      final copy = t.copyWith(id: 'txn-2');
      expect(copy.id, 'txn-2');
    });

    test('overrides type', () {
      final t = makeTransaction(type: TransactionType.purchase);
      final copy = t.copyWith(type: TransactionType.payment);
      expect(copy.type, TransactionType.payment);
    });

    test('overrides amount', () {
      final t = makeTransaction(amount: 100);
      final copy = t.copyWith(amount: 200);
      expect(copy.amount, 200);
    });

    test('overrides billId and note', () {
      final t = makeTransaction();
      final copy = t.copyWith(billId: 'b-new', note: 'Updated note');
      expect(copy.billId, 'b-new');
      expect(copy.note, 'Updated note');
    });

    test('overrides paymentMode', () {
      final t = makeTransaction();
      final copy = t.copyWith(paymentMode: 'upi');
      expect(copy.paymentMode, 'upi');
    });

    test('overrides createdAt', () {
      final t = makeTransaction();
      final newDate = DateTime(2025);
      final copy = t.copyWith(createdAt: newDate);
      expect(copy.createdAt, newDate);
    });
  });

  // ── signedAmount edge cases ──

  group('TransactionModel.signedAmount edge cases', () {
    test('purchase with zero amount', () {
      final t = makeTransaction(type: TransactionType.purchase, amount: 0);
      expect(t.signedAmount, 0);
    });

    test('payment with zero amount', () {
      final t = makeTransaction(amount: 0);
      expect(t.signedAmount, 0);
    });

    test('unknown type not debit', () {
      final t = makeTransaction(type: TransactionType.unknown, amount: 100);
      expect(t.signedAmount, -100);
    });

    test('large amount', () {
      final t = makeTransaction(
        type: TransactionType.purchase,
        amount: 9999999.99,
      );
      expect(t.signedAmount, 9999999.99);
    });
  });

  // ── TransactionType additional ──

  group('TransactionType', () {
    test('unknown has correct properties', () {
      expect(TransactionType.unknown.displayName, 'Unknown');
      expect(TransactionType.unknown.emoji, '❓');
      expect(TransactionType.unknown.isDebit, false);
    });

    test('purchase is debit, payment is not', () {
      expect(TransactionType.purchase.isDebit, true);
      expect(TransactionType.payment.isDebit, false);
    });

    test('fromString is case-sensitive', () {
      expect(TransactionType.fromString('Purchase'), TransactionType.unknown);
      expect(TransactionType.fromString('purchase'), TransactionType.purchase);
    });
  });
}
