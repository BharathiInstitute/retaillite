import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/models/transaction_model.dart';

void main() {
  // ── TransactionType ──

  group('TransactionType.fromString', () {
    test('parses purchase', () {
      expect(TransactionType.fromString('purchase'), TransactionType.purchase);
    });

    test('parses payment', () {
      expect(TransactionType.fromString('payment'), TransactionType.payment);
    });

    test('returns unknown for invalid string', () {
      expect(TransactionType.fromString('invalid'), TransactionType.unknown);
    });

    test('returns unknown for empty string', () {
      expect(TransactionType.fromString(''), TransactionType.unknown);
    });
  });

  group('TransactionType properties', () {
    test('purchase is debit', () {
      expect(TransactionType.purchase.isDebit, isTrue);
    });

    test('payment is not debit', () {
      expect(TransactionType.payment.isDebit, isFalse);
    });

    test('unknown is not debit', () {
      expect(TransactionType.unknown.isDebit, isFalse);
    });

    test('purchase has display name', () {
      expect(TransactionType.purchase.displayName, 'Purchase');
    });

    test('payment has emoji', () {
      expect(TransactionType.payment.emoji, '💵');
    });
  });

  // ── TransactionModel ──

  group('TransactionModel.signedAmount', () {
    test('purchase returns positive amount', () {
      final tx = TransactionModel(
        id: 'tx1',
        customerId: 'c1',
        type: TransactionType.purchase,
        amount: 500,
        createdAt: DateTime.now(),
      );
      expect(tx.signedAmount, 500);
    });

    test('payment returns negative amount', () {
      final tx = TransactionModel(
        id: 'tx2',
        customerId: 'c1',
        type: TransactionType.payment,
        amount: 300,
        createdAt: DateTime.now(),
      );
      expect(tx.signedAmount, -300);
    });

    test('zero amount returns zero', () {
      final tx = TransactionModel(
        id: 'tx3',
        customerId: 'c1',
        type: TransactionType.purchase,
        amount: 0,
        createdAt: DateTime.now(),
      );
      expect(tx.signedAmount, 0);
    });
  });

  group('TransactionModel.toFirestore', () {
    test('serializes all required fields', () {
      final now = DateTime(2026, 1, 30, 10, 30);
      final tx = TransactionModel(
        id: 'tx1',
        customerId: 'c1',
        type: TransactionType.purchase,
        amount: 500,
        createdAt: now,
      );

      final data = tx.toFirestore();
      expect(data['customerId'], 'c1');
      expect(data['type'], 'purchase');
      expect(data['amount'], 500);
      expect(data['createdAt'], isA<Timestamp>());
    });

    test('serializes optional fields when present', () {
      final tx = TransactionModel(
        id: 'tx1',
        customerId: 'c1',
        type: TransactionType.payment,
        amount: 200,
        billId: 'bill_123',
        note: 'Cash payment',
        paymentMode: 'cash',
        createdAt: DateTime.now(),
      );

      final data = tx.toFirestore();
      expect(data['billId'], 'bill_123');
      expect(data['note'], 'Cash payment');
      expect(data['paymentMode'], 'cash');
    });

    test('serializes nulls for missing optional fields', () {
      final tx = TransactionModel(
        id: 'tx1',
        customerId: 'c1',
        type: TransactionType.purchase,
        amount: 100,
        createdAt: DateTime.now(),
      );

      final data = tx.toFirestore();
      expect(data['billId'], isNull);
      expect(data['note'], isNull);
      expect(data['paymentMode'], isNull);
    });

    test('does not include id in Firestore data', () {
      final tx = TransactionModel(
        id: 'tx1',
        customerId: 'c1',
        type: TransactionType.purchase,
        amount: 100,
        createdAt: DateTime.now(),
      );

      final data = tx.toFirestore();
      expect(data.containsKey('id'), isFalse);
    });
  });
}
