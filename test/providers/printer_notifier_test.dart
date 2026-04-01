/// Tests for PrinterNotifier — the state notifier managing printer config.
///
/// Existing coverage in settings_provider_test.dart:
///   - PrinterState model defaults + copyWith (✅)
///   - PrinterFontSize enum (✅)
///   - PrinterTypeOption enum (✅)
///
/// This file adds the MISSING coverage:
///   - PrinterNotifier load from PrinterStorage (SharedPreferences)
///   - PrinterNotifier connect/disconnect/set* methods
///   - Persistence round-trips via SharedPreferences
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';
import 'package:retaillite/features/settings/providers/settings_provider.dart';

void main() {
  // ── Setup ──

  setUp(() async {
    // Reset internal state so each test gets fresh SharedPreferences
    PrinterStorage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await PrinterStorage.initialize();
  });

  // ── Load from empty storage ──

  group('PrinterNotifier initialization', () {
    test('default state when no saved printer', () {
      final notifier = PrinterNotifier();
      expect(notifier.state.isConnected, isFalse);
      expect(notifier.state.printerName, isNull);
      expect(notifier.state.printerAddress, isNull);
      expect(
        notifier.state.paperSizeIndex,
        0,
      ); // Default from getSavedPaperSize
      expect(notifier.state.fontSizeIndex, 1); // Default from getSavedFontSize
      expect(notifier.state.customWidth, 0); // Default auto
      expect(notifier.state.autoPrint, isFalse);
      expect(notifier.state.receiptFooter, '');
      expect(notifier.state.printerType, PrinterTypeOption.system);
    });

    test('loads saved printer from SharedPreferences', () async {
      PrinterStorage.resetForTesting();
      SharedPreferences.setMockInitialValues({
        'printer_name': 'Star TSP100',
        'printer_address': '00:11:22:33:44:55',
        'printer_paper_size': 1,
        'printer_font_size': 2,
        'printer_custom_width': 42,
        'printer_auto_print': true,
        'printer_receipt_footer': 'Thank you!',
        'printer_type': 'bluetooth',
      });
      await PrinterStorage.initialize();

      final notifier = PrinterNotifier();
      expect(notifier.state.isConnected, isTrue);
      expect(notifier.state.printerName, 'Star TSP100');
      expect(notifier.state.printerAddress, '00:11:22:33:44:55');
      expect(notifier.state.paperSizeIndex, 1);
      expect(notifier.state.fontSizeIndex, 2);
      expect(notifier.state.customWidth, 42);
      expect(notifier.state.autoPrint, isTrue);
      expect(notifier.state.receiptFooter, 'Thank you!');
      expect(notifier.state.printerType, PrinterTypeOption.bluetooth);
    });

    test('partially saved settings: no name but has paper size', () async {
      PrinterStorage.resetForTesting();
      SharedPreferences.setMockInitialValues({
        'printer_paper_size': 1,
        'printer_font_size': 0,
      });
      await PrinterStorage.initialize();

      final notifier = PrinterNotifier();
      expect(notifier.state.isConnected, isFalse);
      expect(notifier.state.printerName, isNull);
      expect(notifier.state.paperSizeIndex, 1); // 80mm
      expect(notifier.state.fontSizeIndex, 0); // Small
    });
  });

  // ── Connect / Disconnect ──

  group('Connect and disconnect printer', () {
    test('connectPrinter saves name, address and sets connected', () async {
      final notifier = PrinterNotifier();
      final result = await notifier.connectPrinter(
        'Star TSP100',
        '00:11:22:33:44:55',
      );

      expect(result, isTrue);
      expect(notifier.state.isConnected, isTrue);
      expect(notifier.state.printerName, 'Star TSP100');
      expect(notifier.state.printerAddress, '00:11:22:33:44:55');
      expect(notifier.state.isScanning, isFalse);

      // Verify persisted to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('printer_name'), 'Star TSP100');
      expect(prefs.getString('printer_address'), '00:11:22:33:44:55');
    });

    test('disconnectPrinter clears name, address, sets disconnected', () async {
      final notifier = PrinterNotifier();
      await notifier.connectPrinter('Star TSP100', '00:11:22:33:44:55');
      await notifier.disconnectPrinter();

      expect(notifier.state.isConnected, isFalse);
      expect(notifier.state.printerName, isNull);
      expect(notifier.state.printerAddress, isNull);

      // Verify cleared from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('printer_name'), isNull);
    });

    test('disconnect preserves paper size, font size, auto-print', () async {
      final notifier = PrinterNotifier();
      await notifier.connectPrinter('Star TSP100', 'addr');
      await notifier.setPaperSize(1);
      await notifier.setFontSize(2);
      await notifier.setAutoPrint(true);
      await notifier.setReceiptFooter('Thanks!');

      await notifier.disconnectPrinter();

      expect(notifier.state.paperSizeIndex, 1);
      expect(notifier.state.fontSizeIndex, 2);
      expect(notifier.state.autoPrint, isTrue);
      expect(notifier.state.receiptFooter, 'Thanks!');
    });
  });

  // ── Paper size ──

  group('setPaperSize', () {
    test('updates paper size to 58mm', () async {
      final notifier = PrinterNotifier();
      await notifier.setPaperSize(0);
      expect(notifier.state.paperSizeIndex, 0);
      expect(notifier.state.paperSizeLabel, '58mm');
    });

    test('updates paper size to 80mm', () async {
      final notifier = PrinterNotifier();
      await notifier.setPaperSize(1);
      expect(notifier.state.paperSizeIndex, 1);
      expect(notifier.state.paperSizeLabel, '80mm');
    });

    test('persists paper size to SharedPreferences', () async {
      final notifier = PrinterNotifier();
      await notifier.setPaperSize(1);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('printer_paper_size'), 1);
    });
  });

  // ── Font size ──

  group('setFontSize', () {
    test('updates font size to small (0)', () async {
      final notifier = PrinterNotifier();
      await notifier.setFontSize(0);
      expect(notifier.state.fontSizeIndex, 0);
      expect(notifier.state.fontSize, PrinterFontSize.small);
    });

    test('updates font size to large (2)', () async {
      final notifier = PrinterNotifier();
      await notifier.setFontSize(2);
      expect(notifier.state.fontSizeIndex, 2);
      expect(notifier.state.fontSize, PrinterFontSize.large);
    });

    test('persists font size', () async {
      final notifier = PrinterNotifier();
      await notifier.setFontSize(2);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('printer_font_size'), 2);
    });
  });

  // ── Custom width ──

  group('setCustomWidth', () {
    test('0 means auto width', () async {
      final notifier = PrinterNotifier();
      await notifier.setCustomWidth(0);
      expect(notifier.state.customWidth, 0);
      expect(notifier.state.widthLabel, contains('Auto'));
    });

    test('custom width of 42 chars', () async {
      final notifier = PrinterNotifier();
      await notifier.setCustomWidth(42);
      expect(notifier.state.customWidth, 42);
      expect(notifier.state.effectiveWidth, 42);
      expect(notifier.state.widthLabel, '42 chars');
    });

    test('auto width for 58mm paper is 32 chars', () async {
      final notifier = PrinterNotifier();
      await notifier.setPaperSize(0);
      await notifier.setCustomWidth(0);
      expect(notifier.state.effectiveWidth, 32);
    });

    test('auto width for 80mm paper is 48 chars', () async {
      final notifier = PrinterNotifier();
      await notifier.setPaperSize(1);
      await notifier.setCustomWidth(0);
      expect(notifier.state.effectiveWidth, 48);
    });
  });

  // ── Printer type ──

  group('setPrinterType', () {
    test('set to bluetooth', () async {
      final notifier = PrinterNotifier();
      await notifier.setPrinterType(PrinterTypeOption.bluetooth);
      expect(notifier.state.printerType, PrinterTypeOption.bluetooth);
    });

    test('set to usb', () async {
      final notifier = PrinterNotifier();
      await notifier.setPrinterType(PrinterTypeOption.usb);
      expect(notifier.state.printerType, PrinterTypeOption.usb);
    });

    test('set to wifi', () async {
      final notifier = PrinterNotifier();
      await notifier.setPrinterType(PrinterTypeOption.wifi);
      expect(notifier.state.printerType, PrinterTypeOption.wifi);
    });

    test('persists printer type', () async {
      final notifier = PrinterNotifier();
      await notifier.setPrinterType(PrinterTypeOption.wifi);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('printer_type'), 'wifi');
    });
  });

  // ── Auto-print ──

  group('setAutoPrint', () {
    test('enable auto-print', () async {
      final notifier = PrinterNotifier();
      await notifier.setAutoPrint(true);
      expect(notifier.state.autoPrint, isTrue);
    });

    test('disable auto-print', () async {
      final notifier = PrinterNotifier();
      await notifier.setAutoPrint(true);
      await notifier.setAutoPrint(false);
      expect(notifier.state.autoPrint, isFalse);
    });

    test('persists auto-print', () async {
      final notifier = PrinterNotifier();
      await notifier.setAutoPrint(true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('printer_auto_print'), isTrue);
    });
  });

  // ── Receipt footer ──

  group('setReceiptFooter', () {
    test('set footer text', () async {
      final notifier = PrinterNotifier();
      await notifier.setReceiptFooter('Thank you for shopping!');
      expect(notifier.state.receiptFooter, 'Thank you for shopping!');
    });

    test('set empty footer', () async {
      final notifier = PrinterNotifier();
      await notifier.setReceiptFooter('Something');
      await notifier.setReceiptFooter('');
      expect(notifier.state.receiptFooter, '');
    });

    test('persists footer', () async {
      final notifier = PrinterNotifier();
      await notifier.setReceiptFooter('Thanks!');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('printer_receipt_footer'), 'Thanks!');
    });
  });

  // ── Error handling ──

  group('Error handling', () {
    test('setError sets error and clears scanning', () {
      final notifier = PrinterNotifier();
      notifier.setError('Bluetooth disconnected');
      expect(notifier.state.error, 'Bluetooth disconnected');
      expect(notifier.state.isScanning, isFalse);
    });

    test('clearError clears error', () {
      final notifier = PrinterNotifier();
      notifier.setError('Some error');
      notifier.clearError();
      expect(notifier.state.error, isNull);
    });

    test('setConnectionStatus updates connected flag', () {
      final notifier = PrinterNotifier();
      notifier.setConnectionStatus(true);
      expect(notifier.state.isConnected, isTrue);
      notifier.setConnectionStatus(false);
      expect(notifier.state.isConnected, isFalse);
    });
  });

  // ── checkConnection ──

  group('checkConnection', () {
    test('sets disconnected when no saved printer', () async {
      final notifier = PrinterNotifier();
      await notifier.checkConnection();
      expect(notifier.state.isConnected, isFalse);
    });
  });
}
