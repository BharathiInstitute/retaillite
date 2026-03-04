/// UserModel & UserSettings comprehensive tests
///
/// Ensures model integrity for 10K subscribers — copyWith, serialization,
/// defaults, and settings round-trip.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/models/user_model.dart';
import '../helpers/test_factories.dart';

void main() {
  // ── UserModel basics ──

  group('UserModel', () {
    test('should create with required fields', () {
      final user = makeUser();
      expect(user.id, 'user-1');
      expect(user.shopName, 'Test Shop');
      expect(user.ownerName, 'Test Owner');
      expect(user.phone, '9876543210');
      expect(user.email, 'test@test.com');
    });

    test('isPaid defaults to false', () {
      final user = makeUser();
      expect(user.isPaid, false);
    });

    test('phone/email verified default to false', () {
      final user = makeUser();
      expect(user.phoneVerified, false);
      expect(user.emailVerified, false);
    });

    test('copyWith preserves unchanged fields', () {
      final user = makeUser(shopName: 'Original Shop');
      final updated = user.copyWith(ownerName: 'New Owner');

      expect(updated.shopName, 'Original Shop');
      expect(updated.ownerName, 'New Owner');
      expect(updated.phone, user.phone);
      expect(updated.email, user.email);
    });

    test('copyWith updates multiple fields', () {
      final user = makeUser();
      final updated = user.copyWith(
        shopName: 'New Shop',
        isPaid: true,
        phoneVerified: true,
      );

      expect(updated.shopName, 'New Shop');
      expect(updated.isPaid, true);
      expect(updated.phoneVerified, true);
    });

    test('copyWith preserves id and createdAt', () {
      final user = makeUser(id: 'fixed-id');
      final updated = user.copyWith(shopName: 'Changed');

      expect(updated.id, 'fixed-id');
      expect(updated.createdAt, user.createdAt);
    });

    test('copyWith sets updatedAt', () {
      final user = makeUser();
      final updated = user.copyWith(shopName: 'Changed');
      expect(updated.updatedAt, isNotNull);
    });

    test('toFirestore serializes all fields', () {
      final user = makeUser(
        shopName: 'My Shop',
        gstNumber: '22AAAAA0000A1Z5',
        upiId: 'shop@upi',
      );
      final map = user.toFirestore();

      expect(map['shopName'], 'My Shop');
      expect(map['gstNumber'], '22AAAAA0000A1Z5');
      expect(map['upiId'], 'shop@upi');
      expect(map['isPaid'], false);
      expect(map['settings'], isA<Map<String, dynamic>>());
      expect(map.containsKey('createdAt'), true);
    });

    test('toFirestore does NOT include id', () {
      final user = makeUser();
      final map = user.toFirestore();
      expect(map.containsKey('id'), false);
    });
  });

  // ── UserSettings ──

  group('UserSettings', () {
    test('has correct defaults', () {
      const settings = UserSettings();
      expect(settings.language, 'hi');
      expect(settings.darkMode, false);
      expect(settings.autoPrint, false);
      expect(settings.printPreview, true);
      expect(settings.soundEnabled, true);
      expect(settings.notificationsEnabled, true);
      expect(settings.lowStockAlerts, true);
      expect(settings.subscriptionAlerts, true);
      expect(settings.dailySummary, true);
      expect(settings.printerAddress, isNull);
      expect(settings.billSize, '58mm');
      expect(settings.gstEnabled, true);
      expect(settings.taxRate, 5.0);
      expect(settings.receiptFooter, 'Thank you for shopping!');
    });

    test('fromMap parses complete map', () {
      final settings = UserSettings.fromMap({
        'language': 'en',
        'darkMode': true,
        'autoPrint': true,
        'printPreview': false,
        'soundEnabled': false,
        'notificationsEnabled': false,
        'lowStockAlerts': false,
        'subscriptionAlerts': false,
        'dailySummary': false,
        'printerAddress': 'AA:BB:CC:DD:EE:FF',
        'billSize': '80mm',
        'gstEnabled': false,
        'taxRate': 18.0,
        'receiptFooter': 'Visit again!',
      });

      expect(settings.language, 'en');
      expect(settings.darkMode, true);
      expect(settings.autoPrint, true);
      expect(settings.printPreview, false);
      expect(settings.printerAddress, 'AA:BB:CC:DD:EE:FF');
      expect(settings.billSize, '80mm');
      expect(settings.gstEnabled, false);
      expect(settings.taxRate, 18.0);
      expect(settings.receiptFooter, 'Visit again!');
    });

    test('fromMap with empty map returns defaults', () {
      final settings = UserSettings.fromMap({});
      expect(settings.language, 'hi');
      expect(settings.darkMode, false);
      expect(settings.billSize, '58mm');
      expect(settings.taxRate, 5.0);
    });

    test('fromMap handles numeric taxRate', () {
      final settings = UserSettings.fromMap({'taxRate': 12});
      expect(settings.taxRate, 12.0);
    });

    test('toMap serializes all fields', () {
      const settings = UserSettings(
        language: 'te',
        darkMode: true,
        taxRate: 18.0,
      );
      final map = settings.toMap();

      expect(map['language'], 'te');
      expect(map['darkMode'], true);
      expect(map['taxRate'], 18.0);
      expect(map.length, 14); // All 14 fields
    });

    test('toMap → fromMap round-trip preserves all values', () {
      const original = UserSettings(
        language: 'en',
        darkMode: true,
        autoPrint: true,
        printPreview: false,
        soundEnabled: false,
        gstEnabled: false,
        taxRate: 12.0,
        receiptFooter: 'Custom footer',
      );

      final restored = UserSettings.fromMap(original.toMap());

      expect(restored.language, original.language);
      expect(restored.darkMode, original.darkMode);
      expect(restored.autoPrint, original.autoPrint);
      expect(restored.printPreview, original.printPreview);
      expect(restored.soundEnabled, original.soundEnabled);
      expect(restored.gstEnabled, original.gstEnabled);
      expect(restored.taxRate, original.taxRate);
      expect(restored.receiptFooter, original.receiptFooter);
    });

    test('copyWith updates single field', () {
      const settings = UserSettings();
      final updated = settings.copyWith(darkMode: true);

      expect(updated.darkMode, true);
      expect(updated.language, 'hi'); // unchanged
      expect(updated.taxRate, 5.0); // unchanged
    });

    test('copyWith updates multiple fields', () {
      const settings = UserSettings();
      final updated = settings.copyWith(
        language: 'en',
        billSize: '80mm',
        taxRate: 18.0,
      );

      expect(updated.language, 'en');
      expect(updated.billSize, '80mm');
      expect(updated.taxRate, 18.0);
    });
  });

  // ── Edge cases ──

  group('Edge cases', () {
    test('user with empty strings', () {
      final user = makeUser(shopName: '', ownerName: '', phone: '');
      expect(user.shopName, '');
      expect(user.ownerName, '');
      expect(user.phone, '');
    });

    test('user with very long shop name', () {
      final longName = 'A' * 500;
      final user = makeUser(shopName: longName);
      expect(user.shopName.length, 500);
    });

    test('settings with edge tax rates', () {
      final zeroTax = UserSettings.fromMap({'taxRate': 0});
      expect(zeroTax.taxRate, 0.0);

      final highTax = UserSettings.fromMap({'taxRate': 28.0});
      expect(highTax.taxRate, 28.0);
    });
  });
}
