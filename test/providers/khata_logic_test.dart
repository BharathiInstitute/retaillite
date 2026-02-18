/// Tests for Khata (credit book) business logic
///
/// Tests pure model logic: customer balance tracking, overdue detection,
/// transaction signed amounts, and credit/payment flow simulation.
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/models/customer_model.dart';
import 'package:retaillite/models/transaction_model.dart';

void main() {
  group('CustomerModel', () {
    test('should create customer with default balance 0', () {
      final customer = CustomerModel(
        id: 'c1',
        name: 'Rahul Sharma',
        phone: '9876543210',
        createdAt: DateTime(2024),
      );

      expect(customer.balance, 0);
      expect(customer.hasDue, false);
    });

    test('hasDue should be true when balance > 0', () {
      final customer = CustomerModel(
        id: 'c1',
        name: 'Rahul',
        phone: '9876543210',
        balance: 500,
        createdAt: DateTime(2024),
      );

      expect(customer.hasDue, true);
    });

    test('hasDue should be false when balance = 0 or negative', () {
      final zeroBalance = CustomerModel(
        id: 'c1',
        name: 'Test',
        phone: '9876543210',
        balance: 0,
        createdAt: DateTime(2024),
      );
      expect(zeroBalance.hasDue, false);

      final negativeBalance = CustomerModel(
        id: 'c1',
        name: 'Test',
        phone: '9876543210',
        balance: -100, // overpaid
        createdAt: DateTime(2024),
      );
      expect(negativeBalance.hasDue, false);
    });

    test('daysSinceLastTransaction returns null when no transaction', () {
      final customer = CustomerModel(
        id: 'c1',
        name: 'Test',
        phone: '9876543210',
        createdAt: DateTime(2024),
      );

      expect(customer.daysSinceLastTransaction, isNull);
    });

    test('isOverdue should be true when > 30 days since last transaction', () {
      final customer = CustomerModel(
        id: 'c1',
        name: 'Test',
        phone: '9876543210',
        balance: 500,
        createdAt: DateTime(2024),
        lastTransactionAt: DateTime.now().subtract(const Duration(days: 45)),
      );

      expect(customer.isOverdue, true);
    });

    test('isOverdue should be false when < 30 days', () {
      final customer = CustomerModel(
        id: 'c1',
        name: 'Test',
        phone: '9876543210',
        balance: 500,
        createdAt: DateTime(2024),
        lastTransactionAt: DateTime.now().subtract(const Duration(days: 10)),
      );

      expect(customer.isOverdue, false);
    });

    test('isOverdue should be false when no transaction history', () {
      final customer = CustomerModel(
        id: 'c1',
        name: 'Test',
        phone: '9876543210',
        createdAt: DateTime(2024),
      );

      expect(customer.isOverdue, false);
    });

    test('copyWith should update specified fields', () {
      final customer = CustomerModel(
        id: 'c1',
        name: 'Old Name',
        phone: '9876543210',
        balance: 100,
        createdAt: DateTime(2024),
      );

      final updated = customer.copyWith(name: 'New Name', balance: 200);

      expect(updated.id, 'c1'); // unchanged
      expect(updated.name, 'New Name');
      expect(updated.phone, '9876543210'); // unchanged
      expect(updated.balance, 200);
      expect(updated.updatedAt, isNotNull);
    });

    test('copyWith preserves original fields when not specified', () {
      final customer = CustomerModel(
        id: 'c1',
        name: 'Name',
        phone: '9876543210',
        address: 'Old Address',
        balance: 100,
        createdAt: DateTime(2024),
      );

      final updated = customer.copyWith(name: 'New Name');

      expect(updated.address, 'Old Address');
      expect(updated.balance, 100);
    });
  });

  group('TransactionModel', () {
    test('purchase should have positive signedAmount', () {
      final txn = TransactionModel(
        id: 't1',
        customerId: 'c1',
        type: TransactionType.purchase,
        amount: 500,
        createdAt: DateTime(2024),
      );

      expect(txn.signedAmount, 500);
    });

    test('payment should have negative signedAmount', () {
      final txn = TransactionModel(
        id: 't1',
        customerId: 'c1',
        type: TransactionType.payment,
        amount: 300,
        createdAt: DateTime(2024),
      );

      expect(txn.signedAmount, -300);
    });

    test('purchase isDebit=true, payment isDebit=false', () {
      expect(TransactionType.purchase.isDebit, true);
      expect(TransactionType.payment.isDebit, false);
    });

    test('TransactionType display names', () {
      expect(TransactionType.purchase.displayName, 'Purchase');
      expect(TransactionType.payment.displayName, 'Payment');
    });

    test('TransactionType fromString handles unknown', () {
      expect(TransactionType.fromString('invalid'), TransactionType.unknown);
    });

    test('TransactionType fromString parses valid types', () {
      expect(TransactionType.fromString('purchase'), TransactionType.purchase);
      expect(TransactionType.fromString('payment'), TransactionType.payment);
    });
  });

  group('Khata business logic — balance tracking simulation', () {
    // Simulates credit/payment flow without Firebase
    test('credit purchase increases balance, payment decreases it', () {
      double balance = 0;

      // Customer buys ₹500 on credit
      balance += 500;
      expect(balance, 500);

      // Customer buys ₹300 more
      balance += 300;
      expect(balance, 800);

      // Customer pays ₹500
      balance -= 500;
      expect(balance, 300);

      // Customer pays remaining ₹300
      balance -= 300;
      expect(balance, 0);
    });

    test('multiple transactions compute correct final balance', () {
      final transactions = [
        TransactionModel(
          id: '1',
          customerId: 'c1',
          type: TransactionType.purchase,
          amount: 1000,
          createdAt: DateTime(2024, 1, 1),
        ),
        TransactionModel(
          id: '2',
          customerId: 'c1',
          type: TransactionType.payment,
          amount: 400,
          createdAt: DateTime(2024, 1, 5),
        ),
        TransactionModel(
          id: '3',
          customerId: 'c1',
          type: TransactionType.purchase,
          amount: 200,
          createdAt: DateTime(2024, 1, 10),
        ),
        TransactionModel(
          id: '4',
          customerId: 'c1',
          type: TransactionType.payment,
          amount: 800,
          createdAt: DateTime(2024, 1, 15),
        ),
      ];

      // Calculate balance from transactions
      final balance = transactions.fold<double>(
        0,
        (sum, txn) => sum + txn.signedAmount,
      );

      // 1000 - 400 + 200 - 800 = 0
      expect(balance, 0);
    });

    test('sort transactions by date descending', () {
      final transactions = [
        TransactionModel(
          id: '1',
          customerId: 'c1',
          type: TransactionType.purchase,
          amount: 100,
          createdAt: DateTime(2024, 1, 1),
        ),
        TransactionModel(
          id: '2',
          customerId: 'c1',
          type: TransactionType.payment,
          amount: 50,
          createdAt: DateTime(2024, 2, 1),
        ),
      ];

      transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      expect(transactions.first.id, '2'); // February first
    });
  });
}
