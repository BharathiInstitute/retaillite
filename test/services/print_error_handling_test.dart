/// Error, edge-case, and resilience tests for printing subsystem models
library;

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/services/thermal_printer_service.dart';
import 'package:retaillite/models/bill_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reuse extractText from receipt_content_test
String extractText(List<int> bytes) {
  final textBytes = <int>[];
  var i = 0;
  while (i < bytes.length) {
    final b = bytes[i];
    if (b == 0x1B && i + 1 < bytes.length) {
      final cmd = bytes[i + 1];
      if (cmd == 0x40) {
        i += 2;
      } else if (cmd == 0x74 || cmd == 0x61 || cmd == 0x45 || cmd == 0x21) {
        i += 3;
      } else if (cmd == 0x64) {
        i += 3;
      } else {
        i += 3;
      }
      continue;
    }
    if (b == 0x1D && i + 1 < bytes.length) {
      i += 3;
      continue;
    }
    textBytes.add(b);
    i++;
  }
  return utf8.decode(textBytes, allowMalformed: true);
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({
      'printer_paper_size': 1,
      'printer_font_size': 1,
      'printer_custom_width': 0,
    });
  });

  // ─────────────────────────────────────────────────────
  // PrinterPaperSize enum
  // ─────────────────────────────────────────────────────
  group('PrinterPaperSize', () {
    test('mm58 has 32 chars per line', () {
      expect(PrinterPaperSize.mm58.charsPerLine, 32);
    });

    test('mm80 has 48 chars per line', () {
      expect(PrinterPaperSize.mm80.charsPerLine, 48);
    });

    test('fromIndex 0 → mm58', () {
      expect(PrinterPaperSize.fromIndex(0), PrinterPaperSize.mm58);
    });

    test('fromIndex 1 → mm80', () {
      expect(PrinterPaperSize.fromIndex(1), PrinterPaperSize.mm80);
    });

    test('fromIndex any other → mm80 (default)', () {
      expect(PrinterPaperSize.fromIndex(99), PrinterPaperSize.mm80);
    });
  });

  // ─────────────────────────────────────────────────────
  // PrinterFontSizeMode enum
  // ─────────────────────────────────────────────────────
  group('PrinterFontSizeMode', () {
    test('fromValue 0 → small', () {
      expect(PrinterFontSizeMode.fromValue(0), PrinterFontSizeMode.small);
    });

    test('fromValue 1 → normal', () {
      expect(PrinterFontSizeMode.fromValue(1), PrinterFontSizeMode.normal);
    });

    test('fromValue 2 → large', () {
      expect(PrinterFontSizeMode.fromValue(2), PrinterFontSizeMode.large);
    });

    test('fromValue unknown → normal', () {
      expect(PrinterFontSizeMode.fromValue(42), PrinterFontSizeMode.normal);
    });
  });

  // ─────────────────────────────────────────────────────
  // PrinterDevice
  // ─────────────────────────────────────────────────────
  group('PrinterDevice', () {
    test('toJson and fromJson round-trip', () {
      const device = PrinterDevice(
        name: 'BT-58 Printer',
        address: '11:22:33:44:55:66',
      );
      final json = device.toJson();
      final restored = PrinterDevice.fromJson(json);
      expect(restored.name, device.name);
      expect(restored.address, device.address);
    });

    test('toJson produces correct keys', () {
      const device = PrinterDevice(
        name: 'Wifi Printer',
        address: '192.168.1.5:9100',
      );
      final json = device.toJson();
      expect(json, containsPair('name', 'Wifi Printer'));
      expect(json, containsPair('address', '192.168.1.5:9100'));
    });
  });

  // ─────────────────────────────────────────────────────
  // EscPosBuilder — ESC/POS commands structural tests
  // ─────────────────────────────────────────────────────
  group('EscPosBuilder — command bytes', () {
    test('init starts with ESC @', () {
      final bytes = EscPosBuilder.init();
      expect(bytes[0], 0x1B);
      expect(bytes[1], 0x40);
    });

    test('cut uses GS V 0', () {
      final bytes = EscPosBuilder.cut();
      expect(bytes[0], 0x1D);
      expect(bytes[1], 0x56);
      expect(bytes[2], 0x00);
    });

    test('bold on sends ESC E 1', () {
      final bytes = EscPosBuilder.bold(true);
      expect(bytes, [0x1B, 0x45, 0x01]);
    });

    test('bold off sends ESC E 0', () {
      final bytes = EscPosBuilder.bold(false);
      expect(bytes, [0x1B, 0x45, 0x00]);
    });

    test('center sends ESC a 1', () {
      expect(EscPosBuilder.center(), [0x1B, 0x61, 0x01]);
    });

    test('left sends ESC a 0', () {
      expect(EscPosBuilder.left(), [0x1B, 0x61, 0x00]);
    });

    test('feed sends ESC d n', () {
      expect(EscPosBuilder.feed(3), [0x1B, 0x64, 0x03]);
    });

    test('doubleHeight on sends ESC ! 0x10', () {
      expect(EscPosBuilder.doubleHeight(true), [0x1B, 0x21, 0x10]);
    });

    test('doubleHeight off sends ESC ! 0x00', () {
      expect(EscPosBuilder.doubleHeight(false), [0x1B, 0x21, 0x00]);
    });
  });

  // ─────────────────────────────────────────────────────
  // EscPosBuilder.text — encoding
  // ─────────────────────────────────────────────────────
  group('EscPosBuilder.text — encoding', () {
    test('ASCII text encodes correctly', () {
      final bytes = EscPosBuilder.text('Hello\n');
      expect(utf8.decode(bytes), 'Hello\n');
    });

    test('Rupee symbol encodes as multi-byte UTF-8', () {
      final bytes = EscPosBuilder.text('₹100');
      expect(bytes.length, greaterThan(4)); // ₹ is 3 bytes in UTF-8
      expect(utf8.decode(bytes), '₹100');
    });

    test('Hindi text encodes correctly', () {
      final bytes = EscPosBuilder.text('नमस्ते');
      expect(utf8.decode(bytes), 'नमस्ते');
    });
  });

  // ─────────────────────────────────────────────────────
  // EscPosBuilder.formatLine — alignment
  // ─────────────────────────────────────────────────────
  group('EscPosBuilder.formatLine — alignment', () {
    test('pads to exact width', () {
      final line = EscPosBuilder.formatLine('A', 'B', 'C', 20);
      // strip trailing newline; total visible length should be ~20
      expect(line, endsWith('\n'));
      expect(line.trimRight().length, 20);
    });

    test('overflows gracefully when content wider than width', () {
      final line = EscPosBuilder.formatLine(
        'Long Item Name Here',
        'x10',
        '99999',
        20,
      );
      // should not crash; uses space-separated fallback
      expect(line, contains('Long Item Name Here'));
      expect(line, endsWith('\n'));
    });

    test('handles empty strings', () {
      final line = EscPosBuilder.formatLine('', '', '', 32);
      expect(line, endsWith('\n'));
    });
  });

  // ─────────────────────────────────────────────────────
  // EscPosBuilder.fontSize — mode bytes
  // ─────────────────────────────────────────────────────
  group('EscPosBuilder.fontSize', () {
    test('small mode produces ESC ! 0x01', () {
      expect(EscPosBuilder.fontSize(PrinterFontSizeMode.small), [
        0x1B,
        0x21,
        0x01,
      ]);
    });

    test('normal mode produces ESC ! 0x00', () {
      expect(EscPosBuilder.fontSize(PrinterFontSizeMode.normal), [
        0x1B,
        0x21,
        0x00,
      ]);
    });

    test('large mode produces ESC ! 0x10', () {
      expect(EscPosBuilder.fontSize(PrinterFontSizeMode.large), [
        0x1B,
        0x21,
        0x10,
      ]);
    });
  });

  // ─────────────────────────────────────────────────────
  // buildReceipt — stress / edge cases
  // ─────────────────────────────────────────────────────
  group('EscPosBuilder.buildReceipt — stress', () {
    test('50 items does not crash and contains all items', () {
      final items = List.generate(
        50,
        (i) => CartItem(
          productId: 'p$i',
          name: 'StressItem$i',
          price: (i + 1) * 5,
          quantity: i + 1,
          unit: 'pcs',
        ),
      );
      final bill = BillModel(
        id: 'stress',
        billNumber: 9999,
        items: items,
        total: items.fold(0.0, (s, i) => s + i.total),
        paymentMethod: PaymentMethod.cash,
        receivedAmount: 999999,
        createdAt: DateTime(2026),
        date: '2026-01-01',
      );
      final bytes = EscPosBuilder.buildReceipt(bill: bill);
      final text = extractText(bytes);
      expect(text, contains('StressItem0'));
      expect(text, contains('StressItem49'));
      expect(text, contains('TOTAL'));
    });

    test('special characters in shop name', () {
      final bill = BillModel(
        id: 'sp',
        billNumber: 1,
        items: const [],
        total: 0,
        paymentMethod: PaymentMethod.cash,
        createdAt: DateTime(2026),
        date: '2026-01-01',
      );
      final bytes = EscPosBuilder.buildReceipt(
        bill: bill,
        shopName: 'Ravi\'s "Super" Store',
      );
      final text = extractText(bytes);
      expect(text, contains('Ravi'));
      expect(text, contains('Super'));
    });

    test('very long product name does not crash', () {
      final bill = BillModel(
        id: 'long',
        billNumber: 2,
        items: [
          CartItem(
            productId: 'l1',
            name: 'A' * 100, // 100-char product name
            price: 99,
            quantity: 1,
            unit: 'pc',
          ),
        ],
        total: 99,
        paymentMethod: PaymentMethod.cash,
        createdAt: DateTime(2026),
        date: '2026-01-01',
      );
      final bytes = EscPosBuilder.buildReceipt(bill: bill);
      expect(bytes, isNotEmpty);
    });

    test('zero-price item renders correctly', () {
      final bill = BillModel(
        id: 'free',
        billNumber: 3,
        items: const [
          CartItem(
            productId: 'f1',
            name: 'Free Sample',
            price: 0,
            quantity: 1,
            unit: 'pc',
          ),
        ],
        total: 0,
        paymentMethod: PaymentMethod.cash,
        createdAt: DateTime(2026),
        date: '2026-01-01',
      );
      final bytes = EscPosBuilder.buildReceipt(bill: bill);
      final text = extractText(bytes);
      expect(text, contains('Free Sample'));
      expect(text, contains('@0'));
    });
  });

  // ─────────────────────────────────────────────────────
  // BillModel / CartItem helpers
  // ─────────────────────────────────────────────────────
  group('BillModel helpers', () {
    test('changeAmount computed correctly', () {
      final bill = BillModel(
        id: 'c1',
        billNumber: 1,
        items: const [],
        total: 250,
        paymentMethod: PaymentMethod.cash,
        receivedAmount: 300,
        createdAt: DateTime(2026),
        date: '2026-01-01',
      );
      expect(bill.changeAmount, 50);
    });

    test('itemCount reflects items length', () {
      final bill = BillModel(
        id: 'c2',
        billNumber: 2,
        items: const [
          CartItem(
            productId: 'a',
            name: 'A',
            price: 10,
            quantity: 1,
            unit: 'pc',
          ),
          CartItem(
            productId: 'b',
            name: 'B',
            price: 20,
            quantity: 2,
            unit: 'pc',
          ),
        ],
        total: 50,
        paymentMethod: PaymentMethod.cash,
        createdAt: DateTime(2026),
        date: '2026-01-01',
      );
      expect(bill.itemCount, 3); // sum of quantities: 1 + 2
    });

    test('CartItem.total is price * quantity', () {
      const item = CartItem(
        productId: 'x',
        name: 'X',
        price: 15.5,
        quantity: 4,
        unit: 'pc',
      );
      expect(item.total, closeTo(62.0, 0.01));
    });
  });

  // ─────────────────────────────────────────────────────
  // PaymentMethod enum
  // ─────────────────────────────────────────────────────
  group('PaymentMethod', () {
    test('cash displayName is Cash', () {
      expect(PaymentMethod.cash.displayName, 'Cash');
    });

    test('upi displayName is UPI', () {
      expect(PaymentMethod.upi.displayName, 'UPI');
    });

    test('udhar displayName is Credit', () {
      expect(PaymentMethod.udhar.displayName, 'Credit');
    });

    test('each method has an emoji', () {
      for (final m in PaymentMethod.values) {
        expect(m.emoji, isNotEmpty);
      }
    });
  });
}
