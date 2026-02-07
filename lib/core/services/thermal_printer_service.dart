/// Bluetooth thermal printer service for direct ESC/POS printing
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';
import 'package:retaillite/models/bill_model.dart';
import 'package:intl/intl.dart';

/// Paper size enum for thermal printers
enum PrinterPaperSize {
  mm58(32, '58mm'),
  mm80(48, '80mm');

  final int charsPerLine;
  final String displayName;

  const PrinterPaperSize(this.charsPerLine, this.displayName);

  static PrinterPaperSize fromIndex(int index) {
    return index == 0 ? mm58 : mm80;
  }
}

/// Font size enum for thermal printers
enum PrinterFontSizeMode {
  small(0), // Compressed - fits more text
  normal(1), // Default
  large(2); // Double height

  final int value;

  const PrinterFontSizeMode(this.value);

  static PrinterFontSizeMode fromValue(int value) {
    return PrinterFontSizeMode.values.firstWhere(
      (f) => f.value == value,
      orElse: () => PrinterFontSizeMode.normal,
    );
  }
}

/// Bluetooth printer device info
class PrinterDevice {
  final String name;
  final String address;

  const PrinterDevice({required this.name, required this.address});

  Map<String, dynamic> toJson() => {'name': name, 'address': address};

  factory PrinterDevice.fromJson(Map<String, dynamic> json) {
    return PrinterDevice(
      name: json['name'] as String,
      address: json['address'] as String,
    );
  }
}

/// Service for managing Bluetooth thermal printer
class ThermalPrinterService {
  ThermalPrinterService._();

  static final _dateFormat = DateFormat('dd/MM/yyyy hh:mm a');

