/// Offline storage service - Firestore-based with offline support
///
/// This replaces the previous Hive-based implementation.
/// Firebase Firestore offline persistence handles all local caching.
library;

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:retaillite/core/constants/app_constants.dart';
import 'package:retaillite/core/services/sync_status_service.dart';
import 'package:retaillite/core/utils/id_generator.dart';
import 'package:retaillite/models/bill_model.dart';
import 'package:retaillite/models/customer_model.dart';
import 'package:retaillite/models/expense_model.dart';
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
  static const String _autoPrintKey = 'printer_auto_print';
  static const String _receiptFooterKey = 'printer_receipt_footer';
  static const String _printerTypeKey = 'printer_type';
  static const String _wifiIpKey = 'printer_wifi_ip';
  static const String _wifiPortKey = 'printer_wifi_port';
  static const String _usbPrinterNameKey = 'printer_usb_name';

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

  /// Get auto-print setting
  static bool getAutoPrint() {
    return _prefs?.getBool(_autoPrintKey) ?? false;
  }

  /// Save auto-print setting
  static Future<void> saveAutoPrint(bool autoPrint) async {
    await _ensurePrefs();
    await _prefs?.setBool(_autoPrintKey, autoPrint);
  }

  /// Get receipt footer text
  static String getReceiptFooter() {
    return _prefs?.getString(_receiptFooterKey) ?? '';
  }

  /// Save receipt footer text
  static Future<void> saveReceiptFooter(String footer) async {
    await _ensurePrefs();
    await _prefs?.setString(_receiptFooterKey, footer);
  }

  /// Get printer type (system, bluetooth, usb, wifi)
  static String getPrinterType() {
    return _prefs?.getString(_printerTypeKey) ?? 'system';
  }

  /// Save printer type
  static Future<void> savePrinterType(String type) async {
    await _ensurePrefs();
    await _prefs?.setString(_printerTypeKey, type);
  }

  // ── WiFi printer settings ──

  /// Get saved WiFi printer IP
  static String getWifiPrinterIp() {
    return _prefs?.getString(_wifiIpKey) ?? '';
  }

  /// Save WiFi printer IP
  static Future<void> saveWifiPrinterIp(String ip) async {
    await _ensurePrefs();
    await _prefs?.setString(_wifiIpKey, ip);
  }

  /// Get saved WiFi printer port (default 9100)
  static int getWifiPrinterPort() {
    return _prefs?.getInt(_wifiPortKey) ?? 9100;
  }

  /// Save WiFi printer port
  static Future<void> saveWifiPrinterPort(int port) async {
    await _ensurePrefs();
    await _prefs?.setInt(_wifiPortKey, port);
  }

  // ── USB printer settings ──

  /// Get saved USB printer name (Windows)
  static String getUsbPrinterName() {
    return _prefs?.getString(_usbPrinterNameKey) ?? '';
  }

  /// Save USB printer name (Windows)
  static Future<void> saveUsbPrinterName(String name) async {
    await _ensurePrefs();
    await _prefs?.setString(_usbPrinterNameKey, name);
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

  /// Expose prefs for direct access (e.g., route persistence)
  static SharedPreferences? get prefs => _prefs;

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
      final snapshot = await _firestore.collection('$_basePath/products').get();
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting products: $e');
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

  /// Get all bills (uses server when online, cache when offline)
  static Future<List<BillModel>> getCachedBillsAsync() async {
    if (_basePath.isEmpty) return [];
    try {
      final snapshot = await _firestore
          .collection('$_basePath/bills')
          .orderBy('createdAt', descending: true)
          .limit(AppConstants.queryLimitBills)
          .get();
      return snapshot.docs.map((doc) => BillModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting bills: $e');
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

  /// Get next sequential bill number using Firestore atomic counter.
  /// Atomic, multi-device safe, survives app reinstalls.
  /// Falls back to random bill number if Firestore access fails.
  static Future<int> getNextBillNumber() async {
    if (_basePath.isEmpty) return generateBillNumber();

    try {
      final counterRef = _firestore.doc('$_basePath/counters/billing');
      // Atomic increment — safe even with concurrent access
      await counterRef.set({
        'billNumber': FieldValue.increment(1),
      }, SetOptions(merge: true));
      final snapshot = await counterRef.get();
      final data = snapshot.data();
      return (data?['billNumber'] as int?) ?? 1001;
    } catch (e) {
      debugPrint('⚠️ Bill counter fallback: $e');
      return generateBillNumber();
    }
  }

  /// Save bill locally (alias for saveBill for backward compatibility)
  static Future<void> saveBillLocally(BillModel bill) async {
    await saveBill(bill);
  }

  /// Stream of all bills (real-time updates from Firestore)
  static Stream<List<BillModel>> billsStream() {
    if (_basePath.isEmpty) return Stream.value([]);
    return _firestore
        .collection('$_basePath/bills')
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.queryLimitBills)
        .snapshots()
        .map((snapshot) {
          final bills = snapshot.docs
              .map((doc) => BillModel.fromFirestore(doc))
              .toList();
          // Report sync status
          final pendingCount = snapshot.docs
              .where((d) => d.metadata.hasPendingWrites)
              .length;
          SyncStatusService.updateCollection(
            'bills',
            totalDocs: bills.length,
            unsyncedDocs: pendingCount,
            hasPendingWrites: snapshot.metadata.hasPendingWrites,
          );
          return bills;
        });
  }

  /// Stream of bills in a date range (real-time)
  static Stream<List<BillModel>> billsInRangeStream(
    DateTime start,
    DateTime end,
  ) {
    if (_basePath.isEmpty) return Stream.value([]);
    return _firestore
        .collection('$_basePath/bills')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.queryLimitBills)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => BillModel.fromFirestore(doc)).toList(),
        );
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

  // ==================== Expenses ====================

  /// Save expense
  static Future<void> saveExpense(ExpenseModel expense) async {
    if (_basePath.isEmpty) return;
    await _firestore
        .doc('$_basePath/expenses/${expense.id}')
        .set(expense.toFirestore());
  }

  /// Get all expenses (uses server when online, cache when offline)
  static Future<List<ExpenseModel>> getCachedExpensesAsync() async {
    if (_basePath.isEmpty) return [];
    try {
      final snapshot = await _firestore
          .collection('$_basePath/expenses')
          .orderBy('createdAt', descending: true)
          .limit(AppConstants.queryLimitExpenses)
          .get();
      return snapshot.docs
          .map((doc) => ExpenseModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting expenses: $e');
      return [];
    }
  }

  /// Delete expense
  static Future<void> deleteExpense(String expenseId) async {
    if (_basePath.isEmpty) return;
    await _firestore.doc('$_basePath/expenses/$expenseId').delete();
  }

  /// Stream of all expenses (real-time updates from Firestore)
  static Stream<List<ExpenseModel>> expensesStream() {
    if (_basePath.isEmpty) return Stream.value([]);
    return _firestore
        .collection('$_basePath/expenses')
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.queryLimitExpenses)
        .snapshots()
        .map((snapshot) {
          final expenses = snapshot.docs
              .map((doc) => ExpenseModel.fromFirestore(doc))
              .toList();
          // Report sync status
          final pendingCount = snapshot.docs
              .where((d) => d.metadata.hasPendingWrites)
              .length;
          SyncStatusService.updateCollection(
            'expenses',
            totalDocs: expenses.length,
            unsyncedDocs: pendingCount,
            hasPendingWrites: snapshot.metadata.hasPendingWrites,
          );
          return expenses;
        });
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

  /// Get cached customers async (uses default source for immediate consistency)
  static Future<List<CustomerModel>> getCachedCustomersAsync() async {
    if (_basePath.isEmpty) return [];
    try {
      final snapshot = await _firestore
          .collection('$_basePath/customers')
          .get();
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
          .get();
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

  /// Update customer balance by delta (positive = increase, negative = decrease)
  static Future<void> updateCustomerBalance(
    String customerId,
    double delta,
  ) async {
    if (_basePath.isEmpty) return;
    await _firestore.doc('$_basePath/customers/$customerId').update({
      'balance': FieldValue.increment(delta),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream of all customers (real-time updates from Firestore)
  static Stream<List<CustomerModel>> customersStream() {
    if (_basePath.isEmpty) return Stream.value([]);
    return _firestore
        .collection('$_basePath/customers')
        .limit(AppConstants.queryLimitCustomers)
        .snapshots()
        .map((snapshot) {
          final customers = snapshot.docs
              .map((doc) => CustomerModel.fromFirestore(doc))
              .toList();
          // Report sync status
          final pendingCount = snapshot.docs
              .where((d) => d.metadata.hasPendingWrites)
              .length;
          SyncStatusService.updateCollection(
            'customers',
            totalDocs: customers.length,
            unsyncedDocs: pendingCount,
            hasPendingWrites: snapshot.metadata.hasPendingWrites,
          );
          return customers;
        });
  }

  /// Stream of a single customer (real-time)
  static Stream<CustomerModel?> customerStream(String customerId) {
    if (_basePath.isEmpty) return Stream.value(null);
    return _firestore
        .doc('$_basePath/customers/$customerId')
        .snapshots()
        .map((doc) => doc.exists ? CustomerModel.fromFirestore(doc) : null);
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
      id: generateSafeId('txn'),
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

  /// Get total payment amount collected today (single query, no N+1)
  static Future<double> getTodayPaymentTotal() async {
    if (_basePath.isEmpty) return 0;
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final snapshot = await _firestore
          .collection('$_basePath/transactions')
          .where('type', isEqualTo: 'payment')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .get();
      return snapshot.docs.fold<double>(0, (total, doc) {
        final amount = (doc.data()['amount'] as num?)?.toDouble() ?? 0;
        return total + amount;
      });
    } catch (e) {
      return 0;
    }
  }

  /// Stream of customer transactions (real-time)
  static Stream<List<TransactionModel>> customerTransactionsStream(
    String customerId,
  ) {
    if (_basePath.isEmpty) return Stream.value([]);
    return _firestore
        .collection('$_basePath/transactions')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.queryLimitTransactions)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransactionModel.fromFirestore(doc))
              .toList(),
        );
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

  /// Get setting from local SharedPreferences (for backward compatibility)
  static T? getSetting<T>(String key, {T? defaultValue}) {
    final value = _prefs?.get(key);
    if (value == null) return defaultValue;
    // Handle Map types stored as JSON strings
    if (T == dynamic || value is T) {
      return value as T?;
    }
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is T) return decoded;
      } catch (_) {
        // Not valid JSON, return as-is or default
      }
    }
    return defaultValue;
  }

  /// Save setting to both Firestore (for sync) and SharedPreferences (for local cache)
  static Future<void> saveSetting<T>(String key, T value) async {
    _prefs ??= await SharedPreferences.getInstance();

    // Save to SharedPreferences for local cache
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
    } else if (value is Map<String, dynamic>) {
      // For maps, store as JSON string locally
      await _prefs?.setString(key, jsonEncode(value));
    }

    // Also save to Firestore for cross-device sync
    await saveSettingToCloud(key, value);
  }

  /// Save setting to Firestore for cloud sync
  static Future<void> saveSettingToCloud<T>(String key, T value) async {
    if (_basePath.isEmpty) return;
    try {
      await _firestore
          .doc('$_basePath/settings/user_settings')
          .set({key: value}, SetOptions(merge: true))
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Error saving setting to cloud: $e');
    }
  }

  /// Get setting from Firestore (async, for cloud sync)
  static Future<T?> getSettingFromCloud<T>(String key) async {
    if (_basePath.isEmpty) return null;
    try {
      final doc = await _firestore
          .doc('$_basePath/settings/user_settings')
          .get()
          .timeout(const Duration(seconds: 5));
      if (!doc.exists) return null;
      return doc.data()?[key] as T?;
    } catch (e) {
      debugPrint('Error getting setting from cloud: $e');
      return null;
    }
  }

  /// Load all settings from cloud and cache locally
  static Future<Map<String, dynamic>> loadAllSettingsFromCloud() async {
    if (_basePath.isEmpty) return {};
    try {
      final doc = await _firestore
          .doc('$_basePath/settings/user_settings')
          .get()
          .timeout(const Duration(seconds: 5));
      if (!doc.exists) return {};
      final data = doc.data() ?? {};

      // Cache to SharedPreferences
      for (final entry in data.entries) {
        final value = entry.value;
        if (value is String) {
          await _prefs?.setString(entry.key, value);
        } else if (value is int) {
          await _prefs?.setInt(entry.key, value);
        } else if (value is double) {
          await _prefs?.setDouble(entry.key, value);
        } else if (value is bool) {
          await _prefs?.setBool(entry.key, value);
        }
      }

      return data;
    } catch (e) {
      debugPrint('Error loading settings from cloud: $e');
      return {};
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

  /// Clear all local cache
  static Future<void> clearAll() async {
    await _prefs?.clear();
    debugPrint('✅ clearAll: SharedPreferences cleared');
  }

  /// Clear user-specific local settings on sign-out
  /// Preserves device-level settings (printer config) but clears user data flags
  static Future<void> clearUserLocalSettings() async {
    _prefs ??= await SharedPreferences.getInstance();

    // Keys that are user-specific and should be cleared on sign-out
    final userKeys = [
      SettingsKeys.dataInitialized,
      SettingsKeys.isDarkMode,
      SettingsKeys.language,
      SettingsKeys.retentionDays,
      SettingsKeys.lastCleanupTime,
      SettingsKeys.lastExportTime,
      SettingsKeys.autoCleanupEnabled,
      SettingsKeys.settings,
      // User metrics keys (prevent bill count / user ID leaking between users)
      'bills_this_month',
      'last_reset_month',
      'user_id',
      // Theme settings (each user has their own theme)
      'theme_settings',
      'theme_is_dark',
      'theme_use_system',
      // Route persistence (each user may have different last page)
      'last_route',
    ];

    // Also clear any usage metrics and sync metadata
    final allKeys = _prefs?.getKeys() ?? {};
    for (final key in allKeys) {
      if (key.startsWith('usage_') ||
          key.startsWith('sync_') ||
          key.startsWith('last_sync') ||
          key.startsWith('pending_sync') ||
          userKeys.contains(key)) {
        await _prefs?.remove(key);
      }
    }
    debugPrint('✅ User-specific local settings cleared');
  }

  /// Clear demo data (used when exiting demo mode)
  static Future<void> clearDemoData() async {
    debugPrint('clearDemoData: Clearing local demo preferences');
    await _prefs?.clear();
  }
}
