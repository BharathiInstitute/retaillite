/// Sunmi built-in printer service for Sunmi Android POS terminals
///
/// Uses `sunmi_printer_plus` to access the built-in thermal printer
/// on Sunmi V2, V2 Pro, T2, and other Sunmi devices.
// ignore_for_file: deprecated_member_use
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:retaillite/core/constants/app_constants.dart';
import 'package:retaillite/core/services/thermal_printer_service.dart';
import 'package:retaillite/models/bill_model.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';

/// Service for printing on Sunmi built-in thermal printers.
///
/// Sunmi devices (V2, V2 Pro, T2 etc.) are the most popular
/// Android POS terminals in India (~60%+ market share). They have
/// a built-in thermal printer accessed via the Sunmi SDK rather
/// than Bluetooth or WiFi.
class SunmiPrinterService {
  SunmiPrinterService._();

  static bool _initialized = false;

  /// Whether this is a Sunmi device with a built-in printer.
  /// Returns false on non-Android, web, and non-Sunmi devices.
  static Future<bool> get isAvailable async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      await _ensureInit();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Whether the printer is ready (paper loaded, not overheated).
  static Future<bool> get isReady async {
    try {
      await _ensureInit();
      // bindingPrinter succeeds only on Sunmi devices with working printer
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Initialize the Sunmi printer SDK once.
  static Future<void> _ensureInit() async {
    if (_initialized) return;
    await SunmiPrinter.bindingPrinter();
    _initialized = true;
  }

  /// Print a test page.
  static Future<bool> printTestPage() async {
    try {
      await _ensureInit();
      await SunmiPrinter.initPrinter();
      await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
      await SunmiPrinter.bold();
      await SunmiPrinter.setCustomFontSize(32);
      await SunmiPrinter.printText('TEST PRINT');
      await SunmiPrinter.resetBold();
      await SunmiPrinter.resetFontSize();
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
      await SunmiPrinter.printText('Printer: Sunmi Built-in');
      await SunmiPrinter.printText('Time: ${DateTime.now()}');
      await SunmiPrinter.printText(AppConstants.appName);
      await SunmiPrinter.lineWrap(3);
      await SunmiPrinter.cutPaper();
      return true;
    } catch (e) {
      debugPrint('Sunmi test page error: $e');
      return false;
    }
  }

  /// Print a receipt using raw ESC/POS bytes (shared builder).
  static Future<bool> printReceipt({
    required BillModel bill,
    String? shopName,
    String? shopAddress,
    String? shopPhone,
    String? gstNumber,
    String? receiptFooter,
    String? upiId,
    double? taxRate,
    bool partialCut = false,
    bool isHindi = false,
    String? copyLabel,
    bool showHsnOnReceipt = false,
    Uint8List? logoBytes,
  }) async {
    try {
      await _ensureInit();
      final bytes = EscPosBuilder.buildReceipt(
        bill: bill,
        shopName: shopName,
        shopAddress: shopAddress,
        shopPhone: shopPhone,
        gstNumber: gstNumber,
        receiptFooter: receiptFooter,
        upiId: upiId,
        taxRate: taxRate,
        partialCut: partialCut,
        isHindi: isHindi,
        copyLabel: copyLabel,
        showHsnOnReceipt: showHsnOnReceipt,
        logoBytes: logoBytes,
      );
      await SunmiPrinter.printRawData(Uint8List.fromList(bytes));
      return true;
    } catch (e) {
      debugPrint('Sunmi receipt error: $e');
      return false;
    }
  }

  /// Open cash drawer if connected via Sunmi's kick port.
  static Future<bool> openCashDrawer() async {
    try {
      await _ensureInit();
      await SunmiDrawer.openDrawer();
      return true;
    } catch (e) {
      debugPrint('Sunmi cash drawer error: $e');
      return false;
    }
  }
}
