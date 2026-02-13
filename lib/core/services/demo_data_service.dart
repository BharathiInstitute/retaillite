/// Demo Data Service - In-memory storage for demo mode
///
/// All demo data is hardcoded and stored in memory.
/// Changes persist only during the session - reset on app restart or exit demo mode.
library;

import 'package:flutter/foundation.dart';
import 'package:retaillite/models/bill_model.dart';
import 'package:retaillite/models/customer_model.dart';
import 'package:retaillite/models/expense_model.dart';
import 'package:retaillite/models/product_model.dart';
import 'package:retaillite/models/transaction_model.dart';

/// Demo data service - manages all demo mode data in memory
class DemoDataService {
  // ============================================================
  // IN-MEMORY STATE
  // ============================================================
  static List<ProductModel> _products = [];
  static List<CustomerModel> _customers = [];
  static List<BillModel> _bills = [];
  static List<TransactionModel> _transactions = [];
  static List<ExpenseModel> _expenses = [];
  static bool _isLoaded = false;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  /// Load demo data into memory
  static void loadDemoData() {
    debugPrint(
      '🎭 DemoDataService.loadDemoData() called. Already loaded: $_isLoaded',
    );
    if (_isLoaded) return; // Already loaded

    _loadProducts();
    _loadCustomers();
    _loadBills();
    _loadTransactions();
    _loadExpenses();
    _isLoaded = true;
    debugPrint(
      '🎭 Demo data loaded: ${_products.length} products, ${_customers.length} customers, ${_bills.length} bills, ${_expenses.length} expenses',
    );
  }

  /// Clear all demo data
  static void clearDemoData() {
    _products = [];
    _customers = [];
    _bills = [];
    _transactions = [];
    _expenses = [];
    _isLoaded = false;
  }

  /// Check if demo data is loaded
  static bool get isLoaded => _isLoaded;

  // ============================================================
  // PRODUCTS
  // ============================================================

