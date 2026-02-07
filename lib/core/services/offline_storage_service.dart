/// Offline storage service - Firestore-based with offline support
///
/// This replaces the previous Hive-based implementation.
/// Firebase Firestore offline persistence handles all local caching.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:retaillite/models/bill_model.dart';
import 'package:retaillite/models/customer_model.dart';
import 'package:retaillite/models/product_model.dart';
import 'package:retaillite/models/transaction_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys for SharedPreferences (for settings only)
class SettingsKeys {
  static const String settings = 'app_settings';
  static const String dataInitialized = 'data_initialized';
  static const String isDarkMode = 'is_dark_mode';
  static const String language = 'language';
  static const String retentionDays = 'retention_days';
  static const String lastCleanupTime = 'last_cleanup_time';
  static const String lastExportTime = 'last_export_time';
  static const String autoCleanupEnabled = 'auto_cleanup_enabled';
}

/// Hive box names (kept for compatibility, now maps to Firestore collections)
class HiveBoxes {
  static const String products = 'products';
  static const String bills = 'bills';
  static const String customers = 'customers';
  static const String pendingSync = 'pending_sync';
  static const String settings = 'settings';
}

/// Printer storage for SharedPreferences
class PrinterStorage {
  static const String isConnected = 'printer_is_connected';
  static const String printerName = 'printer_name';
  static const String printerAddress = 'printer_address';
  static const String paperWidth = 'printer_paper_width';
  static const String _paperSizeKey = 'printer_paper_size';
  static const String _fontSizeKey = 'printer_font_size';
  static const String _customWidthKey = 'printer_custom_width';

  static SharedPreferences? _prefs;

  static Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get saved printer
  static Map<String, String>? getSavedPrinter() {
    final name = _prefs?.getString(printerName);
    final address = _prefs?.getString(printerAddress);
    if (name == null || address == null) return null;
    return {'name': name, 'address': address};
  }

  /// Save printer
  static Future<void> savePrinter(String name, String address) async {
    await _ensurePrefs();
    await _prefs?.setString(printerName, name);
    await _prefs?.setString(printerAddress, address);
    await _prefs?.setBool(isConnected, true);
  }

  /// Clear saved printer
  static Future<void> clearSavedPrinter() async {
    await _ensurePrefs();
    await _prefs?.remove(printerName);
    await _prefs?.remove(printerAddress);
    await _prefs?.setBool(isConnected, false);
  }

  /// Get saved paper size (index)
  static int getSavedPaperSize() {
    return _prefs?.getInt(_paperSizeKey) ?? 0;
  }

  /// Save paper size
  static Future<void> savePaperSize(int sizeIndex) async {
    await _ensurePrefs();
    await _prefs?.setInt(_paperSizeKey, sizeIndex);
  }

  /// Get saved font size (index)
  static int getSavedFontSize() {
    return _prefs?.getInt(_fontSizeKey) ?? 1;
  }

  /// Save font size
  static Future<void> saveFontSize(int fontSizeIndex) async {
    await _ensurePrefs();
    await _prefs?.setInt(_fontSizeKey, fontSizeIndex);
  }

  /// Get saved custom width
  static int getSavedCustomWidth() {
    return _prefs?.getInt(_customWidthKey) ?? 0;
  }

  /// Save custom width
  static Future<void> saveCustomWidth(int width) async {
    await _ensurePrefs();
    await _prefs?.setInt(_customWidthKey, width);
  }

  /// Initialize (called during app startup)
  static Future<void> initialize() async {
    await _ensurePrefs();
  }
}

/// Offline storage service using Firestore with offline persistence
class OfflineStorageService {
  static bool _initialized = false;
  static SharedPreferences? _prefs;
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Get user's collection path
  static String get _basePath {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return ''; // Not logged in
    return 'users/$uid';
  }

