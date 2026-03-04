/// Extended UserModel tests — newer fields, copyWith, UserSettings completeness
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/models/user_model.dart';
import '../helpers/test_factories.dart';

void main() {
  // ── UserModel.copyWith — newer fields ──

  group('UserModel.copyWith newer fields', () {
    test('overrides upiId', () {
      final u = makeUser();
      final copy = u.copyWith(upiId: 'user@upi');
      expect(copy.upiId, 'user@upi');
    });

    test('overrides profileImagePath', () {
      final u = makeUser();
      final copy = u.copyWith(profileImagePath: '/path/to/img.jpg');
      expect(copy.profileImagePath, '/path/to/img.jpg');
    });

    test('overrides photoUrl', () {
      final u = makeUser();
      final copy = u.copyWith(photoUrl: 'https://example.com/photo.jpg');
      expect(copy.photoUrl, 'https://example.com/photo.jpg');
    });

    test('overrides isPaid', () {
      final u = makeUser();
      final copy = u.copyWith(isPaid: true);
      expect(copy.isPaid, true);
    });

    test('overrides phoneVerified', () {
      final u = makeUser();
      final copy = u.copyWith(phoneVerified: true);
      expect(copy.phoneVerified, true);
    });

    test('overrides emailVerified', () {
      final u = makeUser();
      final copy = u.copyWith(emailVerified: true);
      expect(copy.emailVerified, true);
    });

    test('overrides phoneVerifiedAt', () {
      final u = makeUser();
      final when = DateTime(2024, 6, 15);
      final copy = u.copyWith(phoneVerifiedAt: when);
      expect(copy.phoneVerifiedAt, when);
    });

    test('preserves all other fields', () {
      final u = makeUser();
      final copy = u.copyWith(isPaid: true);
      expect(copy.shopName, u.shopName);
      expect(copy.ownerName, u.ownerName);
      expect(copy.phone, u.phone);
      expect(copy.createdAt, u.createdAt);
    });

    test('sets updatedAt on copy', () {
      final u = makeUser();
      final before = DateTime.now();
      final copy = u.copyWith(shopName: 'New Shop');
      final after = DateTime.now();
      expect(copy.updatedAt, isNotNull);
      expect(
        copy.updatedAt!.isAfter(before.subtract(const Duration(seconds: 1))),
        true,
      );
      expect(
        copy.updatedAt!.isBefore(after.add(const Duration(seconds: 1))),
        true,
      );
    });
  });

  // ── UserSettings complete field coverage ──

  group('UserSettings complete fields', () {
    test('defaults for all fields', () {
      const s = UserSettings();
      expect(s.language, 'hi');
      expect(s.darkMode, false);
      expect(s.autoPrint, false);
      expect(s.printPreview, true);
      expect(s.soundEnabled, true);
      expect(s.notificationsEnabled, true);
      expect(s.lowStockAlerts, true);
      expect(s.subscriptionAlerts, true);
      expect(s.dailySummary, true);
      expect(s.printerAddress, isNull);
      expect(s.billSize, '58mm');
      expect(s.gstEnabled, true);
      expect(s.taxRate, 5.0);
      expect(s.receiptFooter, 'Thank you for shopping!');
    });

    test('toMap includes all fields', () {
      const s = UserSettings(
        lowStockAlerts: false,
        subscriptionAlerts: false,
        dailySummary: false,
        printerAddress: 'AA:BB:CC:DD:EE:FF',
      );
      final map = s.toMap();
      expect(map['lowStockAlerts'], false);
      expect(map['subscriptionAlerts'], false);
      expect(map['dailySummary'], false);
      expect(map['printerAddress'], 'AA:BB:CC:DD:EE:FF');
    });

    test('fromMap handles all fields', () {
      final s = UserSettings.fromMap({
        'language': 'en',
        'darkMode': true,
        'autoPrint': true,
        'printPreview': false,
        'soundEnabled': false,
        'notificationsEnabled': false,
        'lowStockAlerts': false,
        'subscriptionAlerts': false,
        'dailySummary': false,
        'printerAddress': 'AA:BB:CC',
        'billSize': '80mm',
        'gstEnabled': false,
        'taxRate': 18.0,
        'receiptFooter': 'Custom footer',
      });
      expect(s.language, 'en');
      expect(s.darkMode, true);
      expect(s.autoPrint, true);
      expect(s.printPreview, false);
      expect(s.soundEnabled, false);
      expect(s.notificationsEnabled, false);
      expect(s.lowStockAlerts, false);
      expect(s.subscriptionAlerts, false);
      expect(s.dailySummary, false);
      expect(s.printerAddress, 'AA:BB:CC');
      expect(s.billSize, '80mm');
      expect(s.gstEnabled, false);
      expect(s.taxRate, 18.0);
      expect(s.receiptFooter, 'Custom footer');
    });

    test('fromMap with empty map uses defaults', () {
      final s = UserSettings.fromMap({});
      expect(s.lowStockAlerts, true);
      expect(s.subscriptionAlerts, true);
      expect(s.dailySummary, true);
      expect(s.printerAddress, isNull);
    });

    test('copyWith overrides individual alert fields', () {
      const s = UserSettings();
      final copy = s.copyWith(
        lowStockAlerts: false,
        subscriptionAlerts: false,
        dailySummary: false,
        printerAddress: 'XX:YY:ZZ',
      );
      expect(copy.lowStockAlerts, false);
      expect(copy.subscriptionAlerts, false);
      expect(copy.dailySummary, false);
      expect(copy.printerAddress, 'XX:YY:ZZ');
      // Other fields preserved
      expect(copy.language, 'hi');
      expect(copy.soundEnabled, true);
    });

    test('toMap → fromMap roundtrip preserves all fields', () {
      const original = UserSettings(
        language: 'en',
        darkMode: true,
        autoPrint: true,
        printPreview: false,
        soundEnabled: false,
        notificationsEnabled: false,
        lowStockAlerts: false,
        subscriptionAlerts: false,
        dailySummary: false,
        printerAddress: 'bt-address',
        billSize: '80mm',
        gstEnabled: false,
        taxRate: 12.0,
        receiptFooter: 'Thanks!',
      );
      final map = original.toMap();
      final restored = UserSettings.fromMap(map);
      expect(restored.language, original.language);
      expect(restored.darkMode, original.darkMode);
      expect(restored.autoPrint, original.autoPrint);
      expect(restored.printPreview, original.printPreview);
      expect(restored.soundEnabled, original.soundEnabled);
      expect(restored.notificationsEnabled, original.notificationsEnabled);
      expect(restored.lowStockAlerts, original.lowStockAlerts);
      expect(restored.subscriptionAlerts, original.subscriptionAlerts);
      expect(restored.dailySummary, original.dailySummary);
      expect(restored.printerAddress, original.printerAddress);
      expect(restored.billSize, original.billSize);
      expect(restored.gstEnabled, original.gstEnabled);
      expect(restored.taxRate, original.taxRate);
      expect(restored.receiptFooter, original.receiptFooter);
    });
  });
}
