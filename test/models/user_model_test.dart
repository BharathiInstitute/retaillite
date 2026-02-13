import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('should create with required fields', () {
      final user = UserModel(
        id: 'u1',
        shopName: 'Test Shop',
        ownerName: 'Test Owner',
        email: 'test@example.com',
        phone: '9876543210',
        settings: const UserSettings(),
        createdAt: DateTime(2024),
      );

      expect(user.id, 'u1');
      expect(user.shopName, 'Test Shop');
      expect(user.ownerName, 'Test Owner');
      expect(user.email, 'test@example.com');
      expect(user.phone, '9876543210');
      expect(user.address, isNull);
      expect(user.gstNumber, isNull);
      expect(user.shopLogoPath, isNull);
    });

    test('should create with all optional fields', () {
      final user = UserModel(
        id: 'u2',
        shopName: 'Full Shop',
        ownerName: 'Full Owner',
        email: 'full@example.com',
        phone: '1234567890',
        address: '123 Main Street',
        gstNumber: '29ABCDE1234F1Z5',
        shopLogoPath: '/path/to/logo.png',
        settings: const UserSettings(),
        createdAt: DateTime(2024, 6, 15),
      );

      expect(user.address, '123 Main Street');
      expect(user.gstNumber, '29ABCDE1234F1Z5');
      expect(user.shopLogoPath, '/path/to/logo.png');
    });

    test('should serialize to map correctly', () {
      final user = UserModel(
        id: 'u3',
        shopName: 'Map Shop',
        ownerName: 'Map Owner',
        email: 'map@example.com',
        phone: '5555555555',
        address: 'Test Address',
        gstNumber: 'GST123',
        settings: const UserSettings(),
        createdAt: DateTime(2024),
      );

      final map = user.toFirestore();
      expect(map['shopName'], 'Map Shop');
      expect(map['ownerName'], 'Map Owner');
      expect(map['email'], 'map@example.com');
      expect(map['phone'], '5555555555');
      expect(map['address'], 'Test Address');
      expect(map['gstNumber'], 'GST123');
    });

    test('should copyWith preserve unchanged fields', () {
      final original = UserModel(
        id: 'u4',
        shopName: 'Original Shop',
        ownerName: 'Original Owner',
        email: 'original@example.com',
        phone: '1111111111',
        settings: const UserSettings(),
        createdAt: DateTime(2024),
      );

      final updated = original.copyWith(shopName: 'Updated Shop');

      expect(updated.shopName, 'Updated Shop');
      expect(updated.ownerName, 'Original Owner');
      expect(updated.email, 'original@example.com');
      expect(updated.phone, '1111111111');
      expect(updated.id, 'u4');
    });

    test('should copyWith update multiple fields', () {
      final original = UserModel(
        id: 'u5',
        shopName: 'Shop',
        ownerName: 'Owner',
        email: 'test@test.com',
        phone: '0000000000',
        settings: const UserSettings(),
        createdAt: DateTime(2024),
      );

      final updated = original.copyWith(
        shopName: 'New Shop',
        ownerName: 'New Owner',
        address: 'New Address',
        gstNumber: 'NEW_GST',
        shopLogoPath: '/new/logo.png',
      );

      expect(updated.shopName, 'New Shop');
      expect(updated.ownerName, 'New Owner');
      expect(updated.address, 'New Address');
      expect(updated.gstNumber, 'NEW_GST');
      expect(updated.shopLogoPath, '/new/logo.png');
    });
  });

  group('UserSettings', () {
    test('should have sensible defaults', () {
      const settings = UserSettings();

      expect(settings.language, 'hi');
      expect(settings.darkMode, false);
      expect(settings.autoPrint, false);
      expect(settings.printPreview, true);
      expect(settings.soundEnabled, true);
      expect(settings.notificationsEnabled, true);
      expect(settings.printerAddress, isNull);
      expect(settings.billSize, '58mm');
      expect(settings.gstEnabled, true);
      expect(settings.taxRate, 5.0);
      expect(settings.receiptFooter, 'Thank you for shopping!');
    });

    test('should serialize defaults to map', () {
      const settings = UserSettings();
      final map = settings.toMap();

      expect(map['language'], 'hi');
      expect(map['darkMode'], false);
      expect(map['soundEnabled'], true);
      expect(map['notificationsEnabled'], true);
      expect(map['gstEnabled'], true);
      expect(map['taxRate'], 5.0);
      expect(map['billSize'], '58mm');
    });

    test('should deserialize from map', () {
      final settings = UserSettings.fromMap({
        'language': 'en',
        'darkMode': true,
        'soundEnabled': false,
        'notificationsEnabled': false,
        'gstEnabled': false,
        'taxRate': 18.0,
        'billSize': '80mm',
        'receiptFooter': 'Custom footer',
      });

      expect(settings.language, 'en');
      expect(settings.darkMode, true);
      expect(settings.soundEnabled, false);
      expect(settings.notificationsEnabled, false);
      expect(settings.gstEnabled, false);
      expect(settings.taxRate, 18.0);
      expect(settings.billSize, '80mm');
      expect(settings.receiptFooter, 'Custom footer');
    });

    test('should handle empty map with defaults', () {
      final settings = UserSettings.fromMap({});

      expect(settings.language, 'hi');
      expect(settings.darkMode, false);
      expect(settings.soundEnabled, true);
      expect(settings.notificationsEnabled, true);
      expect(settings.gstEnabled, true);
      expect(settings.taxRate, 5.0);
    });

    test('should copyWith update specific fields', () {
      const original = UserSettings();
      final updated = original.copyWith(
        language: 'en',
        darkMode: true,
        taxRate: 12.0,
      );

      expect(updated.language, 'en');
      expect(updated.darkMode, true);
      expect(updated.taxRate, 12.0);
      // unchanged
      expect(updated.soundEnabled, true);
      expect(updated.notificationsEnabled, true);
      expect(updated.gstEnabled, true);
    });

    test('should round-trip through toMap/fromMap', () {
      const original = UserSettings(
        language: 'en',
        darkMode: true,
        autoPrint: true,
        printPreview: false,
        soundEnabled: false,
        notificationsEnabled: false,
        billSize: '80mm',
        gstEnabled: false,
        taxRate: 12.0,
        receiptFooter: 'Visit again!',
      );

      final restored = UserSettings.fromMap(original.toMap());

      expect(restored.language, original.language);
      expect(restored.darkMode, original.darkMode);
      expect(restored.autoPrint, original.autoPrint);
      expect(restored.printPreview, original.printPreview);
      expect(restored.soundEnabled, original.soundEnabled);
      expect(restored.notificationsEnabled, original.notificationsEnabled);
      expect(restored.billSize, original.billSize);
      expect(restored.gstEnabled, original.gstEnabled);
      expect(restored.taxRate, original.taxRate);
      expect(restored.receiptFooter, original.receiptFooter);
    });
  });
}
