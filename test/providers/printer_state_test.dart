/// Unit tests for PrinterState, PrinterTypeOption, PrinterFontSize
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/features/settings/providers/settings_provider.dart';

void main() {
  // ─────────────────────────────────────────────────────
  // PrinterFontSize
  // ─────────────────────────────────────────────────────
  group('PrinterFontSize', () {
    test('fromValue returns correct enum for known values', () {
      expect(PrinterFontSize.fromValue(0), PrinterFontSize.small);
      expect(PrinterFontSize.fromValue(1), PrinterFontSize.normal);
      expect(PrinterFontSize.fromValue(2), PrinterFontSize.large);
    });

    test('fromValue defaults to normal for unknown value', () {
      expect(PrinterFontSize.fromValue(99), PrinterFontSize.normal);
      expect(PrinterFontSize.fromValue(-1), PrinterFontSize.normal);
    });

    test('each variant has label and description', () {
      for (final size in PrinterFontSize.values) {
        expect(size.label, isNotEmpty);
        expect(size.description, isNotEmpty);
      }
    });
  });

  // ─────────────────────────────────────────────────────
  // PrinterTypeOption
  // ─────────────────────────────────────────────────────
  group('PrinterTypeOption', () {
    test('system is NOT thermal', () {
      expect(PrinterTypeOption.system.isThermal, isFalse);
    });

    test('bluetooth is thermal', () {
      expect(PrinterTypeOption.bluetooth.isThermal, isTrue);
    });

    test('usb is thermal', () {
      expect(PrinterTypeOption.usb.isThermal, isTrue);
    });

    test('wifi is thermal', () {
      expect(PrinterTypeOption.wifi.isThermal, isTrue);
    });

    test('fromString returns correct type for known names', () {
      expect(PrinterTypeOption.fromString('system'), PrinterTypeOption.system);
      expect(
        PrinterTypeOption.fromString('bluetooth'),
        PrinterTypeOption.bluetooth,
      );
      expect(PrinterTypeOption.fromString('usb'), PrinterTypeOption.usb);
      expect(PrinterTypeOption.fromString('wifi'), PrinterTypeOption.wifi);
    });

    test('fromString defaults to system for unknown name', () {
      expect(PrinterTypeOption.fromString('unknown'), PrinterTypeOption.system);
      expect(PrinterTypeOption.fromString(''), PrinterTypeOption.system);
    });

    test('each variant has label and description', () {
      for (final type in PrinterTypeOption.values) {
        expect(type.label, isNotEmpty);
        expect(type.description, isNotEmpty);
      }
    });
  });

  // ─────────────────────────────────────────────────────
  // PrinterState — defaults
  // ─────────────────────────────────────────────────────
  group('PrinterState — defaults', () {
    test('default state is disconnected', () {
      const state = PrinterState();
      expect(state.isConnected, isFalse);
      expect(state.printerName, isNull);
      expect(state.printerAddress, isNull);
    });

    test('default paper size is 80mm', () {
      const state = PrinterState();
      expect(state.paperSizeIndex, 1);
      expect(state.paperSizeLabel, '80mm');
    });

    test('default font size is Normal', () {
      const state = PrinterState();
      expect(state.fontSizeIndex, 1);
      expect(state.fontSize, PrinterFontSize.normal);
    });

    test('default custom width is auto (0)', () {
      const state = PrinterState();
      expect(state.customWidth, 0);
    });

    test('default type is system', () {
      const state = PrinterState();
      expect(state.printerType, PrinterTypeOption.system);
    });

    test('auto-print defaults to false', () {
      const state = PrinterState();
      expect(state.autoPrint, isFalse);
    });

    test('receipt footer defaults to empty', () {
      const state = PrinterState();
      expect(state.receiptFooter, isEmpty);
    });
  });

  // ─────────────────────────────────────────────────────
  // PrinterState — effectiveWidth
  // ─────────────────────────────────────────────────────
  group('PrinterState — effectiveWidth', () {
    test('58mm paper auto width is 32', () {
      const state = PrinterState(paperSizeIndex: 0);
      expect(state.effectiveWidth, 32);
    });

    test('80mm paper auto width is 48', () {
      const state = PrinterState();
      expect(state.effectiveWidth, 48);
    });

    test('custom width overrides auto width', () {
      const state = PrinterState(customWidth: 40);
      expect(state.effectiveWidth, 40);
    });

    test('widthLabel shows auto when customWidth is 0', () {
      const state = PrinterState();
      expect(state.widthLabel, contains('Auto'));
      expect(state.widthLabel, contains('48'));
    });

    test('widthLabel shows custom chars when set', () {
      const state = PrinterState(customWidth: 36);
      expect(state.widthLabel, '36 chars');
    });
  });

  // ─────────────────────────────────────────────────────
  // PrinterState — paperSizeLabel
  // ─────────────────────────────────────────────────────
  group('PrinterState — paperSizeLabel', () {
    test('index 0 → 58mm', () {
      const state = PrinterState(paperSizeIndex: 0);
      expect(state.paperSizeLabel, '58mm');
    });

    test('index 1 → 80mm', () {
      const state = PrinterState();
      expect(state.paperSizeLabel, '80mm');
    });
  });

  // ─────────────────────────────────────────────────────
  // PrinterState — copyWith
  // ─────────────────────────────────────────────────────
  group('PrinterState — copyWith', () {
    const base = PrinterState(
      isConnected: true,
      printerName: 'BT-58',
      printerAddress: '11:22:33:44:55:66',
      paperSizeIndex: 0,
      fontSizeIndex: 2,
      customWidth: 28,
      printerType: PrinterTypeOption.bluetooth,
      autoPrint: true,
      receiptFooter: 'Thank you',
    );

    test('copyWith preserves all unmodified fields', () {
      final copy = base.copyWith(isConnected: false);
      expect(copy.isConnected, isFalse);
      expect(copy.printerName, 'BT-58');
      expect(copy.printerAddress, '11:22:33:44:55:66');
      expect(copy.paperSizeIndex, 0);
      expect(copy.fontSizeIndex, 2);
      expect(copy.customWidth, 28);
      expect(copy.printerType, PrinterTypeOption.bluetooth);
      expect(copy.autoPrint, isTrue);
      expect(copy.receiptFooter, 'Thank you');
    });

    test('copyWith can change paper size', () {
      final copy = base.copyWith(paperSizeIndex: 1);
      expect(copy.paperSizeIndex, 1);
      expect(copy.paperSizeLabel, '80mm');
    });

    test('copyWith can change font size', () {
      final copy = base.copyWith(fontSizeIndex: 0);
      expect(copy.fontSize, PrinterFontSize.small);
    });

    test('copyWith can change printer type', () {
      final copy = base.copyWith(printerType: PrinterTypeOption.wifi);
      expect(copy.printerType, PrinterTypeOption.wifi);
      expect(copy.printerType.isThermal, isTrue);
    });

    test('error is cleared by default in copyWith', () {
      final withError = base.copyWith(error: 'Connection lost');
      expect(withError.error, 'Connection lost');
      final cleared = withError.copyWith();
      expect(cleared.error, isNull);
    });
  });
}
