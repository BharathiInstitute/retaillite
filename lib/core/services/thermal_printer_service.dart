/// Thermal printer services for direct ESC/POS printing
///
/// Three backends:
/// - **Bluetooth** — via `print_bluetooth_thermal` (Android/iOS)
/// - **WiFi/Network** — via TCP Socket to port 9100 (all non-web)
/// - **USB** — via Windows RAW printing / Process command (Windows)
///
/// System printers (inkjet/laser) use `printing` package via ReceiptService.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';
import 'package:retaillite/models/bill_model.dart';
import 'package:intl/intl.dart';

// ════════════════════════════════════════════════════════════════════
//  Shared Enums & Models
// ════════════════════════════════════════════════════════════════════

/// Paper size for thermal printers
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

/// Font size for thermal printers
enum PrinterFontSizeMode {
  small(0),
  normal(1),
  large(2);

  final int value;
  const PrinterFontSizeMode(this.value);

  static PrinterFontSizeMode fromValue(int value) {
    return PrinterFontSizeMode.values.firstWhere(
      (f) => f.value == value,
      orElse: () => PrinterFontSizeMode.normal,
    );
  }
}

/// Printer device info (Bluetooth, WiFi, or USB)
class PrinterDevice {
  final String name;
  final String address; // MAC address, IP:port, or Windows printer name

  const PrinterDevice({required this.name, required this.address});

  Map<String, dynamic> toJson() => {'name': name, 'address': address};