  /// Initialize storage (Firestore offline is already enabled in SyncSettingsService)
  static Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    debugPrint('✅ OfflineStorageService initialized (Firestore-based)');
  }

  // ==================== Products ====================

  /// Cache products locally (no-op, Firestore handles caching)
  static Future<void> cacheProducts(List<ProductModel> products) async {
    debugPrint(
      'cacheProducts: Firestore handles caching, ${products.length} products',
    );
  }

  /// Get cached products from Firestore
  static List<ProductModel> getCachedProducts() {
    debugPrint('getCachedProducts: Use productsProvider stream instead');
    return [];
  }

  /// Get cached products async (recommended)
  static Future<List<ProductModel>> getCachedProductsAsync() async {
    if (_basePath.isEmpty) return [];
    try {
      final snapshot = await _firestore
          .collection('$_basePath/products')
          .get(const GetOptions(source: Source.cache));
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get single cached product
  static ProductModel? getCachedProduct(String id) {
    return null;
  }

  /// Get single cached product async
  static Future<ProductModel?> getCachedProductAsync(String id) async {
    if (_basePath.isEmpty) return null;
    try {
      final doc = await _firestore.doc('$_basePath/products/$id').get();
      if (!doc.exists) return null;
      return ProductModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  /// Update cached product (saves to Firestore)
  static Future<void> updateCachedProduct(ProductModel product) async {
    if (_basePath.isEmpty) return;
    await _firestore
        .doc('$_basePath/products/${product.id}')
        .set(product.toFirestore());
  }

  /// Delete product
  static Future<void> deleteProduct(String productId) async {
    if (_basePath.isEmpty) return;
    await _firestore.doc('$_basePath/products/$productId').delete();
  }

  // ==================== Bills ====================

  /// Cache bills locally (no-op, Firestore handles caching)
  static Future<void> cacheBills(List<BillModel> bills) async {
    debugPrint('cacheBills: Firestore handles caching, ${bills.length} bills');
  }

  /// Get cached bills
  static List<BillModel> getCachedBills() {
    return [];
  }

  /// Get cached bills async
  static Future<List<BillModel>> getCachedBillsAsync() async {
    if (_basePath.isEmpty) return [];
    try {
      final snapshot = await _firestore
          .collection('$_basePath/bills')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get(const GetOptions(source: Source.cache));
      return snapshot.docs.map((doc) => BillModel.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get cached bills in date range
  static Future<List<BillModel>> getCachedBillsInRange(
    DateTime start,
    DateTime end,
  ) async {
    if (_basePath.isEmpty) return [];
    try {
      final snapshot = await _firestore
          .collection('$_basePath/bills')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => BillModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting bills in range: $e');
      return [];
    }
  }

  /// Save bill
  static Future<void> saveBill(BillModel bill) async {
    if (_basePath.isEmpty) return;
    await _firestore.doc('$_basePath/bills/${bill.id}').set(bill.toFirestore());
  }

  /// Save bill locally (alias for saveBill for backward compatibility)
  static Future<void> saveBillLocally(BillModel bill) async {
    await saveBill(bill);
  }

  /// Delete old bills (data retention)
  static Future<int> deleteOldBills(DateTime before) async {
    if (_basePath.isEmpty) return 0;
    final snapshot = await _firestore
        .collection('$_basePath/bills')
        .where('createdAt', isLessThan: Timestamp.fromDate(before))
        .get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    return snapshot.docs.length;
  }

  // ==================== Customers ====================

  /// Cache customers (no-op)
  static Future<void> cacheCustomers(List<CustomerModel> customers) async {
    debugPrint(
      'cacheCustomers: Firestore handles caching, ${customers.length} customers',
    );
  }

  /// Get cached customers
  static List<CustomerModel> getCachedCustomers() {
    return [];
  }

  /// Get cached customers async
  static Future<List<CustomerModel>> getCachedCustomersAsync() async {
    if (_basePath.isEmpty) return [];
    try {
      final snapshot = await _firestore
          .collection('$_basePath/customers')
          .get(const GetOptions(source: Source.cache));
      return snapshot.docs
          .map((doc) => CustomerModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get single cached customer async
  static Future<CustomerModel?> getCachedCustomerAsync(
    String customerId,
  ) async {
    if (_basePath.isEmpty) return null;
    try {
      final doc = await _firestore
          .doc('$_basePath/customers/$customerId')
          .get(const GetOptions(source: Source.cache));
      if (!doc.exists) return null;
      return CustomerModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  /// Save customer
  static Future<void> saveCustomer(CustomerModel customer) async {
    if (_basePath.isEmpty) return;
    await _firestore
        .doc('$_basePath/customers/${customer.id}')
        .set(customer.toFirestore());
  }

  /// Update cached customer
  static Future<void> updateCachedCustomer(CustomerModel customer) async {
    await saveCustomer(customer);
  }

  /// Delete customer
  static Future<void> deleteCustomer(String customerId) async {
    if (_basePath.isEmpty) return;
    await _firestore.doc('$_basePath/customers/$customerId').delete();
  }

  /// Update customer balance
  static Future<void> updateCustomerBalance(
    String customerId,
    double newBalance,
  ) async {
    if (_basePath.isEmpty) return;
    await _firestore.doc('$_basePath/customers/$customerId').update({
      'balance': newBalance,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================== Transactions ====================

  /// Save transaction (for Khata) - accepts TransactionModel
  static Future<void> saveTransactionModel(TransactionModel transaction) async {
    if (_basePath.isEmpty) return;
    await _firestore
        .doc('$_basePath/transactions/${transaction.id}')
        .set(transaction.toFirestore());
  }

  /// Save transaction with named parameters (convenience method)
  static Future<void> saveTransaction({
    required String customerId,
    required String type,
    required double amount,
    String? billId,
    String? note,
    String? paymentMode,
  }) async {
    if (_basePath.isEmpty) return;

    final transaction = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      customerId: customerId,
      type: type == 'payment'
          ? TransactionType.payment
          : TransactionType.purchase,
      amount: amount,
      billId: billId,
      note: note,
      paymentMode: paymentMode,
      createdAt: DateTime.now(),
    );

    await _firestore
        .doc('$_basePath/transactions/${transaction.id}')
        .set(transaction.toFirestore());
  }

  /// Get customer transactions
  static Future<List<TransactionModel>> getCustomerTransactions(
    String customerId,
  ) async {
    if (_basePath.isEmpty) return [];
    try {
      final snapshot = await _firestore
          .collection('$_basePath/transactions')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ==================== Settings ====================

  /// Check if data is initialized
  static bool isDataInitialized() {
    return _prefs?.getBool(SettingsKeys.dataInitialized) ?? false;
  }

  /// Mark data as initialized
  static Future<void> markDataInitialized() async {
    await _prefs?.setBool(SettingsKeys.dataInitialized, true);
  }

  /// Get setting
  static T? getSetting<T>(String key, {T? defaultValue}) {
    final value = _prefs?.get(key);
    if (value == null) return defaultValue;
    return value as T?;
  }

  /// Save setting
  static Future<void> saveSetting<T>(String key, T value) async {
    _prefs ??= await SharedPreferences.getInstance();
    if (value is String) {
      await _prefs?.setString(key, value);
    } else if (value is int) {
      await _prefs?.setInt(key, value);
    } else if (value is double) {
      await _prefs?.setDouble(key, value);
    } else if (value is bool) {
      await _prefs?.setBool(key, value);
    } else if (value is List<String>) {
      await _prefs?.setStringList(key, value);
    }
  }

  /// Set setting (alias for saveSetting)
  static Future<void> setSetting<T>(String key, T value) async {
    await saveSetting(key, value);
  }

  // ==================== Usage Metrics ====================

  /// Log usage metric
  static Future<void> logUsageMetric(String metricName, int value) async {
    final key = 'usage_$metricName';
    final current = _prefs?.getInt(key) ?? 0;
    await _prefs?.setInt(key, current + value);
  }

  /// Get usage metric
  static int getUsageMetric(String metricName) {
    return _prefs?.getInt('usage_$metricName') ?? 0;
  }

  // ==================== Storage Stats ====================

  /// Get storage stats
  static Future<Map<String, int>> getStorageStats() async {
    return {'products': 0, 'bills': 0, 'customers': 0, 'total': 0};
  }

  /// Clear all local cache (not recommended)
  static Future<void> clearAll() async {
    debugPrint('clearAll: Not implemented for Firestore');
  }

  /// Clear demo data (used when exiting demo mode)
  static Future<void> clearDemoData() async {
    debugPrint('clearDemoData: Clearing local demo preferences');
    await _prefs?.clear();
  }
}
