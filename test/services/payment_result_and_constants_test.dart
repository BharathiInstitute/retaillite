/// Tests for PaymentResult data class, safeTextStyle utility,
/// SettingsKeys, HiveBoxes, PrinterStorage, and ImageSizes constants
library;

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Inline PaymentResult (avoids razorpay_flutter platform dep) ──

class PaymentResult {
  final bool success;
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final String? errorCode;
  final String? errorMessage;

  const PaymentResult({
    required this.success,
    this.paymentId,
    this.orderId,
    this.signature,
    this.errorCode,
    this.errorMessage,
  });

  factory PaymentResult.success({
    required String paymentId,
    String? orderId,
    String? signature,
  }) {
    return PaymentResult(
      success: true,
      paymentId: paymentId,
      orderId: orderId,
      signature: signature,
    );
  }

  factory PaymentResult.failure({
    required String errorCode,
    required String errorMessage,
  }) {
    return PaymentResult(
      success: false,
      errorCode: errorCode,
      errorMessage: errorMessage,
    );
  }

  factory PaymentResult.cancelled() {
    return const PaymentResult(
      success: false,
      errorCode: 'CANCELLED',
      errorMessage: 'Payment was cancelled by user',
    );
  }
}

// ── Inline safeTextStyle (no transitive deps) ──

const double _minFontSize = 11.0;

TextStyle safeTextStyle(TextStyle style) {
  final fontSize = style.fontSize ?? 14;
  return style.copyWith(fontSize: max(fontSize, _minFontSize));
}

// ── Inline storage key classes ──

class SettingsKeys {
  static const String settings = 'app_settings';
  static const String dataInitialized = 'data_initialized';
  static const String isDarkMode = 'is_dark_mode';
  static const String language = 'language';
  static const String retentionDays = 'retention_days';
  static const String lastCleanupTime = 'last_cleanup_time';
  static const String lastExportTime = 'last_export_time';
  static const String autoCleanupEnabled = 'auto_cleanup_enabled';
}

class HiveBoxes {
  static const String products = 'products';
  static const String bills = 'bills';
  static const String customers = 'customers';
  static const String pendingSync = 'pending_sync';
  static const String settings = 'settings';
}

class PrinterStorage {
  static const String isConnected = 'printer_is_connected';
  static const String printerName = 'printer_name';
  static const String printerAddress = 'printer_address';
  static const String paperWidth = 'printer_paper_width';
  static const String paperSizeKey = 'printer_paper_size';
  static const String fontSizeKey = 'printer_font_size';
  static const String customWidthKey = 'printer_custom_width';
  static const String autoPrintKey = 'printer_auto_print';
  static const String receiptFooterKey = 'printer_receipt_footer';
  static const String printerTypeKey = 'printer_type';
  static const String wifiIpKey = 'printer_wifi_ip';
  static const String wifiPortKey = 'printer_wifi_port';
  static const String usbPrinterNameKey = 'printer_usb_name';
}

class ImageSizes {
  static const int logoSize = 200;
  static const int productThumbnailSize = 150;
}