  static void _loadProducts() {
    final now = DateTime.now();
    _products = [
      ProductModel(
        id: 'demo_prod_1',
        name: 'Rice (1kg)',
        price: 55,
        purchasePrice: 48,
        stock: 50,
        lowStockAlert: 10,
        unit: ProductUnit.kg,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      ProductModel(
        id: 'demo_prod_2',
        name: 'Toor Dal (1kg)',
        price: 120,
        purchasePrice: 105,
        stock: 30,
        lowStockAlert: 5,
        unit: ProductUnit.kg,
        createdAt: now.subtract(const Duration(days: 28)),
      ),
      ProductModel(
        id: 'demo_prod_3',
        name: 'Sugar (1kg)',
        price: 45,
        purchasePrice: 40,
        stock: 40,
        lowStockAlert: 10,
        unit: ProductUnit.kg,
        createdAt: now.subtract(const Duration(days: 25)),
      ),
      ProductModel(
        id: 'demo_prod_4',
        name: 'Milk (1L)',
        price: 60,
        purchasePrice: 54,
        stock: 25,
        lowStockAlert: 5,
        unit: ProductUnit.liter,
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      ProductModel(
        id: 'demo_prod_5',
        name: 'Apple (1kg)',
        price: 180,
        purchasePrice: 150,
        stock: 15,
        lowStockAlert: 5,
        unit: ProductUnit.kg,
        createdAt: now.subtract(const Duration(days: 18)),
      ),
      ProductModel(
        id: 'demo_prod_6',
        name: 'Onion (1kg)',
        price: 30,
        purchasePrice: 22,
        stock: 60,
        lowStockAlert: 15,
        unit: ProductUnit.kg,
        createdAt: now.subtract(const Duration(days: 15)),
      ),
      ProductModel(
        id: 'demo_prod_7',
        name: 'Maggi (Pack of 4)',
        price: 56,
        purchasePrice: 48,
        stock: 45,
        lowStockAlert: 10,
        unit: ProductUnit.pack,
        createdAt: now.subtract(const Duration(days: 14)),
      ),
      ProductModel(
        id: 'demo_prod_8',
        name: 'Aashirvaad Atta (5kg)',
        price: 280,
        purchasePrice: 250,
        stock: 20,
        lowStockAlert: 5,
        unit: ProductUnit.pack,
        createdAt: now.subtract(const Duration(days: 12)),
      ),
      ProductModel(
        id: 'demo_prod_9',
        name: 'Fortune Oil (1L)',
        price: 165,
        purchasePrice: 148,
        stock: 18,
        lowStockAlert: 5,
        unit: ProductUnit.liter,
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      ProductModel(
        id: 'demo_prod_10',
        name: 'Tata Salt (1kg)',
        price: 28,
        purchasePrice: 22,
        stock: 80,
        lowStockAlert: 20,
        unit: ProductUnit.kg,
        createdAt: now.subtract(const Duration(days: 8)),
      ),
      ProductModel(
        id: 'demo_prod_11',
        name: 'Amul Butter (100g)',
        price: 56,
        purchasePrice: 50,
        stock: 22,
        lowStockAlert: 5,
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      ProductModel(
        id: 'demo_prod_12',
        name: 'Coca Cola (2L)',
        price: 95,
        purchasePrice: 82,
        stock: 35,
        lowStockAlert: 10,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      ProductModel(
        id: 'demo_prod_13',
        name: 'Parle-G Biscuits',
        price: 10,
        purchasePrice: 8,
        stock: 100,
        lowStockAlert: 20,
        unit: ProductUnit.pack,
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      ProductModel(
        id: 'demo_prod_14',
        name: 'Dairy Milk (₹50)',
        price: 50,
        purchasePrice: 44,
        stock: 40,
        lowStockAlert: 10,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      ProductModel(
        id: 'demo_prod_15',
        name: 'Surf Excel (1kg)',
        price: 220,
        purchasePrice: 195,
        stock: 12,
        lowStockAlert: 3,
        unit: ProductUnit.pack,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }

  /// Get all products
  static List<ProductModel> getProducts() => List.unmodifiable(_products);

  /// Get product by ID
  static ProductModel? getProduct(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get product by barcode
  static ProductModel? getProductByBarcode(String barcode) {
    try {
      return _products.firstWhere((p) => p.barcode == barcode);
    } catch (_) {
      return null;
    }
  }

  /// Add product
  static String addProduct(ProductModel product) {
    final id = 'demo_prod_${DateTime.now().millisecondsSinceEpoch}';
    final newProduct = ProductModel(
      id: id,
      name: product.name,
      price: product.price,
      purchasePrice: product.purchasePrice,
      stock: product.stock,
      lowStockAlert: product.lowStockAlert,
      barcode: product.barcode,
      imageUrl: product.imageUrl,
      unit: product.unit,
      createdAt: DateTime.now(),
    );
    _products.add(newProduct);
    return id;
  }

  /// Update product
  static void updateProduct(ProductModel product) {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
    }
  }

  /// Delete product
  static void deleteProduct(String id) {
    _products.removeWhere((p) => p.id == id);
  }

  /// Update stock
  static void updateStock(String productId, int newStock) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      _products[index] = _products[index].copyWith(stock: newStock);
    }
  }

  /// Decrement stock
  static void decrementStock(String productId, int quantity) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final current = _products[index].stock;
      _products[index] = _products[index].copyWith(stock: current - quantity);
    }
  }

  // ============================================================
  // CUSTOMERS
  // ============================================================

  static void _loadCustomers() {
    final now = DateTime.now();
    _customers = [
      CustomerModel(
        id: 'demo_cust_1',
        name: 'Rajesh Kumar',
        phone: '9876543210',
        address: 'Shop No. 5, Main Market',
        balance: 2500,
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      CustomerModel(
        id: 'demo_cust_2',
        name: 'Anita Sharma',
        phone: '9876543211',
        address: 'House No. 12, Sector 4',
        balance: 500,
        createdAt: now.subtract(const Duration(days: 45)),
      ),
      CustomerModel(
        id: 'demo_cust_3',
        name: 'Mohit Verma',
        phone: '9876543212',
        address: 'B-Block, Gali No. 3',
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      CustomerModel(
        id: 'demo_cust_4',
        name: 'Sunita Devi',
        phone: '9876543213',
        address: 'Near Temple, Old City',
        balance: 1200,
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      CustomerModel(
        id: 'demo_cust_5',
        name: 'Amit Gupta',
        phone: '9876543214',
        address: 'Green Park Colony',
        balance: 800,
        createdAt: now.subtract(const Duration(days: 10)),
      ),
    ];
  }

  /// Get all customers
  static List<CustomerModel> getCustomers() => List.unmodifiable(_customers);

  /// Get customer by ID
  static CustomerModel? getCustomer(String id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Add customer
  static String addCustomer(CustomerModel customer) {
    final id = 'demo_cust_${DateTime.now().millisecondsSinceEpoch}';
    final newCustomer = CustomerModel(
      id: id,
      name: customer.name,
      phone: customer.phone,
      address: customer.address,
      balance: customer.balance,
      createdAt: DateTime.now(),
    );
    _customers.add(newCustomer);
    return id;
  }

  /// Update customer
  static void updateCustomer(CustomerModel customer) {
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      _customers[index] = customer;
    }
  }

  /// Delete customer
  static void deleteCustomer(String id) {
    _customers.removeWhere((c) => c.id == id);
    // Also remove related transactions
    _transactions.removeWhere((t) => t.customerId == id);
  }

  /// Update customer balance
  static void updateCustomerBalance(String customerId, double amount) {
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index != -1) {
      final current = _customers[index].balance;
      _customers[index] = CustomerModel(
        id: _customers[index].id,
        name: _customers[index].name,
        phone: _customers[index].phone,
        address: _customers[index].address,
        balance: current + amount,
        createdAt: _customers[index].createdAt,
      );
    }
  }

  // ============================================================
  // BILLS
  // ============================================================

  static int _billCounter = 1000; // Starting bill number for demo

  static String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  static void _loadBills() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    _bills = [
      // Today's bill - Cash
      BillModel(
        id: 'demo_bill_1',
        billNumber: 1001,
        items: [
          const CartItem(
            productId: 'demo_prod_1',
            name: 'Rice (1kg)',
            quantity: 2,
            price: 55,
            unit: 'kg',
          ),
          const CartItem(
            productId: 'demo_prod_3',
            name: 'Sugar (1kg)',
            quantity: 1,
            price: 45,
            unit: 'kg',
          ),
          const CartItem(
            productId: 'demo_prod_10',
            name: 'Tata Salt (1kg)',
            quantity: 2,
            price: 28,
            unit: 'kg',
          ),
        ],
        total: 211,
        paymentMethod: PaymentMethod.cash,
        createdAt: today.add(const Duration(hours: 10, minutes: 30)),
        date: _formatDate(today),
      ),
      // Today's second bill - UPI
      BillModel(
        id: 'demo_bill_2',
        billNumber: 1002,
        items: [
          const CartItem(
            productId: 'demo_prod_8',
            name: 'Aashirvaad Atta (5kg)',
            quantity: 1,
            price: 280,
            unit: 'pack',
          ),
          const CartItem(
            productId: 'demo_prod_9',
            name: 'Fortune Oil (1L)',
            quantity: 2,
            price: 165,
            unit: 'L',
          ),
        ],
        total: 610,
        paymentMethod: PaymentMethod.upi,
        createdAt: today.add(const Duration(hours: 14, minutes: 15)),
        date: _formatDate(today),
      ),
      // Yesterday's bill - Udhar (credit)
      BillModel(
        id: 'demo_bill_3',
        billNumber: 1000,
        customerId: 'demo_cust_1',
        customerName: 'Rajesh Kumar',
        items: [
          const CartItem(
            productId: 'demo_prod_5',
            name: 'Apple (1kg)',
            quantity: 3,
            price: 180,
            unit: 'kg',
          ),
          const CartItem(
            productId: 'demo_prod_4',
            name: 'Milk (1L)',
            quantity: 5,
            price: 60,
            unit: 'L',
          ),
          const CartItem(
            productId: 'demo_prod_11',
            name: 'Amul Butter (100g)',
            quantity: 2,
            price: 56,
            unit: 'pcs',
          ),
        ],
        total: 952,
        paymentMethod: PaymentMethod.udhar,
        createdAt: yesterday.add(const Duration(hours: 11)),
        date: _formatDate(yesterday),
      ),
    ];
    _billCounter = 1003;
  }

  /// Get all bills
  static List<BillModel> getBills() => List.unmodifiable(_bills);

  /// Get bills in date range
  static List<BillModel> getBillsInRange(DateTime start, DateTime end) {
    return _bills.where((b) {
      return b.createdAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
          b.createdAt.isBefore(end);
    }).toList();
  }

  /// Get bill by ID
  static BillModel? getBill(String id) {
    try {
      return _bills.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Add bill
  static String addBill(BillModel bill) {
    final id = 'demo_bill_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    _billCounter++;
    final newBill = BillModel(
      id: id,
      billNumber: _billCounter,
      items: bill.items,
      total: bill.total,
      paymentMethod: bill.paymentMethod,
      customerId: bill.customerId,
      customerName: bill.customerName,
      receivedAmount: bill.receivedAmount,
      createdAt: now,
      date: _formatDate(now),
    );
    _bills.add(newBill);
    return id;
  }

  // ============================================================
  // TRANSACTIONS
  // ============================================================

  static void _loadTransactions() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _transactions = [
      // Payment from Rajesh Kumar
      TransactionModel(
        id: 'demo_txn_1',
        customerId: 'demo_cust_1',
        type: TransactionType.payment,
        amount: 1000,
        note: 'Cash payment',
        createdAt: today.subtract(const Duration(days: 5)),
      ),
      // Credit to Rajesh Kumar (from bill)
      TransactionModel(
        id: 'demo_txn_2',
        customerId: 'demo_cust_1',
        type: TransactionType.purchase,
        amount: 900,
        billId: 'demo_bill_3',
        createdAt: today.subtract(const Duration(days: 1)),
      ),
      // Payment from Anita Sharma
      TransactionModel(
        id: 'demo_txn_3',
        customerId: 'demo_cust_2',
        type: TransactionType.payment,
        amount: 500,
        note: 'UPI payment',
        createdAt: today.subtract(const Duration(days: 3)),
      ),
      // Credit to Sunita Devi
      TransactionModel(
        id: 'demo_txn_4',
        customerId: 'demo_cust_4',
        type: TransactionType.purchase,
        amount: 1200,
        createdAt: today.subtract(const Duration(days: 7)),
      ),
      // Credit to Amit Gupta
      TransactionModel(
        id: 'demo_txn_5',
        customerId: 'demo_cust_5',
        type: TransactionType.purchase,
        amount: 800,
        createdAt: today.subtract(const Duration(days: 2)),
      ),
    ];
  }

  /// Get all transactions
  static List<TransactionModel> getTransactions() =>
      List.unmodifiable(_transactions);

  /// Get transactions for customer
  static List<TransactionModel> getCustomerTransactions(String customerId) {
    return _transactions.where((t) => t.customerId == customerId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Add transaction
  static String addTransaction({
    required String customerId,
    required TransactionType type,
    required double amount,
    String? note,
    String? billId,
  }) {
    final id = 'demo_txn_${DateTime.now().millisecondsSinceEpoch}';
    final txn = TransactionModel(
      id: id,
      customerId: customerId,
      type: type,
      amount: amount,
      note: note,
      billId: billId,
      createdAt: DateTime.now(),
    );
    _transactions.add(txn);
    return id;
  }

  // ============================================================
  // EXPENSES
  // ============================================================

  static String _formatDateForExpense(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  static void _loadExpenses() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _expenses = [
      ExpenseModel(
        id: 'demo_exp_1',
        amount: 5000,
        category: ExpenseCategory.rent,
        description: 'Monthly shop rent',
        paymentMethod: PaymentMethod.upi,
        createdAt: today.subtract(const Duration(days: 5)),
        date: _formatDateForExpense(today.subtract(const Duration(days: 5))),
      ),
      ExpenseModel(
        id: 'demo_exp_2',
        amount: 500,
        category: ExpenseCategory.utilities,
        description: 'Electricity bill',
        paymentMethod: PaymentMethod.cash,
        createdAt: today.subtract(const Duration(days: 3)),
        date: _formatDateForExpense(today.subtract(const Duration(days: 3))),
      ),
      ExpenseModel(
        id: 'demo_exp_3',
        amount: 200,
        category: ExpenseCategory.supplies,
        description: 'Paper bags and packaging',
        paymentMethod: PaymentMethod.cash,
        createdAt: today.subtract(const Duration(days: 1)),
        date: _formatDateForExpense(today.subtract(const Duration(days: 1))),
      ),
    ];
  }

  /// Get all expenses
  static List<ExpenseModel> getExpenses() => List.unmodifiable(_expenses);

  /// Add expense
  static String addExpense(ExpenseModel expense) {
    final id = 'demo_exp_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    final newExpense = ExpenseModel(
      id: id,
      amount: expense.amount,
      category: expense.category,
      description: expense.description,
      paymentMethod: expense.paymentMethod,
      createdAt: now,
      date: _formatDateForExpense(now),
    );
    _expenses.add(newExpense);
    return id;
  }
}
