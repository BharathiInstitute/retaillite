/// Web Bluetooth printer service for Chrome-based printing
///
/// Uses the Web Bluetooth API (`navigator.bluetooth`) to connect
/// directly to Bluetooth thermal printers from the browser.
///
/// **Limitations**:
/// - Chrome/Edge only (no Firefox/Safari)
/// - Requires HTTPS or localhost
/// - User must pair device each session (no auto-reconnect)
/// - Only available on web platform
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:retaillite/core/services/thermal_printer_service.dart';
import 'package:retaillite/models/bill_model.dart';
import 'package:web/web.dart' as web;

/// Standard Bluetooth Serial Port Profile UUID for printers
const _serialPortServiceUuid = '000018f0-0000-1000-8000-00805f9b34fb';
const _serialPortCharUuid = '00002af1-0000-1000-8000-00805f9b34fb';

/// Service for printing via Chrome Web Bluetooth API.
class WebBluetoothPrinterService {
  WebBluetoothPrinterService._();

  static JSObject? _device;
  static JSObject? _characteristic;
  static bool _connected = false;

  /// Whether Web Bluetooth is supported in this browser.
  static bool get isSupported {
    if (!kIsWeb) return false;
    try {
      final nav = web.window.navigator as JSObject;
      final bt = nav['bluetooth'];
      return bt != null && bt.isA<JSObject>();
    } catch (_) {
      return false;
    }
  }

  /// Whether we have an active connection.
  static bool get isConnected => _connected && _characteristic != null;

  /// Request a Bluetooth printer and connect to it.
  ///
  /// Shows the browser's device picker dialog. Returns true if connected.
  static Future<bool> connect() async {
    if (!isSupported) return false;
    try {
      final nav = web.window.navigator as JSObject;
      final bluetooth = nav['bluetooth']! as JSObject;

      // Request device with serial port service
      final options = {
        'filters': [
          {
            'services': [_serialPortServiceUuid],
          },
        ],
      }.jsify()!;

      final device =
          await (bluetooth.callMethod('requestDevice'.toJS, options)
                  as JSPromise<JSObject>)
              .toDart;

      _device = device;

      // Connect to GATT server
      final gatt = device['gatt']! as JSObject;
      final server =
          await (gatt.callMethod('connect'.toJS) as JSPromise<JSObject>).toDart;

      // Get the serial port service
      final service =
          await (server.callMethod(
                    'getPrimaryService'.toJS,
                    _serialPortServiceUuid.toJS,
                  )
                  as JSPromise<JSObject>)
              .toDart;

      // Get the write characteristic
      final characteristic =
          await (service.callMethod(
                    'getCharacteristic'.toJS,
                    _serialPortCharUuid.toJS,
                  )
                  as JSPromise<JSObject>)
              .toDart;

      _characteristic = characteristic;
      _connected = true;

      debugPrint('Web Bluetooth: Connected to printer');
      return true;
    } catch (e) {
      debugPrint('Web Bluetooth connect error: $e');
      _connected = false;
      _characteristic = null;
      return false;
    }
  }

  /// Disconnect from the Bluetooth printer.
  static void disconnect() {
    try {
      if (_device != null) {
        final gatt = _device!['gatt'] as JSObject?;
        gatt?.callMethod('disconnect'.toJS);
      }
    } catch (e) {
      debugPrint('Web Bluetooth disconnect error: $e');
    }
    _device = null;
    _characteristic = null;
    _connected = false;
  }

  /// Send raw bytes to the connected printer.
  ///
  /// Web Bluetooth has a 512-byte MTU limit per write, so large
  /// payloads are chunked automatically.
  static Future<bool> sendBytes(List<int> bytes) async {
    if (_characteristic == null) {
      // Try to connect first
      if (!await connect()) return false;
    }
    try {
      final data = Uint8List.fromList(bytes);
      const chunkSize = 512;

      for (var offset = 0; offset < data.length; offset += chunkSize) {
        final end = (offset + chunkSize > data.length)
            ? data.length
            : offset + chunkSize;
        final chunk = data.sublist(offset, end);
        final buffer = chunk.buffer.toJS;

        await (_characteristic!.callMethod(
                  'writeValueWithoutResponse'.toJS,
                  buffer,
                )
                as JSPromise)
            .toDart;
      }
      return true;
    } catch (e) {
      debugPrint('Web Bluetooth send error: $e');
      _connected = false;
      return false;
    }
  }

  /// Print a receipt via Web Bluetooth using the shared ESC/POS builder.
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
    return sendBytes(bytes);
  }

  /// Print a test page.
  static Future<bool> printTestPage() async {
    return sendBytes(EscPosBuilder.buildTestPage());
  }
}