void main() {
  // ─── PaymentResult ───────────────────────────────────────────────────

  group('PaymentResult', () {
    test('success factory sets success=true and paymentId', () {
      final result = PaymentResult.success(paymentId: 'pay_abc123');
      expect(result.success, isTrue);
      expect(result.paymentId, 'pay_abc123');
      expect(result.errorCode, isNull);
      expect(result.errorMessage, isNull);
    });

    test('success factory includes orderId and signature', () {
      final result = PaymentResult.success(
        paymentId: 'pay_abc',
        orderId: 'order_xyz',
        signature: 'sig_123',
      );
      expect(result.orderId, 'order_xyz');
      expect(result.signature, 'sig_123');
    });

    test('failure factory sets success=false with error details', () {
      final result = PaymentResult.failure(
        errorCode: 'NETWORK_ERROR',
        errorMessage: 'Connection lost',
      );
      expect(result.success, isFalse);
      expect(result.errorCode, 'NETWORK_ERROR');
      expect(result.errorMessage, 'Connection lost');
      expect(result.paymentId, isNull);
    });

    test('cancelled factory has predefined code and message', () {
      final result = PaymentResult.cancelled();
      expect(result.success, isFalse);
      expect(result.errorCode, 'CANCELLED');
      expect(result.errorMessage, contains('cancelled'));
    });

    test('const constructor works for custom cases', () {
      const result = PaymentResult(
        success: false,
        errorCode: 'TIMEOUT',
        errorMessage: 'Request timed out',
      );
      expect(result.success, isFalse);
      expect(result.errorCode, 'TIMEOUT');
    });
  });

  // ─── safeTextStyle ───────────────────────────────────────────────────

  group('safeTextStyle', () {
    test('clamps font size below minimum to 11', () {
      const style = TextStyle(fontSize: 8);
      final safe = safeTextStyle(style);
      expect(safe.fontSize, 11);
    });

    test('passes through font size above minimum', () {
      const style = TextStyle(fontSize: 16);
      final safe = safeTextStyle(style);
      expect(safe.fontSize, 16);
    });

    test('null fontSize defaults to 14 (above minimum)', () {
      const style = TextStyle(); // fontSize is null
      final safe = safeTextStyle(style);
      expect(safe.fontSize, 14);
    });

    test('exactly minimum passes through', () {
      const style = TextStyle(fontSize: 11);
      final safe = safeTextStyle(style);
      expect(safe.fontSize, 11);
    });

    test('preserves other style properties', () {
      const style = TextStyle(
        fontSize: 8,
        fontWeight: FontWeight.bold,
        color: Color(0xFF000000),
      );
      final safe = safeTextStyle(style);
      expect(safe.fontWeight, FontWeight.bold);
      expect(safe.color, const Color(0xFF000000));
    });

    test('very large font size passes through', () {
      const style = TextStyle(fontSize: 100);
      final safe = safeTextStyle(style);
      expect(safe.fontSize, 100);
    });
  });

  // ─── Storage Key Constants ───────────────────────────────────────────

  group('SettingsKeys', () {
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
        expect(key, isNotEmpty, reason: 'each key must be non-empty');
      }
    });

    test('all keys are unique', () {
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
      expect(keys.toSet().length, keys.length);
    });

    test('exact values match', () {
      expect(SettingsKeys.isDarkMode, 'is_dark_mode');
      expect(SettingsKeys.language, 'language');
    });
  });

  group('HiveBoxes', () {
    test('all box names are non-empty', () {
      final boxes = [
        HiveBoxes.products,
        HiveBoxes.bills,
        HiveBoxes.customers,
        HiveBoxes.pendingSync,
        HiveBoxes.settings,
      ];
      for (final box in boxes) {
        expect(box, isNotEmpty);
      }
    });

    test('all box names are lowercase', () {
      final boxes = [
        HiveBoxes.products,
        HiveBoxes.bills,
        HiveBoxes.customers,
        HiveBoxes.pendingSync,
        HiveBoxes.settings,
      ];
      for (final box in boxes) {
        expect(box, box.toLowerCase());
      }
    });
  });

  group('PrinterStorage', () {
    test('all keys are non-empty', () {
      final keys = [
        PrinterStorage.isConnected,
        PrinterStorage.printerName,
        PrinterStorage.printerAddress,
        PrinterStorage.paperWidth,
        PrinterStorage.paperSizeKey,
        PrinterStorage.fontSizeKey,
        PrinterStorage.customWidthKey,
        PrinterStorage.autoPrintKey,
        PrinterStorage.receiptFooterKey,
        PrinterStorage.printerTypeKey,
        PrinterStorage.wifiIpKey,
        PrinterStorage.wifiPortKey,
        PrinterStorage.usbPrinterNameKey,
      ];
      for (final key in keys) {
        expect(key, isNotEmpty);
      }
    });

    test('all keys are unique', () {
      final keys = [
        PrinterStorage.isConnected,
        PrinterStorage.printerName,
        PrinterStorage.printerAddress,
        PrinterStorage.paperWidth,
        PrinterStorage.paperSizeKey,
        PrinterStorage.fontSizeKey,
        PrinterStorage.customWidthKey,
        PrinterStorage.autoPrintKey,
        PrinterStorage.receiptFooterKey,
        PrinterStorage.printerTypeKey,
        PrinterStorage.wifiIpKey,
        PrinterStorage.wifiPortKey,
        PrinterStorage.usbPrinterNameKey,
      ];
      expect(keys.toSet().length, keys.length);
    });

    test('all printer keys have printer_ prefix', () {
      final keys = [
        PrinterStorage.isConnected,
        PrinterStorage.printerName,
        PrinterStorage.printerAddress,
        PrinterStorage.paperWidth,
        PrinterStorage.paperSizeKey,
        PrinterStorage.fontSizeKey,
        PrinterStorage.customWidthKey,
        PrinterStorage.autoPrintKey,
        PrinterStorage.receiptFooterKey,
        PrinterStorage.printerTypeKey,
        PrinterStorage.wifiIpKey,
        PrinterStorage.wifiPortKey,
        PrinterStorage.usbPrinterNameKey,
      ];
      for (final key in keys) {
        expect(key, startsWith('printer_'));
      }
    });

    test('no key collision with SettingsKeys', () {
      final settingsKeys = {
        SettingsKeys.settings,
        SettingsKeys.dataInitialized,
        SettingsKeys.isDarkMode,
        SettingsKeys.language,
        SettingsKeys.retentionDays,
        SettingsKeys.lastCleanupTime,
        SettingsKeys.lastExportTime,
        SettingsKeys.autoCleanupEnabled,
      };
      final printerKeys = {
        PrinterStorage.isConnected,
        PrinterStorage.printerName,
        PrinterStorage.printerAddress,
        PrinterStorage.paperWidth,
        PrinterStorage.paperSizeKey,
        PrinterStorage.fontSizeKey,
        PrinterStorage.customWidthKey,
        PrinterStorage.autoPrintKey,
        PrinterStorage.receiptFooterKey,
        PrinterStorage.printerTypeKey,
        PrinterStorage.wifiIpKey,
        PrinterStorage.wifiPortKey,
        PrinterStorage.usbPrinterNameKey,
      };
      expect(settingsKeys.intersection(printerKeys), isEmpty);
    });
  });

  // ─── ImageSizes ──────────────────────────────────────────────────────

  group('ImageSizes', () {
    test('logo size is positive', () {
      expect(ImageSizes.logoSize, greaterThan(0));
    });

    test('thumbnail size is positive', () {
      expect(ImageSizes.productThumbnailSize, greaterThan(0));
    });

    test('logo size >= thumbnail size', () {
      expect(
        ImageSizes.logoSize,
        greaterThanOrEqualTo(ImageSizes.productThumbnailSize),
      );
    });

    test('exact values', () {
      expect(ImageSizes.logoSize, 200);
      expect(ImageSizes.productThumbnailSize, 150);
    });
  });
}
