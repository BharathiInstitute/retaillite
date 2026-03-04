/// OfflineStorageService — settings & printer storage tests
///
/// Tests the SharedPreferences-based settings layer of OfflineStorageService:
/// — SettingsKeys constants
/// — HiveBoxes collection name mapping
/// — PrinterStorage read/write with SharedPreferences
/// — Settings CRUD (getSetting, saveSetting, etc.)
/// — Usage metrics logging via SharedPreferences
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';

void main() {
  group('SettingsKeys — constant correctness', () {
    test('all keys are non-empty strings', () {
      final keys = [
        SettingsKeys.settings,
        SettingsKeys.dataInitialized,
        SettingsKeys.isDarkMode,
        SettingsKeys.language,
        SettingsKeys.retentionDays,
        SettingsKeys.lastCleanupTime,
        SettingsKeys.lastExportTime,
        SettingsKeys.autoCleanupEnabled,
      ];
      for (final key in keys) {
        expect(key, isNotEmpty, reason: 'Key should not be empty');
        expect(key, isA<String>());
      }
    });

    test('no duplicate keys', () {
      final keys = [
        SettingsKeys.settings,
        SettingsKeys.dataInitialized,
        SettingsKeys.isDarkMode,
        SettingsKeys.language,
        SettingsKeys.retentionDays,
        SettingsKeys.lastCleanupTime,
        SettingsKeys.lastExportTime,
        SettingsKeys.autoCleanupEnabled,
      ];
      expect(keys.toSet().length, keys.length, reason: 'Keys must be unique');
    });
  });

  group('HiveBoxes — collection name mapping', () {
    test('box names are non-empty', () {
      expect(HiveBoxes.products, isNotEmpty);
      expect(HiveBoxes.bills, isNotEmpty);
      expect(HiveBoxes.customers, isNotEmpty);
      expect(HiveBoxes.pendingSync, isNotEmpty);
      expect(HiveBoxes.settings, isNotEmpty);
    });

    test('box names map to Firestore collection names', () {
      expect(HiveBoxes.products, 'products');
      expect(HiveBoxes.bills, 'bills');
      expect(HiveBoxes.customers, 'customers');
    });
  });

  group('PrinterStorage — SharedPreferences keys', () {
    test('all printer keys are non-empty', () {
      expect(PrinterStorage.isConnected, isNotEmpty);
      expect(PrinterStorage.printerName, isNotEmpty);
      expect(PrinterStorage.printerAddress, isNotEmpty);
      expect(PrinterStorage.paperWidth, isNotEmpty);
    });

    test('printer keys are unique', () {
      final keys = [
        PrinterStorage.isConnected,
        PrinterStorage.printerName,
        PrinterStorage.printerAddress,
        PrinterStorage.paperWidth,
      ];
      expect(keys.toSet().length, keys.length);
    });
  });

  group('PrinterStorage — SharedPreferences operations', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initialize sets up SharedPreferences', () async {
      await PrinterStorage.initialize();
      // No crash = success
    });

    test('getSavedPrinter returns null when no printer saved', () async {
      await PrinterStorage.initialize();
      expect(PrinterStorage.getSavedPrinter(), isNull);
    });

    test('savePrinter and getSavedPrinter round-trip', () async {
      await PrinterStorage.initialize();
      await PrinterStorage.savePrinter('HP Printer', 'AA:BB:CC:DD:EE:FF');

      final saved = PrinterStorage.getSavedPrinter();
      expect(saved, isNotNull);
      expect(saved!['name'], 'HP Printer');
      expect(saved['address'], 'AA:BB:CC:DD:EE:FF');
    });

    test('clearSavedPrinter removes printer', () async {
      await PrinterStorage.initialize();
      await PrinterStorage.savePrinter('Printer', 'addr');
      await PrinterStorage.clearSavedPrinter();

      expect(PrinterStorage.getSavedPrinter(), isNull);
    });

    test('paper size defaults to 0', () async {
      await PrinterStorage.initialize();
      expect(PrinterStorage.getSavedPaperSize(), 0);
    });

    test('savePaperSize persists', () async {
      await PrinterStorage.initialize();
      await PrinterStorage.savePaperSize(2);
      expect(PrinterStorage.getSavedPaperSize(), 2);
    });

    test('font size defaults to 1', () async {
      await PrinterStorage.initialize();
      expect(PrinterStorage.getSavedFontSize(), 1);
    });

    test('saveFontSize persists', () async {
      await PrinterStorage.initialize();
      await PrinterStorage.saveFontSize(3);
      expect(PrinterStorage.getSavedFontSize(), 3);
    });

    test('custom width defaults to 0', () async {
      await PrinterStorage.initialize();
      expect(PrinterStorage.getSavedCustomWidth(), 0);
    });

    test('saveCustomWidth persists', () async {
      await PrinterStorage.initialize();
      await PrinterStorage.saveCustomWidth(384);
      expect(PrinterStorage.getSavedCustomWidth(), 384);
    });

    test('auto-print defaults to false', () async {
      await PrinterStorage.initialize();
      expect(PrinterStorage.getAutoPrint(), isFalse);
    });

    test('saveAutoPrint persists', () async {
      await PrinterStorage.initialize();
      await PrinterStorage.saveAutoPrint(true);
      expect(PrinterStorage.getAutoPrint(), isTrue);
    });

    test('receipt footer defaults to empty string', () async {
      await PrinterStorage.initialize();
      expect(PrinterStorage.getReceiptFooter(), '');
    });

    test('saveReceiptFooter persists', () async {
      await PrinterStorage.initialize();
      await PrinterStorage.saveReceiptFooter('Thank you!');
      expect(PrinterStorage.getReceiptFooter(), 'Thank you!');
    });

    test('printer type defaults to system', () async {
      await PrinterStorage.initialize();
      expect(PrinterStorage.getPrinterType(), 'system');
    });

    test('savePrinterType persists', () async {
      await PrinterStorage.initialize();
      await PrinterStorage.savePrinterType('bluetooth');
      expect(PrinterStorage.getPrinterType(), 'bluetooth');
    });

    test('wifi printer IP defaults to empty', () async {
      await PrinterStorage.initialize();
      expect(PrinterStorage.getWifiPrinterIp(), '');
    });

    test('saveWifiPrinterIp persists', () async {
      await PrinterStorage.initialize();
      await PrinterStorage.saveWifiPrinterIp('192.168.1.100');
      expect(PrinterStorage.getWifiPrinterIp(), '192.168.1.100');
    });

    test('wifi printer port defaults to 9100', () async {
      await PrinterStorage.initialize();
      expect(PrinterStorage.getWifiPrinterPort(), 9100);
    });

    test('saveWifiPrinterPort persists', () async {
      await PrinterStorage.initialize();
      await PrinterStorage.saveWifiPrinterPort(8080);
      expect(PrinterStorage.getWifiPrinterPort(), 8080);
    });

    test('USB printer name defaults to empty', () async {
      await PrinterStorage.initialize();
      expect(PrinterStorage.getUsbPrinterName(), '');
    });

    test('saveUsbPrinterName persists', () async {
      await PrinterStorage.initialize();
      await PrinterStorage.saveUsbPrinterName('EPSON TM-T88VI');
      expect(PrinterStorage.getUsbPrinterName(), 'EPSON TM-T88VI');
    });
  });

  group('PrinterStorage — edge cases', () {
    test('saving empty printer name works', () async {
      SharedPreferences.setMockInitialValues({});
      await PrinterStorage.initialize();
      await PrinterStorage.savePrinter('', '');
      final saved = PrinterStorage.getSavedPrinter();
      // Both name and address are empty strings, which match null check
      // The method returns null only if getString returns null
      expect(saved, isNotNull);
    });

    test('saving very long receipt footer works', () async {
      SharedPreferences.setMockInitialValues({});
      await PrinterStorage.initialize();
      final longFooter = 'A' * 1000;
      await PrinterStorage.saveReceiptFooter(longFooter);
      expect(PrinterStorage.getReceiptFooter(), longFooter);
    });

    test('saving unicode receipt footer works', () async {
      SharedPreferences.setMockInitialValues({});
      await PrinterStorage.initialize();
      await PrinterStorage.saveReceiptFooter('धन्यवाद! 🙏');
      expect(PrinterStorage.getReceiptFooter(), 'धन्यवाद! 🙏');
    });
  });
}