  /// Check if thermal printing is available (Android/iOS only)
  static bool get isAvailable {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Get list of paired Bluetooth devices
  static Future<List<PrinterDevice>> getPairedDevices() async {
    if (!isAvailable) return [];

    try {
      final devices = await PrintBluetoothThermal.pairedBluetooths;
      return devices
          .map((d) => PrinterDevice(name: d.name, address: d.macAdress))
          .toList();
    } catch (e) {
      debugPrint('Error getting paired devices: $e');
      return [];
    }
  }

  /// Connect to a printer
  static Future<bool> connect(PrinterDevice device) async {
    if (!isAvailable) return false;

    try {
      final result = await PrintBluetoothThermal.connect(
        macPrinterAddress: device.address,
      );
      return result;
    } catch (e) {
      debugPrint('Error connecting to printer: $e');
      return false;
    }
  }

  /// Disconnect from printer
  static Future<bool> disconnect() async {
    if (!isAvailable) return false;

    try {
      final result = await PrintBluetoothThermal.disconnect;
      return result;
    } catch (e) {
      return false;
    }
  }

  /// Check if printer is connected
  static Future<bool> get isConnected async {
    if (!isAvailable) return false;

    try {
      return await PrintBluetoothThermal.connectionStatus;
    } catch (e) {
      return false;
    }
  }

  /// Get saved printer from storage
  static PrinterDevice? getSavedPrinter() {
    final data = PrinterStorage.getSavedPrinter();
    if (data == null) return null;
    return PrinterDevice(name: data['name']!, address: data['address']!);
  }

  /// Save printer to storage
  static Future<void> savePrinter(PrinterDevice device) async {
    await PrinterStorage.savePrinter(device.name, device.address);
  }

  /// Clear saved printer
  static Future<void> clearSavedPrinter() async {
    await PrinterStorage.clearSavedPrinter();
  }

  /// Get saved paper size
  static PrinterPaperSize getSavedPaperSize() {
    final index = PrinterStorage.getSavedPaperSize();
    return PrinterPaperSize.fromIndex(index);
  }

  /// Save paper size
  static Future<void> savePaperSize(PrinterPaperSize size) async {
    await PrinterStorage.savePaperSize(size.index);
  }

  /// Get effective characters per line (uses custom width if set)
  static int getEffectiveWidth() {
    final customWidth = PrinterStorage.getSavedCustomWidth();
    if (customWidth > 0) return customWidth;
    final paperSize = getSavedPaperSize();
    return paperSize.charsPerLine;
  }

  /// Get saved font size
  static PrinterFontSizeMode getSavedFontSize() {
    final value = PrinterStorage.getSavedFontSize();
    return PrinterFontSizeMode.fromValue(value);
  }

  /// Print a test page
  static Future<bool> printTestPage() async {
    if (!await isConnected) return false;

    try {
      final paperSize = getSavedPaperSize();
      final chars = getEffectiveWidth();
      final fontSizeMode = getSavedFontSize();

      List<int> bytes = [];

      // ESC/POS commands
      bytes += _escPosInit();
      bytes += _setFontSize(fontSizeMode);
      bytes += _escPosCenter();
      bytes += _escPosBold(true);
      bytes += _escPosText('TEST PRINT\n');
      bytes += _escPosBold(false);
      bytes += _escPosText('${'=' * chars}\n');
      bytes += _escPosLeft();
      bytes += _escPosText('Printer: Connected\n');
      bytes += _escPosText('Paper: ${paperSize.displayName}\n');
      bytes += _escPosText('Width: $chars chars\n');
      bytes += _escPosText('Font: ${fontSizeMode.name}\n');
      bytes += _escPosText('Time: ${DateTime.now()}\n');
      bytes += _escPosText('${'=' * chars}\n');
      bytes += _escPosCenter();
      bytes += _escPosText('LITE Billing App\n');
      bytes += _escPosFeed(3);
      bytes += _escPosCut();

      final result = await PrintBluetoothThermal.writeBytes(bytes);
      return result;
    } catch (e) {
      debugPrint('Error printing test page: $e');
      return false;
    }
  }

  /// Print a bill receipt
  static Future<bool> printReceipt({
    required BillModel bill,
    String? shopName,
    String? shopAddress,
    String? shopPhone,
    String? gstNumber,
  }) async {
    if (!await isConnected) return false;

    try {
      final chars = getEffectiveWidth();
      final fontSizeMode = getSavedFontSize();

      List<int> bytes = [];

      // Initialize printer
      bytes += _escPosInit();
      bytes += _setFontSize(fontSizeMode);

      // Shop header (centered, bold)
      bytes += _escPosCenter();
      bytes += _escPosBold(true);
      bytes += _escPosDoubleHeight(true);
      bytes += _escPosText('${shopName ?? 'LITE'}\n');
      bytes += _escPosDoubleHeight(false);
      bytes += _escPosBold(false);

      if (shopAddress != null) {
        bytes += _escPosText('$shopAddress\n');
      }
      if (shopPhone != null) {
        bytes += _escPosText('Ph: $shopPhone\n');
      }
      if (gstNumber != null) {
        bytes += _escPosText('GSTIN: $gstNumber\n');
      }

      bytes += _escPosText('${'=' * chars}\n');

      // Bill info
      bytes += _escPosLeft();
      bytes += _escPosBold(true);
      bytes += _escPosText('Bill #${bill.billNumber}');
      bytes += _escPosBold(false);

      // Date on right side
      final dateStr = _dateFormat.format(bill.createdAt);
      bytes += _escPosText('\n$dateStr\n');
      bytes += _escPosText('Payment: ${bill.paymentMethod.displayName}\n');

      if (bill.customerName != null) {
        bytes += _escPosText('Customer: ${bill.customerName}\n');
      }

      bytes += _escPosText('${'-' * chars}\n');

      // Items header
      bytes += _escPosBold(true);
      bytes += _escPosText(_formatLine('Item', 'Qty', 'Amt', chars));
      bytes += _escPosBold(false);
      bytes += _escPosText('${'-' * chars}\n');

      // Items
      for (final item in bill.items) {
        bytes += _escPosText('${item.name}\n');
        bytes += _escPosText(
          _formatLine(
            '  @${item.price.toStringAsFixed(0)}',
            'x${item.quantity}',
            item.total.toStringAsFixed(0),
            chars,
          ),
        );
      }

      bytes += _escPosText('${'-' * chars}\n');

      // Total
      bytes += _escPosBold(true);
      bytes += _escPosDoubleHeight(true);
      bytes += _escPosText(
        _formatLine('TOTAL', '', 'Rs${bill.total.toStringAsFixed(0)}', chars),
      );
      bytes += _escPosDoubleHeight(false);
      bytes += _escPosBold(false);

      // Cash payment details
      if (bill.paymentMethod == PaymentMethod.cash &&
          bill.receivedAmount != null) {
        bytes += _escPosText(
          _formatLine(
            'Received',
            '',
            'Rs${bill.receivedAmount!.toStringAsFixed(0)}',
            chars,
          ),
        );
        if ((bill.changeAmount ?? 0) > 0) {
          bytes += _escPosText(
            _formatLine(
              'Change',
              '',
              'Rs${bill.changeAmount!.toStringAsFixed(0)}',
              chars,
            ),
          );
        }
      }

      // Udhar note
      if (bill.paymentMethod == PaymentMethod.udhar) {
        bytes += _escPosText('${'-' * chars}\n');
        bytes += _escPosCenter();
        bytes += _escPosBold(true);
        bytes += _escPosText('*** UDHAR - Payment Pending ***\n');
        bytes += _escPosBold(false);
      }

      bytes += _escPosText('${'=' * chars}\n');

      // Footer
      bytes += _escPosCenter();
      bytes += _escPosText('Thank you for shopping!\n');
      bytes += _escPosText('Powered by LITE\n');

      // Feed and cut
      bytes += _escPosFeed(3);
      bytes += _escPosCut();

      final result = await PrintBluetoothThermal.writeBytes(bytes);
      return result;
    } catch (e) {
      debugPrint('Error printing receipt: $e');
      return false;
    }
  }

  // ESC/POS helper functions
  static List<int> _escPosInit() => [0x1B, 0x40]; // ESC @

  static List<int> _escPosCenter() => [0x1B, 0x61, 0x01]; // ESC a 1

  static List<int> _escPosLeft() => [0x1B, 0x61, 0x00]; // ESC a 0

  static List<int> _escPosBold(bool on) => [
    0x1B,
    0x45,
    on ? 0x01 : 0x00,
  ]; // ESC E n

  static List<int> _escPosDoubleHeight(bool on) => [
    0x1B,
    0x21,
    on ? 0x10 : 0x00,
  ]; // ESC ! n

  static List<int> _escPosFeed(int lines) => [0x1B, 0x64, lines]; // ESC d n

  static List<int> _escPosCut() => [0x1D, 0x56, 0x00]; // GS V 0

  /// Set font size based on mode
  static List<int> _setFontSize(PrinterFontSizeMode mode) {
    // ESC ! n - Select print modes
    // Bit 0: Font A/B (we use A)
    // Bit 4: Double height
    // Bit 5: Double width
    // Bit 7: Emphasized
    switch (mode) {
      case PrinterFontSizeMode.small:
        // Use compressed/condensed mode (Font B if available)
        return [0x1B, 0x21, 0x01]; // ESC ! 1 (Font B - smaller)
      case PrinterFontSizeMode.normal:
        return [0x1B, 0x21, 0x00]; // ESC ! 0 (Normal)
      case PrinterFontSizeMode.large:
        return [0x1B, 0x21, 0x10]; // ESC ! 16 (Double height)
    }
  }

  static List<int> _escPosText(String text) {
    // Convert text to bytes (basic ASCII)
    return text.codeUnits;
  }

  /// Format a line with left, center, and right alignment
  static String _formatLine(
    String left,
    String center,
    String right,
    int width,
  ) {
    final totalLen = left.length + center.length + right.length;
    if (totalLen >= width) {
      return '$left $center $right\n';
    }

    final spaces = width - totalLen;
    final leftSpaces = spaces ~/ 2;
    final rightSpaces = spaces - leftSpaces;

    return '$left${' ' * leftSpaces}$center${' ' * rightSpaces}$right\n';
  }
}