  factory PrinterDevice.fromJson(Map<String, dynamic> json) {
    return PrinterDevice(
      name: json['name'] as String,
      address: json['address'] as String,
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  Shared ESC/POS Receipt Builder
// ════════════════════════════════════════════════════════════════════

/// Generates ESC/POS byte sequences for receipts — shared by all backends
class EscPosBuilder {
  EscPosBuilder._();

  static final _dateFormat = DateFormat('dd/MM/yyyy hh:mm a');

  // ── ESC/POS command helpers ──
  static List<int> init() => [0x1B, 0x40];
  static List<int> center() => [0x1B, 0x61, 0x01];
  static List<int> left() => [0x1B, 0x61, 0x00];
  static List<int> bold(bool on) => [0x1B, 0x45, on ? 0x01 : 0x00];
  static List<int> doubleHeight(bool on) => [0x1B, 0x21, on ? 0x10 : 0x00];
  static List<int> feed(int lines) => [0x1B, 0x64, lines];
  static List<int> cut() => [0x1D, 0x56, 0x00];
  static List<int> text(String t) => t.codeUnits;

  static List<int> fontSize(PrinterFontSizeMode mode) {
    switch (mode) {
      case PrinterFontSizeMode.small:
        return [0x1B, 0x21, 0x01];
      case PrinterFontSizeMode.normal:
        return [0x1B, 0x21, 0x00];
      case PrinterFontSizeMode.large:
        return [0x1B, 0x21, 0x10];
    }
  }

  /// Format a 3-column line
  static String formatLine(String l, String c, String r, int w) {
    final total = l.length + c.length + r.length;
    if (total >= w) return '$l $c $r\n';
    final sp = w - total;
    final ls = sp ~/ 2;
    return '$l${' ' * ls}$c${' ' * (sp - ls)}$r\n';
  }

  // ── Shared settings helpers ──
  static int getEffectiveWidth() {
    final custom = PrinterStorage.getSavedCustomWidth();
    if (custom > 0) return custom;
    return PrinterPaperSize.fromIndex(
      PrinterStorage.getSavedPaperSize(),
    ).charsPerLine;
  }

  static PrinterFontSizeMode getSavedFontSize() {
    return PrinterFontSizeMode.fromValue(PrinterStorage.getSavedFontSize());
  }

  static PrinterPaperSize getSavedPaperSize() {
    return PrinterPaperSize.fromIndex(PrinterStorage.getSavedPaperSize());
  }

  // ── Build test page bytes ──
  static List<int> buildTestPage() {
    final paperSize = getSavedPaperSize();
    final chars = getEffectiveWidth();
    final font = getSavedFontSize();

    return [
      ...init(),
      ...fontSize(font),
      ...center(),
      ...bold(true),
      ...text('TEST PRINT\n'),
      ...bold(false),
      ...text('${'=' * chars}\n'),
      ...left(),
      ...text('Printer: Connected\n'),
      ...text('Paper: ${paperSize.displayName}\n'),
      ...text('Width: $chars chars\n'),
      ...text('Font: ${font.name}\n'),
      ...text('Time: ${DateTime.now()}\n'),
      ...text('${'=' * chars}\n'),
      ...center(),
      ...text('Tulasi Stores\n'),
      ...feed(3),
      ...cut(),
    ];
  }

  // ── Build receipt bytes ──
  static List<int> buildReceipt({
    required BillModel bill,
    String? shopName,
    String? shopAddress,
    String? shopPhone,
    String? gstNumber,
    String? receiptFooter,
  }) {
    final chars = getEffectiveWidth();
    final font = getSavedFontSize();
    final bytes = <int>[];

    // Init
    bytes.addAll(init());
    bytes.addAll(fontSize(font));

    // Shop header
    bytes.addAll(center());
    bytes.addAll(bold(true));
    bytes.addAll(doubleHeight(true));
    bytes.addAll(text('${shopName ?? 'Tulasi Stores'}\n'));
    bytes.addAll(doubleHeight(false));
    bytes.addAll(bold(false));

    if (shopAddress != null) bytes.addAll(text('$shopAddress\n'));
    if (shopPhone != null) bytes.addAll(text('Ph: $shopPhone\n'));
    if (gstNumber != null) bytes.addAll(text('GSTIN: $gstNumber\n'));

    bytes.addAll(text('${'=' * chars}\n'));

    // Bill info
    bytes.addAll(left());
    bytes.addAll(bold(true));
    bytes.addAll(text('Bill #${bill.billNumber}'));
    bytes.addAll(bold(false));

    final dateStr = _dateFormat.format(bill.createdAt);
    bytes.addAll(text('\n$dateStr\n'));
    bytes.addAll(text('Payment: ${bill.paymentMethod.displayName}\n'));

    if (bill.customerName != null) {
      bytes.addAll(text('Customer: ${bill.customerName}\n'));
    }

    bytes.addAll(text('${'-' * chars}\n'));

    // Items header
    bytes.addAll(bold(true));
    bytes.addAll(text(formatLine('Item', 'Qty', 'Amt', chars)));
    bytes.addAll(bold(false));
    bytes.addAll(text('${'-' * chars}\n'));

    // Items
    for (final item in bill.items) {
      bytes.addAll(text('${item.name}\n'));
      bytes.addAll(
        text(
          formatLine(
            '  @${item.price.toStringAsFixed(0)}',
            'x${item.quantity}',
            item.total.toStringAsFixed(0),
            chars,
          ),
        ),
      );
    }

    bytes.addAll(text('${'-' * chars}\n'));

    // Total
    bytes.addAll(bold(true));
    bytes.addAll(doubleHeight(true));
    bytes.addAll(
      text(
        formatLine('TOTAL', '', 'Rs${bill.total.toStringAsFixed(0)}', chars),
      ),
    );
    bytes.addAll(doubleHeight(false));
    bytes.addAll(bold(false));

    // Cash details
    if (bill.paymentMethod == PaymentMethod.cash &&
        bill.receivedAmount != null) {
      bytes.addAll(
        text(
          formatLine(
            'Received',
            '',
            'Rs${bill.receivedAmount!.toStringAsFixed(0)}',
            chars,
          ),
        ),
      );
      if ((bill.changeAmount ?? 0) > 0) {
        bytes.addAll(
          text(
            formatLine(
              'Change',
              '',
              'Rs${bill.changeAmount!.toStringAsFixed(0)}',
              chars,
            ),
          ),
        );
      }
    }

    // Udhar note
    if (bill.paymentMethod == PaymentMethod.udhar) {
      bytes.addAll(text('${'-' * chars}\n'));
      bytes.addAll(center());
      bytes.addAll(bold(true));
      bytes.addAll(text('*** UDHAR - Payment Pending ***\n'));
      bytes.addAll(bold(false));
    }

    bytes.addAll(text('${'=' * chars}\n'));

    // Footer
    bytes.addAll(center());
    if (receiptFooter != null && receiptFooter.isNotEmpty) {
      bytes.addAll(text('$receiptFooter\n'));
    } else {
      bytes.addAll(text('Thank you for shopping!\n'));
    }
    bytes.addAll(text('Powered by Tulasi Stores\n'));

    bytes.addAll(feed(3));
    bytes.addAll(cut());

    return bytes;
  }
}

// ════════════════════════════════════════════════════════════════════
//  1. Bluetooth Thermal Printer Service
// ════════════════════════════════════════════════════════════════════

/// Bluetooth thermal printing via `print_bluetooth_thermal` (Android/iOS)
class ThermalPrinterService {
  ThermalPrinterService._();

  /// Available on Android/iOS only
  static bool get isAvailable {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  static Future<List<PrinterDevice>> getPairedDevices() async {
    if (!isAvailable) return [];
    try {
      final devices = await PrintBluetoothThermal.pairedBluetooths;
      return devices
          .map((d) => PrinterDevice(name: d.name, address: d.macAdress))
          .toList();
    } catch (e) {
      debugPrint('BT scan error: $e');
      return [];
    }
  }

  static Future<bool> connect(PrinterDevice device) async {
    if (!isAvailable) return false;
    try {
      return await PrintBluetoothThermal.connect(
        macPrinterAddress: device.address,
      );
    } catch (e) {
      debugPrint('BT connect error: $e');
      return false;
    }
  }

  static Future<bool> disconnect() async {
    if (!isAvailable) return false;
    try {
      return await PrintBluetoothThermal.disconnect;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> get isConnected async {
    if (!isAvailable) return false;
    try {
      return await PrintBluetoothThermal.connectionStatus;
    } catch (_) {
      return false;
    }
  }

  static PrinterDevice? getSavedPrinter() {
    final data = PrinterStorage.getSavedPrinter();
    if (data == null) return null;
    return PrinterDevice(name: data['name']!, address: data['address']!);
  }

  static Future<void> savePrinter(PrinterDevice device) async {
    await PrinterStorage.savePrinter(device.name, device.address);
  }

  static Future<void> clearSavedPrinter() async {
    await PrinterStorage.clearSavedPrinter();
  }

  static Future<bool> printTestPage() async {
    if (!await _ensureConnected()) return false;
    try {
      return await PrintBluetoothThermal.writeBytes(
        EscPosBuilder.buildTestPage(),
      );
    } catch (e) {
      debugPrint('BT print error: $e');
      return false;
    }
  }

  /// Auto-reconnect to saved printer if disconnected
  static Future<bool> _ensureConnected() async {
    if (await isConnected) return true;

    // Try to reconnect using saved printer
    final saved = getSavedPrinter();
    if (saved == null) return false;

    debugPrint('🔄 BT: Auto-reconnecting to ${saved.name}...');
    try {
      final ok = await connect(
        saved,
      ).timeout(const Duration(seconds: 3), onTimeout: () => false);
      if (ok) {
        debugPrint('✅ BT: Auto-reconnected');
      } else {
        debugPrint('❌ BT: Auto-reconnect failed');
      }
      return ok;
    } catch (e) {
      debugPrint('❌ BT: Auto-reconnect error: $e');
      return false;
    }
  }

  static Future<bool> printReceipt({
    required BillModel bill,
    String? shopName,
    String? shopAddress,
    String? shopPhone,
    String? gstNumber,
    String? receiptFooter,
  }) async {
    if (!await _ensureConnected()) return false;
    try {
      return await PrintBluetoothThermal.writeBytes(
        EscPosBuilder.buildReceipt(
          bill: bill,
          shopName: shopName,
          shopAddress: shopAddress,
          shopPhone: shopPhone,
          gstNumber: gstNumber,
          receiptFooter: receiptFooter,
        ),
      );
    } catch (e) {
      debugPrint('BT receipt error: $e');
      return false;
    }
  }
}

// ════════════════════════════════════════════════════════════════════
//  2. WiFi / Network Thermal Printer Service
// ════════════════════════════════════════════════════════════════════

/// WiFi/Network thermal printing via TCP Socket to port 9100
class WifiPrinterService {
  WifiPrinterService._();

  static Socket? _socket;
  static String? _connectedIp;
  static int? _connectedPort;

  /// Available on all non-web platforms
  static bool get isAvailable => !kIsWeb;

  /// Current connection state
  static bool get isConnected => _socket != null;

  /// Connected printer address
  static String? get connectedAddress =>
      _connectedIp != null ? '$_connectedIp:$_connectedPort' : null;

  /// Connect to a WiFi thermal printer
  static Future<bool> connect(String ip, int port) async {
    if (!isAvailable) return false;

    // Disconnect existing connection first
    await disconnect();

    try {
      _socket = await Socket.connect(
        ip,
        port,
        timeout: const Duration(seconds: 5),
      );
      _connectedIp = ip;
      _connectedPort = port;

      // Listen for errors and disconnection
      _socket!.listen(
        (_) {}, // ignore incoming data
        onError: (error) {
          debugPrint('WiFi printer socket error: $error');
          _cleanup();
        },
        onDone: () {
          debugPrint('WiFi printer disconnected');
          _cleanup();
        },
        cancelOnError: true,
      );

      debugPrint('WiFi printer connected: $ip:$port');
      return true;
    } catch (e) {
      debugPrint('WiFi connect error: $e');
      _cleanup();
      return false;
    }
  }

  /// Disconnect from WiFi printer
  static Future<void> disconnect() async {
    try {
      await _socket?.close();
    } catch (_) {}
    _cleanup();
  }

  static void _cleanup() {
    _socket = null;
    _connectedIp = null;
    _connectedPort = null;
  }

  /// Send raw bytes to WiFi printer
  static Future<bool> _sendBytes(List<int> bytes) async {
    if (_socket == null) return false;
    try {
      _socket!.add(bytes);
      await _socket!.flush();
      return true;
    } catch (e) {
      debugPrint('WiFi send error: $e');
      _cleanup();
      return false;
    }
  }

  /// Print test page
  static Future<bool> printTestPage() async {
    return _sendBytes(EscPosBuilder.buildTestPage());
  }

  /// Print receipt
  static Future<bool> printReceipt({
    required BillModel bill,
    String? shopName,
    String? shopAddress,
    String? shopPhone,
    String? gstNumber,
    String? receiptFooter,
  }) async {
    return _sendBytes(
      EscPosBuilder.buildReceipt(
        bill: bill,
        shopName: shopName,
        shopAddress: shopAddress,
        shopPhone: shopPhone,
        gstNumber: gstNumber,
        receiptFooter: receiptFooter,
      ),
    );
  }

  /// Save WiFi printer settings
  static Future<void> saveWifiPrinter(String ip, int port) async {
    await PrinterStorage.saveWifiPrinterIp(ip);
    await PrinterStorage.saveWifiPrinterPort(port);
    await PrinterStorage.savePrinter('WiFi Printer', '$ip:$port');
  }

  /// Get saved WiFi printer IP
  static String getSavedIp() => PrinterStorage.getWifiPrinterIp();

  /// Get saved WiFi printer port
  static int getSavedPort() => PrinterStorage.getWifiPrinterPort();
}

// ════════════════════════════════════════════════════════════════════
//  3. USB Thermal Printer Service (Windows)
// ════════════════════════════════════════════════════════════════════

/// USB thermal printing on Windows via RAW print command
class UsbPrinterService {
  UsbPrinterService._();

  /// Available on Windows only
  static bool get isAvailable {
    if (kIsWeb) return false;
    return Platform.isWindows;
  }

  /// List available printers on Windows
  static Future<List<String>> getWindowsPrinters() async {
    if (!isAvailable) return [];

    try {
      final result = await Process.run('powershell', [
        '-Command',
        'Get-Printer | Select-Object -ExpandProperty Name',
      ]);
      if (result.exitCode != 0) return [];

      final output = (result.stdout as String).trim();
      if (output.isEmpty) return [];

      return output
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Error listing printers: $e');
      return [];
    }
  }

  /// Send raw ESC/POS bytes to a Windows printer using Windows Spooler API
  static Future<bool> _sendBytes(String printerName, List<int> bytes) async {
    if (!isAvailable || printerName.isEmpty) return false;

    try {
      debugPrint('🖨️ USB: Sending ${bytes.length} bytes to "$printerName"...');

      // Write bytes to temp file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}\\thermal_print_${DateTime.now().millisecondsSinceEpoch}.bin',
      );
      await tempFile.writeAsBytes(bytes);

      // Use Windows Spooler API via PowerShell P/Invoke for raw printing
      // This is the correct way to send raw ESC/POS data on Windows
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        '''
Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.Runtime.InteropServices;

public class RawPrinterHelper {
    [StructLayout(LayoutKind.Sequential)]
    public struct DOCINFOA {
        [MarshalAs(UnmanagedType.LPStr)] public string pDocName;
        [MarshalAs(UnmanagedType.LPStr)] public string pOutputFile;
        [MarshalAs(UnmanagedType.LPStr)] public string pDataType;
    }

    [DllImport("winspool.drv", EntryPoint = "OpenPrinterA", CharSet = CharSet.Ansi, SetLastError = true)]
    public static extern bool OpenPrinter(string szPrinter, out IntPtr hPrinter, IntPtr pd);

    [DllImport("winspool.drv", EntryPoint = "ClosePrinter", SetLastError = true)]
    public static extern bool ClosePrinter(IntPtr hPrinter);

    [DllImport("winspool.drv", EntryPoint = "StartDocPrinterA", CharSet = CharSet.Ansi, SetLastError = true)]
    public static extern int StartDocPrinter(IntPtr hPrinter, int level, ref DOCINFOA di);

    [DllImport("winspool.drv", EntryPoint = "EndDocPrinter", SetLastError = true)]
    public static extern bool EndDocPrinter(IntPtr hPrinter);

    [DllImport("winspool.drv", EntryPoint = "StartPagePrinter", SetLastError = true)]
    public static extern bool StartPagePrinter(IntPtr hPrinter);

    [DllImport("winspool.drv", EntryPoint = "EndPagePrinter", SetLastError = true)]
    public static extern bool EndPagePrinter(IntPtr hPrinter);

    [DllImport("winspool.drv", EntryPoint = "WritePrinter", SetLastError = true)]
    public static extern bool WritePrinter(IntPtr hPrinter, IntPtr pBytes, int dwCount, out int dwWritten);

    public static bool SendRawData(string printerName, byte[] data) {
        IntPtr hPrinter = IntPtr.Zero;
        if (!OpenPrinter(printerName, out hPrinter, IntPtr.Zero)) {
            Console.Error.WriteLine("ERROR: Cannot open printer");
            return false;
        }
        try {
            DOCINFOA di = new DOCINFOA();
            di.pDocName = "ESC/POS Receipt";
            di.pDataType = "RAW";

            if (StartDocPrinter(hPrinter, 1, ref di) == 0) {
                Console.Error.WriteLine("ERROR: StartDocPrinter failed");
                return false;
            }
            try {
                if (!StartPagePrinter(hPrinter)) {
                    Console.Error.WriteLine("ERROR: StartPagePrinter failed");
                    return false;
                }
                IntPtr pBytes = Marshal.AllocCoTaskMem(data.Length);
                try {
                    Marshal.Copy(data, 0, pBytes, data.Length);
                    int written = 0;
                    if (!WritePrinter(hPrinter, pBytes, data.Length, out written)) {
                        Console.Error.WriteLine("ERROR: WritePrinter failed");
                        return false;
                    }
                    Console.WriteLine("OK:" + written);
                } finally {
                    Marshal.FreeCoTaskMem(pBytes);
                }
                EndPagePrinter(hPrinter);
            } finally {
                EndDocPrinter(hPrinter);
            }
            return true;
        } finally {
            ClosePrinter(hPrinter);
        }
    }
}
"@

\$data = [System.IO.File]::ReadAllBytes("${tempFile.path.replaceAll('\\', '\\\\')}")
\$ok = [RawPrinterHelper]::SendRawData("$printerName", \$data)
if (\$ok) { exit 0 } else { exit 1 }
''',
      ]);

      // Cleanup temp file
      try {
        await tempFile.delete();
      } catch (_) {}

      final stdout = (result.stdout as String).trim();
      final stderr = (result.stderr as String).trim();

      if (result.exitCode == 0 && stdout.startsWith('OK:')) {
        debugPrint('🖨️ USB: Print success — $stdout');
        return true;
      }

      debugPrint('🖨️ USB: Print failed (exit ${result.exitCode})');
      if (stdout.isNotEmpty) debugPrint('🖨️ USB stdout: $stdout');
      if (stderr.isNotEmpty) debugPrint('🖨️ USB stderr: $stderr');
      return false;
    } catch (e) {
      debugPrint('🖨️ USB print error: $e');
      return false;
    }
  }

  /// Print test page
  static Future<bool> printTestPage(String printerName) async {
    return _sendBytes(printerName, EscPosBuilder.buildTestPage());
  }

  /// Print receipt
  static Future<bool> printReceipt({
    required String printerName,
    required BillModel bill,
    String? shopName,
    String? shopAddress,
    String? shopPhone,
    String? gstNumber,
    String? receiptFooter,
  }) async {
    return _sendBytes(
      printerName,
      EscPosBuilder.buildReceipt(
        bill: bill,
        shopName: shopName,
        shopAddress: shopAddress,
        shopPhone: shopPhone,
        gstNumber: gstNumber,
        receiptFooter: receiptFooter,
      ),
    );
  }

  /// Save selected USB printer name
  static Future<void> saveUsbPrinter(String name) async {
    await PrinterStorage.saveUsbPrinterName(name);
    await PrinterStorage.savePrinter('USB: $name', name);
  }

  /// Get saved USB printer name
  static String getSavedPrinterName() => PrinterStorage.getUsbPrinterName();
}
