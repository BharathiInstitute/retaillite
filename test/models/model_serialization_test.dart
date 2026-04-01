/// Round-trip serialization tests for all models with toMap/fromMap support.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/models/bill_model.dart';
import 'package:retaillite/models/expense_model.dart';
import 'package:retaillite/models/theme_settings_model.dart';
import 'package:retaillite/models/user_model.dart';

void main() {
  // ---- CartItem toMap/fromMap ----
  group('CartItem serialization', () {
    test('round-trip with all fields', () {
      const original = CartItem(
        productId: 'p1',
        name: 'Basmati Rice',
        price: 85.50,
        quantity: 3,
        unit: 'kg',
      );
      final map = original.toMap();
      final restored = CartItem.fromMap(map);
      expect(restored.productId, original.productId);
      expect(restored.name, original.name);
      expect(restored.price, original.price);
      expect(restored.quantity, original.quantity);
      expect(restored.unit, original.unit);
    });

    test('fromMap with missing fields uses defaults', () {
      final restored = CartItem.fromMap(<String, dynamic>{});
      expect(restored.productId, '');
      expect(restored.name, '');
      expect(restored.price, 0.0);
      expect(restored.quantity, 1);
      expect(restored.unit, 'pcs');
    });

    test('round-trip with zero price', () {
      const item = CartItem(
        productId: 'p2',
        name: 'Free Sample',
        price: 0.0,
        quantity: 1,
        unit: 'piece',
      );
      final restored = CartItem.fromMap(item.toMap());
      expect(restored.price, 0.0);
    });

    test('round-trip with large quantity', () {
      const item = CartItem(
        productId: 'p3',
        name: 'Bulk',
        price: 10,
        quantity: 9999,
        unit: 'piece',
      );
      final restored = CartItem.fromMap(item.toMap());
      expect(restored.quantity, 9999);
    });

    test('round-trip preserves unicode name', () {
      const item = CartItem(
        productId: 'p4',
        name: 'चावल',
        price: 50,
        quantity: 1,
        unit: 'kg',
      );
      final restored = CartItem.fromMap(item.toMap());
      expect(restored.name, 'चावल');
    });
  });

  // ---- BillModel toMap ----
  group('BillModel toMap structure', () {
    BillModel makeBill({
      String? customerId,
      String? customerName,
      double? receivedAmount,
      PaymentMethod method = PaymentMethod.cash,
    }) {
      return BillModel(
        id: 'bill_1',
        billNumber: 42,
        items: [
          const CartItem(
            productId: 'p1',
            name: 'Rice',
            price: 50,
            quantity: 2,
            unit: 'kg',
          ),
        ],
        total: 100.0,
        paymentMethod: method,
        customerId: customerId,
        customerName: customerName,
        receivedAmount: receivedAmount,
        createdAt: DateTime(2024, 6, 15, 10, 30),
        date: '2024-06-15',
      );
    }

    test('toMap contains all required keys', () {
      final map = makeBill().toMap();
      expect(map, containsPair('id', 'bill_1'));
      expect(map, containsPair('billNumber', 42));
      expect(map, containsPair('total', 100.0));
      expect(map, containsPair('paymentMethod', 'cash'));
      expect(map, containsPair('date', '2024-06-15'));
      expect(map['items'], isList);
      expect((map['items'] as List).length, 1);
    });

    test('toMap serializes createdAt as ISO 8601', () {
      final map = makeBill().toMap();
      final createdAt = map['createdAt'] as String;
      expect(DateTime.tryParse(createdAt), isNotNull);
    });

    test('toMap with null optionals', () {
      final map = makeBill(customerName: null).toMap();
      expect(map['customerId'], isNull);
      expect(map['customerName'], isNull);
      expect(map['receivedAmount'], isNull);
    });

    test('toMap with all optionals set', () {
      final map = makeBill(
        customerId: 'cust_1',
        customerName: 'Rajesh',
        receivedAmount: 200.0,
      ).toMap();
      expect(map['customerId'], 'cust_1');
      expect(map['customerName'], 'Rajesh');
      expect(map['receivedAmount'], 200.0);
    });

    test('toMap serializes all PaymentMethod values', () {
      for (final method in PaymentMethod.values) {
        final map = makeBill(method: method).toMap();
        expect(map['paymentMethod'], method.name);
      }
    });

    test('toMap serializes nested CartItem list', () {
      final bill = BillModel(
        id: 'bill_2',
        billNumber: 43,
        items: [
          const CartItem(
            productId: 'p1',
            name: 'Rice',
            price: 50,
            quantity: 2,
            unit: 'kg',
          ),
          const CartItem(
            productId: 'p2',
            name: 'Dal',
            price: 80,
            quantity: 1,
            unit: 'kg',
          ),
        ],
        total: 180.0,
        paymentMethod: PaymentMethod.upi,
        createdAt: DateTime(2024, 6, 15),
        date: '2024-06-15',
      );
      final map = bill.toMap();
      final items = map['items'] as List;
      expect(items.length, 2);
      expect((items[0] as Map)['name'], 'Rice');
      expect((items[1] as Map)['name'], 'Dal');
    });

    test('toMap with empty items list', () {
      final bill = BillModel(
        id: 'bill_3',
        billNumber: 44,
        items: const [],
        total: 0.0,
        paymentMethod: PaymentMethod.cash,
        createdAt: DateTime(2024, 1),
        date: '2024-01-01',
      );
      final map = bill.toMap();
      expect((map['items'] as List), isEmpty);
    });
  });

  // ---- ExpenseModel toMap/fromMap ----
  group('ExpenseModel serialization', () {
    test('round-trip with all fields', () {
      final original = ExpenseModel(
        id: 'exp_1',
        amount: 5000.0,
        category: ExpenseCategory.rent,
        description: 'Monthly shop rent',
        paymentMethod: PaymentMethod.upi,
        createdAt: DateTime(2024, 6, 1, 9),
        date: '2024-06-01',
      );
      final map = original.toMap();
      final restored = ExpenseModel.fromMap(map);
      expect(restored.id, original.id);
      expect(restored.amount, original.amount);
      expect(restored.category, original.category);
      expect(restored.description, original.description);
      expect(restored.paymentMethod, original.paymentMethod);
      expect(restored.date, original.date);
    });

    test('round-trip preserves createdAt through ISO 8601', () {
      final original = ExpenseModel(
        id: 'exp_2',
        amount: 100.0,
        category: ExpenseCategory.supplies,
        paymentMethod: PaymentMethod.cash,
        createdAt: DateTime(2024, 12, 31, 23, 59, 59),
        date: '2024-12-31',
      );
      final restored = ExpenseModel.fromMap(original.toMap());
      expect(restored.createdAt.year, 2024);
      expect(restored.createdAt.month, 12);
      expect(restored.createdAt.day, 31);
    });

    test('round-trip with null description', () {
      final original = ExpenseModel(
        id: 'exp_3',
        amount: 250.0,
        category: ExpenseCategory.transport,
        paymentMethod: PaymentMethod.cash,
        createdAt: DateTime(2024, 3, 15),
        date: '2024-03-15',
      );
      final restored = ExpenseModel.fromMap(original.toMap());
      expect(restored.description, isNull);
    });

    test('fromMap with missing fields uses defaults', () {
      final restored = ExpenseModel.fromMap(<String, dynamic>{});
      expect(restored.id, '');
      expect(restored.amount, 0.0);
      expect(restored.category, ExpenseCategory.other);
      expect(restored.paymentMethod, PaymentMethod.cash);
    });

    test('round-trip all ExpenseCategory values', () {
      for (final cat in ExpenseCategory.values) {
        final expense = ExpenseModel(
          id: 'e',
          amount: 10,
          category: cat,
          paymentMethod: PaymentMethod.cash,
          createdAt: DateTime(2024),
          date: '2024-01-01',
        );
        final restored = ExpenseModel.fromMap(expense.toMap());
        expect(restored.category, cat);
      }
    });

    test('round-trip with zero amount', () {
      final expense = ExpenseModel(
        id: 'exp_zero',
        amount: 0.0,
        category: ExpenseCategory.other,
        paymentMethod: PaymentMethod.cash,
        createdAt: DateTime(2024),
        date: '2024-01-01',
      );
      final restored = ExpenseModel.fromMap(expense.toMap());
      expect(restored.amount, 0.0);
    });
  });

  // ---- ThemeSettingsModel toJson/fromJson ----
  group('ThemeSettingsModel serialization', () {
    test('round-trip with defaults', () {
      const original = ThemeSettingsModel();
      final json = original.toJson();
      final restored = ThemeSettingsModel.fromJson(json);
      expect(restored.primaryColorHex, original.primaryColorHex);
      expect(restored.fontFamily, original.fontFamily);
      expect(restored.fontSizeScale, original.fontSizeScale);
      expect(restored.useDarkMode, original.useDarkMode);
      expect(restored.useSystemTheme, original.useSystemTheme);
    });

    test('round-trip with custom values', () {
      const original = ThemeSettingsModel(
        primaryColorHex: '#3B82F6',
        fontFamily: 'Poppins',
        fontSizeScale: 1.2,
        useDarkMode: true,
      );
      final restored = ThemeSettingsModel.fromJson(original.toJson());
      expect(restored.primaryColorHex, '#3B82F6');
      expect(restored.fontFamily, 'Poppins');
      expect(restored.fontSizeScale, 1.2);
      expect(restored.useDarkMode, isTrue);
    });

    test('fromJson with empty map uses defaults', () {
      final restored = ThemeSettingsModel.fromJson(<String, dynamic>{});
      expect(restored.primaryColorHex, '#10B981');
      expect(restored.fontFamily, 'Inter');
      expect(restored.fontSizeScale, 1.0);
      expect(restored.useDarkMode, isFalse);
      expect(restored.useSystemTheme, isFalse);
    });

    test('round-trip with small font scale', () {
      const original = ThemeSettingsModel(fontSizeScale: 0.8);
      final restored = ThemeSettingsModel.fromJson(original.toJson());
      expect(restored.fontSizeScale, 0.8);
    });

    test('all color presets are valid hex', () {
      for (final hex in ThemeSettingsModel.colorPresets) {
        expect(hex, startsWith('#'));
        expect(hex.length, 7);
        final parsed = int.tryParse(hex.substring(1), radix: 16);
        expect(parsed, isNotNull, reason: '$hex is not valid hex');
      }
    });
  });

  // ---- UserSettings toMap/fromMap ----
  group('UserSettings serialization', () {
    test('round-trip with defaults', () {
      const original = UserSettings();
      final map = original.toMap();
      final restored = UserSettings.fromMap(map);
      expect(restored.language, 'hi');
      expect(restored.darkMode, isFalse);
      expect(restored.autoPrint, isFalse);
      expect(restored.printPreview, isTrue);
      expect(restored.soundEnabled, isTrue);
      expect(restored.notificationsEnabled, isTrue);
      expect(restored.lowStockAlerts, isTrue);
      expect(restored.subscriptionAlerts, isTrue);
      expect(restored.dailySummary, isTrue);
      expect(restored.printerAddress, isNull);
      expect(restored.billSize, '58mm');
      expect(restored.gstEnabled, isTrue);
      expect(restored.taxRate, 5.0);
      expect(restored.receiptFooter, 'Thank you for shopping!');
    });

    test('round-trip with all custom values', () {
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
        printerAddress: '00:11:22:33:44:55',
        billSize: '80mm',
        gstEnabled: false,
        taxRate: 18.0,
        receiptFooter: 'Thanks!',
      );
      final restored = UserSettings.fromMap(original.toMap());
      expect(restored.language, 'en');
      expect(restored.darkMode, isTrue);
      expect(restored.autoPrint, isTrue);
      expect(restored.printPreview, isFalse);
      expect(restored.soundEnabled, isFalse);
      expect(restored.notificationsEnabled, isFalse);
      expect(restored.lowStockAlerts, isFalse);
      expect(restored.subscriptionAlerts, isFalse);
      expect(restored.dailySummary, isFalse);
      expect(restored.printerAddress, '00:11:22:33:44:55');
      expect(restored.billSize, '80mm');
      expect(restored.gstEnabled, isFalse);
      expect(restored.taxRate, 18.0);
      expect(restored.receiptFooter, 'Thanks!');
    });

    test('fromMap with empty map uses defaults', () {
      final restored = UserSettings.fromMap(<String, dynamic>{});
      expect(restored.language, 'hi');
      expect(restored.darkMode, isFalse);
      expect(restored.billSize, '58mm');
      expect(restored.taxRate, 5.0);
    });

    test('round-trip with null printerAddress', () {
      const original = UserSettings();
      final restored = UserSettings.fromMap(original.toMap());
      expect(restored.printerAddress, isNull);
    });

    test('round-trip with custom tax rate', () {
      const original = UserSettings(taxRate: 12.5);
      final restored = UserSettings.fromMap(original.toMap());
      expect(restored.taxRate, 12.5);
    });

    test('round-trip with empty receipt footer', () {
      const original = UserSettings(receiptFooter: '');
      final restored = UserSettings.fromMap(original.toMap());
      expect(restored.receiptFooter, '');
    });
  });

  // ---- Enum serialization ----
  group('Enum serialization', () {
    test('PaymentMethod.fromString round-trips all values', () {
      for (final method in PaymentMethod.values) {
        final restored = PaymentMethod.fromString(method.name);
        expect(restored, method);
      }
    });

    test('PaymentMethod.fromString returns unknown for invalid input', () {
      expect(PaymentMethod.fromString('bitcoin'), PaymentMethod.unknown);
      expect(PaymentMethod.fromString(''), PaymentMethod.unknown);
    });

    test('ExpenseCategory.fromString round-trips all values', () {
      for (final cat in ExpenseCategory.values) {
        final restored = ExpenseCategory.fromString(cat.name);
        expect(restored, cat);
      }
    });

    test('ExpenseCategory.fromString returns other for invalid input', () {
      expect(ExpenseCategory.fromString('food'), ExpenseCategory.other);
      expect(ExpenseCategory.fromString(''), ExpenseCategory.other);
    });
  });

  // ---- DateTime boundary tests ----
  group('DateTime boundaries in serialization', () {
    test('BillModel toMap handles epoch date', () {
      final bill = BillModel(
        id: 'b',
        billNumber: 1,
        items: const [],
        total: 0,
        paymentMethod: PaymentMethod.cash,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        date: '1970-01-01',
      );
      final map = bill.toMap();
      expect(DateTime.tryParse(map['createdAt'] as String), isNotNull);
    });

    test('ExpenseModel roundtrip with year-end boundary', () {
      final original = ExpenseModel(
        id: 'exp',
        amount: 10,
        category: ExpenseCategory.other,
        paymentMethod: PaymentMethod.cash,
        createdAt: DateTime(2024, 12, 31, 23, 59, 59),
        date: '2024-12-31',
      );
      final restored = ExpenseModel.fromMap(original.toMap());
      expect(restored.createdAt.year, 2024);
      expect(restored.createdAt.month, 12);
      expect(restored.createdAt.day, 31);
      expect(restored.createdAt.hour, 23);
      expect(restored.createdAt.minute, 59);
    });

    test('ExpenseModel roundtrip with new year start', () {
      final original = ExpenseModel(
        id: 'exp',
        amount: 10,
        category: ExpenseCategory.other,
        paymentMethod: PaymentMethod.cash,
        createdAt: DateTime(2025, 1, 1, 0, 0),
        date: '2025-01-01',
      );
      final restored = ExpenseModel.fromMap(original.toMap());
      expect(restored.createdAt.year, 2025);
      expect(restored.createdAt.month, 1);
      expect(restored.createdAt.day, 1);
    });
  });
}
