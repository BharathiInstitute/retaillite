import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/services/demo_data_service.dart';
import 'package:retaillite/models/bill_model.dart';
import 'package:retaillite/models/customer_model.dart';
import 'package:retaillite/models/expense_model.dart';
import 'package:retaillite/models/product_model.dart';
import 'package:retaillite/models/transaction_model.dart';

void main() {
  setUp(() {
    // Always start fresh
    DemoDataService.clearDemoData();
  });

  // ── Initialization ──

  group('Initialization', () {
    test('isLoaded is false initially', () {
      expect(DemoDataService.isLoaded, isFalse);
    });

    test('loadDemoData sets isLoaded to true', () {
      DemoDataService.loadDemoData();
      expect(DemoDataService.isLoaded, isTrue);
    });

    test('clearDemoData resets isLoaded', () {
      DemoDataService.loadDemoData();
      DemoDataService.clearDemoData();
      expect(DemoDataService.isLoaded, isFalse);
    });

    test('loadDemoData is idempotent', () {
      DemoDataService.loadDemoData();
      final count1 = DemoDataService.getProducts().length;
      DemoDataService.loadDemoData(); // second call
      final count2 = DemoDataService.getProducts().length;
      expect(count1, count2);
    });
  });

  // ── Products ──

  group('Products', () {
    setUp(() {
      DemoDataService.loadDemoData();
    });

    test('getProducts returns non-empty list', () {
      expect(DemoDataService.getProducts(), isNotEmpty);
    });

    test('getProducts returns at least 10 products', () {
      expect(DemoDataService.getProducts().length, greaterThanOrEqualTo(10));
    });

    test('getProduct by valid ID returns product', () {
      final product = DemoDataService.getProduct('demo_prod_1');
      expect(product, isNotNull);
      expect(product!.id, 'demo_prod_1');
    });

    test('getProduct by invalid ID returns null', () {
      expect(DemoDataService.getProduct('non_existent'), isNull);
    });

    test('getProductByBarcode with valid barcode', () {
      final products = DemoDataService.getProducts();
      final withBarcode = products.where((p) => p.barcode != null).toList();
      if (withBarcode.isNotEmpty) {
        final found = DemoDataService.getProductByBarcode(
          withBarcode.first.barcode!,
        );
        expect(found, isNotNull);
        expect(found!.id, withBarcode.first.id);
      }
    });

    test('getProductByBarcode with invalid barcode returns null', () {
      expect(DemoDataService.getProductByBarcode('0000000000'), isNull);
    });

    test('addProduct returns ID and adds to list', () {
      final initialCount = DemoDataService.getProducts().length;
      final product = ProductModel(
        id: 'temp',
        name: 'Test Product',
        price: 99,
        stock: 50,
        createdAt: DateTime.now(),
      );
      final id = DemoDataService.addProduct(product);
      expect(id, startsWith('demo_prod_'));
      expect(DemoDataService.getProducts().length, initialCount + 1);
      expect(DemoDataService.getProduct(id), isNotNull);
    });

    test('updateProduct modifies existing product', () {
      final original = DemoDataService.getProduct('demo_prod_1')!;
      final updated = original.copyWith(name: 'Updated Rice');
      DemoDataService.updateProduct(updated);
      expect(DemoDataService.getProduct('demo_prod_1')!.name, 'Updated Rice');
    });

    test('deleteProduct removes product', () {
      final initialCount = DemoDataService.getProducts().length;
      DemoDataService.deleteProduct('demo_prod_1');
      expect(DemoDataService.getProducts().length, initialCount - 1);
      expect(DemoDataService.getProduct('demo_prod_1'), isNull);
    });

    test('updateStock changes stock value', () {
      DemoDataService.updateStock('demo_prod_1', 999);
      expect(DemoDataService.getProduct('demo_prod_1')!.stock, 999);
    });

    test('decrementStock reduces stock', () {
      final original = DemoDataService.getProduct('demo_prod_1')!.stock;
      DemoDataService.decrementStock('demo_prod_1', 5);
      expect(DemoDataService.getProduct('demo_prod_1')!.stock, original - 5);
    });
  });

  // ── Customers ──

  group('Customers', () {
    setUp(() {
      DemoDataService.loadDemoData();
    });

    test('getCustomers returns non-empty list', () {
      expect(DemoDataService.getCustomers(), isNotEmpty);
    });

    test('getCustomer by valid ID', () {
      final customer = DemoDataService.getCustomer('demo_cust_1');
      expect(customer, isNotNull);
      expect(customer!.name, isNotEmpty);
    });

    test('getCustomer by invalid ID returns null', () {
      expect(DemoDataService.getCustomer('non_existent'), isNull);
    });

    test('addCustomer returns ID and adds to list', () {
      final initialCount = DemoDataService.getCustomers().length;
      final customer = CustomerModel(
        id: 'temp',
        name: 'New Customer',
        phone: '9876543210',
        createdAt: DateTime.now(),
      );
      final id = DemoDataService.addCustomer(customer);
      expect(id, startsWith('demo_cust_'));
      expect(DemoDataService.getCustomers().length, initialCount + 1);
    });

    test('updateCustomer modifies existing', () {
      final original = DemoDataService.getCustomer('demo_cust_1')!;
      final updated = CustomerModel(
        id: original.id,
        name: 'Updated Name',
        phone: original.phone,
        balance: original.balance,
        createdAt: original.createdAt,
      );
      DemoDataService.updateCustomer(updated);
      expect(DemoDataService.getCustomer('demo_cust_1')!.name, 'Updated Name');
    });

    test('deleteCustomer removes customer and transactions', () {
      final initialCustomers = DemoDataService.getCustomers().length;
      DemoDataService.deleteCustomer('demo_cust_1');
      expect(DemoDataService.getCustomers().length, initialCustomers - 1);
      expect(DemoDataService.getCustomerTransactions('demo_cust_1'), isEmpty);
    });

    test('updateCustomerBalance adds to balance', () {
      final original = DemoDataService.getCustomer('demo_cust_1')!.balance;
      DemoDataService.updateCustomerBalance('demo_cust_1', 500);
      expect(
        DemoDataService.getCustomer('demo_cust_1')!.balance,
        original + 500,
      );
    });

    test('updateCustomerBalance subtracts from balance', () {
      final original = DemoDataService.getCustomer('demo_cust_1')!.balance;
      DemoDataService.updateCustomerBalance('demo_cust_1', -200);
      expect(
        DemoDataService.getCustomer('demo_cust_1')!.balance,
        original - 200,
      );
    });

    // ── Khata balance scenarios (KHAT-004/005/006) ──

    test('partial payment reduces balance (KHAT-005)', () {
      // Set a known balance first
      final cust = DemoDataService.getCustomer('demo_cust_1')!;
      final initialBalance = cust.balance;
      // Add 1000 debt
      DemoDataService.updateCustomerBalance('demo_cust_1', 1000);
      expect(
        DemoDataService.getCustomer('demo_cust_1')!.balance,
        initialBalance + 1000,
      );
      // Pay 500 — balance should be initial + 500
      DemoDataService.updateCustomerBalance('demo_cust_1', -500);
      expect(
        DemoDataService.getCustomer('demo_cust_1')!.balance,
        initialBalance + 500,
      );
    });

    test('full payment clears balance to 0 (KHAT-006)', () {
      // Set balance to exactly 1000
      final cust = DemoDataService.getCustomer('demo_cust_1')!;
      final currentBalance = cust.balance;
      // Zero it out
      DemoDataService.updateCustomerBalance('demo_cust_1', -currentBalance);
      expect(DemoDataService.getCustomer('demo_cust_1')!.balance, 0);
    });

    test('payment creates transaction record (KHAT-004)', () {
      final initialTxns = DemoDataService.getCustomerTransactions(
        'demo_cust_1',
      ).length;
      // Record a payment
      DemoDataService.addTransaction(
        customerId: 'demo_cust_1',
        type: TransactionType.payment,
        amount: 500,
        note: 'Cash payment',
      );
      // Update balance
      DemoDataService.updateCustomerBalance('demo_cust_1', -500);
      // Verify transaction was added
      expect(
        DemoDataService.getCustomerTransactions('demo_cust_1').length,
        initialTxns + 1,
      );
    });
  });

  // ── Bills ──

  group('Bills', () {
    setUp(() {
      DemoDataService.loadDemoData();
    });

    test('getBills returns non-empty list', () {
      expect(DemoDataService.getBills(), isNotEmpty);
    });

    test('getBill by valid ID', () {
      final bills = DemoDataService.getBills();
      final bill = DemoDataService.getBill(bills.first.id);
      expect(bill, isNotNull);
    });

    test('getBill by invalid ID returns null', () {
      expect(DemoDataService.getBill('non_existent'), isNull);
    });

    test('getBillsInRange filters correctly', () {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 30));
      final end = now.add(const Duration(days: 1));
      final bills = DemoDataService.getBillsInRange(start, end);
      expect(bills, isNotEmpty);
      for (final bill in bills) {
        expect(
          bill.createdAt.isAfter(start.subtract(const Duration(seconds: 1))),
          isTrue,
        );
        expect(bill.createdAt.isBefore(end), isTrue);
      }
    });

    test('getBillsInRange returns empty for future range', () {
      final start = DateTime.now().add(const Duration(days: 100));
      final end = start.add(const Duration(days: 10));
      expect(DemoDataService.getBillsInRange(start, end), isEmpty);
    });

    test('addBill returns ID and adds to list', () {
      final initialCount = DemoDataService.getBills().length;
      final bill = BillModel(
        id: 'temp',
        billNumber: 0,
        items: [
          const CartItem(
            productId: 'p1',
            name: 'Test',
            price: 100,
            quantity: 1,
            unit: 'piece',
          ),
        ],
        total: 100,
        paymentMethod: PaymentMethod.cash,
        createdAt: DateTime.now(),
        date: '2026-02-25',
      );
      final id = DemoDataService.addBill(bill);
      expect(id, startsWith('demo_bill_'));
      expect(DemoDataService.getBills().length, initialCount + 1);
    });
  });

  // ── Transactions ──

  group('Transactions', () {
    setUp(() {
      DemoDataService.loadDemoData();
    });

    test('getTransactions returns non-empty list', () {
      expect(DemoDataService.getTransactions(), isNotEmpty);
    });

    test('getCustomerTransactions filters by customer', () {
      final txns = DemoDataService.getCustomerTransactions('demo_cust_1');
      expect(txns, isNotEmpty);
      for (final txn in txns) {
        expect(txn.customerId, 'demo_cust_1');
      }
    });

    test('getCustomerTransactions sorted by date descending', () {
      final txns = DemoDataService.getCustomerTransactions('demo_cust_1');
      if (txns.length > 1) {
        for (var i = 0; i < txns.length - 1; i++) {
          expect(
            txns[i].createdAt.isAfter(txns[i + 1].createdAt) ||
                txns[i].createdAt.isAtSameMomentAs(txns[i + 1].createdAt),
            isTrue,
          );
        }
      }
    });

    test('addTransaction adds to list', () {
      final initialCount = DemoDataService.getTransactions().length;
      DemoDataService.addTransaction(
        customerId: 'demo_cust_1',
        type: TransactionType.payment,
        amount: 1000,
        note: 'Test payment',
      );
      expect(DemoDataService.getTransactions().length, initialCount + 1);
    });

    test('addTransaction returns valid ID', () {
      final id = DemoDataService.addTransaction(
        customerId: 'demo_cust_2',
        type: TransactionType.purchase,
        amount: 500,
        billId: 'bill_123',
      );
      expect(id, startsWith('demo_txn_'));
    });
  });

  // ── Expenses ──

  group('Expenses', () {
    setUp(() {
      DemoDataService.loadDemoData();
    });

    test('getExpenses returns non-empty list', () {
      expect(DemoDataService.getExpenses(), isNotEmpty);
    });

    test('getExpenses has 3 preloaded expenses', () {
      expect(DemoDataService.getExpenses().length, 3);
    });

    test('addExpense adds to list', () {
      final expense = ExpenseModel(
        id: 'temp',
        amount: 300,
        category: ExpenseCategory.supplies,
        description: 'Test expense',
        paymentMethod: PaymentMethod.cash,
        createdAt: DateTime.now(),
        date: '2026-02-25',
      );
      final id = DemoDataService.addExpense(expense);
      expect(id, startsWith('demo_exp_'));
      expect(DemoDataService.getExpenses().length, 4);
    });
  });

  // ── clearDemoData ──

  group('clearDemoData', () {
    test('clears all data', () {
      DemoDataService.loadDemoData();
      expect(DemoDataService.getProducts(), isNotEmpty);
      expect(DemoDataService.getCustomers(), isNotEmpty);

      DemoDataService.clearDemoData();
      expect(DemoDataService.getProducts(), isEmpty);
      expect(DemoDataService.getCustomers(), isEmpty);
      expect(DemoDataService.getBills(), isEmpty);
      expect(DemoDataService.getTransactions(), isEmpty);
      expect(DemoDataService.getExpenses(), isEmpty);
    });
  });
}
