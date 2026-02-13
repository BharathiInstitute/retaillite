import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/models/customer_model.dart';
import 'package:retaillite/models/transaction_model.dart';

void main() {
  group('CustomerModel', () {
    test('should create customer with required fields', () {
      final customer = CustomerModel(
        id: 'cust-1',
        name: 'Test Customer',
        phone: '9876543210',
        balance: 500.0,
        createdAt: DateTime(2024),
      );

      expect(customer.id, 'cust-1');
      expect(customer.name, 'Test Customer');
      expect(customer.phone, '9876543210');
      expect(customer.balance, 500.0);
    });

    test('should detect due correctly', () {
      final customerWithDue = CustomerModel(
        id: 'cust-1',
        name: 'Test Customer',
        phone: '9876543210',
        balance: 500.0,
        createdAt: DateTime(2024),
      );

      final customerPaid = CustomerModel(
        id: 'cust-2',
        name: 'Test Customer 2',
        phone: '9876543211',
        createdAt: DateTime(2024),
      );

      expect(customerWithDue.hasDue, true);
      expect(customerPaid.hasDue, false);
    });

    test('should calculate days since last transaction', () {
      final now = DateTime.now();
      final customer = CustomerModel(
        id: 'cust-1',
        name: 'Test Customer',
        phone: '9876543210',
        balance: 500.0,
        createdAt: DateTime(2024),
        lastTransactionAt: now.subtract(const Duration(days: 5)),
      );

      expect(customer.daysSinceLastTransaction, 5);
    });

    test('should detect overdue customer', () {
      final now = DateTime.now();
      final overdueCustomer = CustomerModel(
        id: 'cust-1',
        name: 'Test Customer',
        phone: '9876543210',
        balance: 500.0,
        createdAt: DateTime(2024),
        lastTransactionAt: now.subtract(const Duration(days: 35)),
      );

      expect(overdueCustomer.isOverdue, true);
    });

    test('should serialize to Firestore correctly', () {
      final customer = CustomerModel(
        id: 'cust-1',
        name: 'Test Customer',
        phone: '9876543210',
        address: '123 Test Street',
        balance: 500.0,
        createdAt: DateTime(2024),
      );

      final map = customer.toFirestore();

      expect(map['name'], 'Test Customer');
      expect(map['phone'], '9876543210');
      expect(map['address'], '123 Test Street');
      expect(map['balance'], 500.0);
    });
  });

  group('TransactionModel', () {
    test('should create transaction with required fields', () {
      final transaction = TransactionModel(
        id: 'txn-1',
        customerId: 'cust-1',
        type: TransactionType.purchase,
        amount: 500.0,
        createdAt: DateTime(2024),
      );

      expect(transaction.id, 'txn-1');
      expect(transaction.customerId, 'cust-1');
      expect(transaction.type, TransactionType.purchase);
      expect(transaction.amount, 500.0);
    });

    test('should calculate signed amount correctly', () {
      final purchase = TransactionModel(
        id: 'txn-1',
        customerId: 'cust-1',
        type: TransactionType.purchase,
        amount: 500.0,
        createdAt: DateTime(2024),
      );

      final payment = TransactionModel(
        id: 'txn-2',
        customerId: 'cust-1',
        type: TransactionType.payment,
        amount: 300.0,
        createdAt: DateTime(2024),
      );

      expect(purchase.signedAmount, 500.0); // Positive for purchase
      expect(payment.signedAmount, -300.0); // Negative for payment
    });

    test('should serialize to Firestore correctly', () {
      final transaction = TransactionModel(
        id: 'txn-1',
        customerId: 'cust-1',
        type: TransactionType.payment,
        amount: 500.0,
        note: 'Test payment',
        billId: 'bill-1',
        createdAt: DateTime(2024),
      );

      final map = transaction.toFirestore();

      expect(map['customerId'], 'cust-1');
      expect(map['type'], 'payment');
      expect(map['amount'], 500.0);
      expect(map['note'], 'Test payment');
      expect(map['billId'], 'bill-1');
    });
  });

  group('TransactionType', () {
    test('should have correct display names', () {
      expect(TransactionType.purchase.displayName, 'Purchase');
      expect(TransactionType.payment.displayName, 'Payment');
    });

    test('should parse from string correctly', () {
      expect(TransactionType.fromString('purchase'), TransactionType.purchase);
      expect(TransactionType.fromString('payment'), TransactionType.payment);
    });
  });
}
