/// Offline resilience boundary tests
///
/// Verifies that the app handles offline/unauthenticated states gracefully:
/// — Empty basePath results in safe no-ops / empty returns
/// — Stream providers return empty lists when not authenticated
/// — Settings fall back to defaults when offline
/// — Data retention handles edge cases
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';
import 'package:retaillite/models/bill_model.dart';
import 'package:retaillite/models/product_model.dart';
import 'package:retaillite/models/customer_model.dart';

void main() {
  group('Offline resilience — unauthenticated state', () {
    // When user is not logged in, _basePath is empty.
    // All CRUD operations must be safe no-ops.

    test('getCachedProducts returns empty list sync', () {
      // getCachedProducts() is deprecated but should not crash
      // ignore: deprecated_member_use_from_same_package
      final result = OfflineStorageService.getCachedProducts();
      expect(result, isEmpty);
    });

    test('getCachedBills returns empty list sync', () {
      final result = OfflineStorageService.getCachedBills();
      expect(result, isEmpty);
    });

    test('getCachedCustomers returns empty list sync', () {
      final result = OfflineStorageService.getCachedCustomers();
      expect(result, isEmpty);
    });

    test('getCachedProduct returns null sync', () {
      final result = OfflineStorageService.getCachedProduct('any-id');
      expect(result, isNull);
    });
  });

  group('Offline resilience — SharedPreferences defaults', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('isDataInitialized defaults to false', () {
      expect(OfflineStorageService.isDataInitialized(), isFalse);
    });

    test('getUsageMetric defaults to 0', () {
      expect(OfflineStorageService.getUsageMetric('bills_created'), 0);
      expect(OfflineStorageService.getUsageMetric('any_metric'), 0);
    });

    test('getStorageStats returns zeros', () async {
      final stats = await OfflineStorageService.getStorageStats();
      expect(stats['products'], 0);
      expect(stats['bills'], 0);
      expect(stats['customers'], 0);
      expect(stats['total'], 0);
    });
  });

  group('Offline resilience — model fallback behavior', () {
    test('BillModel handles missing fields gracefully', () {
      // Verify the model can be constructed with minimal data
      final bill = BillModel(
        id: 'bill-offline-1',
        billNumber: 1,
        items: const [],
        total: 0,
        paymentMethod: PaymentMethod.cash,
        receivedAmount: 0,
        createdAt: DateTime.now(),
        date: '2024-01-15',
      );
      expect(bill.id, isNotEmpty);
      expect(bill.items, isEmpty);
      expect(bill.total, 0);
    });

    test('ProductModel handles empty stock', () {
      final product = ProductModel(
        id: 'prod-offline-1',
        name: 'Offline Product',
        price: 0,
        stock: 0,
        createdAt: DateTime.now(),
      );
      expect(product.stock, 0);
    });

    test('CustomerModel handles zero balance', () {
      final customer = CustomerModel(
        id: 'cust-offline-1',
        name: 'Offline Customer',
        phone: '',
        createdAt: DateTime.now(),
      );
      expect(customer.balance, 0);
    });
  });

  group('Offline resilience — settings persistence', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('clearAll removes all preferences', () async {
      SharedPreferences.setMockInitialValues({'key1': 'value1', 'key2': 42});
      await OfflineStorageService.initialize();
      await OfflineStorageService.clearAll();
      // After clear, prefs should be empty
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
    });

    test('clearDemoData removes all preferences', () async {
      SharedPreferences.setMockInitialValues({'demo_key': 'demo_value'});
      await OfflineStorageService.initialize();
      await OfflineStorageService.clearDemoData();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
    });
  });

  group('Offline resilience — user settings isolation on sign-out', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'data_initialized': true,
        'is_dark_mode': true,
        'language': 'hi',
        'printer_name': 'HP Printer',
        'printer_address': 'AA:BB:CC',
        'usage_bills': 100,
        'sync_last': '2024-01-15',
      });
      // Reset OfflineStorageService so it picks up the new mock
      OfflineStorageService.resetForTesting();
      await OfflineStorageService.initialize();
    });

    test('clearUserLocalSettings removes user-specific keys', () async {
      await OfflineStorageService.clearUserLocalSettings();
      final prefs = await SharedPreferences.getInstance();
      // User-specific keys should be removed
      expect(prefs.getBool('data_initialized'), isNull);
      expect(prefs.getBool('is_dark_mode'), isNull);
      expect(prefs.getString('language'), isNull);
      // Usage metrics cleared
      expect(prefs.getInt('usage_bills'), isNull);
      // Sync metadata cleared
      expect(prefs.getString('sync_last'), isNull);
    });

    test(
      'clearUserLocalSettings preserves device-level printer config',
      () async {
        await OfflineStorageService.clearUserLocalSettings();
        final prefs = await SharedPreferences.getInstance();
        // Printer config should be preserved across sign-outs
        expect(prefs.getString('printer_name'), 'HP Printer');
        expect(prefs.getString('printer_address'), 'AA:BB:CC');
      },
    );
  });

  group('Offline resilience — cacheProducts/cacheBills are no-ops', () {
    test('cacheProducts does not throw', () async {
      // Firestore handles caching, this is a no-op
      await OfflineStorageService.cacheProducts([]);
    });

    test('cacheBills does not throw', () async {
      await OfflineStorageService.cacheBills([]);
    });

    test('cacheCustomers does not throw', () async {
      await OfflineStorageService.cacheCustomers([]);
    });
  });
}
