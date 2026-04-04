import 'package:flutter/material.dart';
import 'package:retaillite/core/services/receipt_service.dart';
import 'package:retaillite/core/services/sunmi_printer_service.dart';
import 'package:retaillite/core/services/thermal_printer_service.dart';
import 'package:retaillite/core/services/web_bluetooth_printer_service.dart';
import 'package:retaillite/features/settings/providers/settings_provider.dart';
import 'package:retaillite/models/bill_model.dart';
import 'package:retaillite/models/user_model.dart';

/// Centralized print helper — single source of truth for all receipt printing.
///
/// Used by both mobile (payment_modal) and web (pos_web_widgets) checkout flows.
class PrintHelper {
  PrintHelper._();

  /// Print a receipt using the configured printer type.
  ///
  /// [isAutoPrint] — when true, skips system printer (shows dialog) and
  /// suppresses the fallback from a disconnected thermal printer to system.
  ///
  /// [onRetry] — callback for the "Retry" snackbar action. If null, no retry
  /// button is shown on failure.
  static Future<void> printReceipt({
    required BillModel bill,
    required PrinterState printerState,
    required UserModel? user,
    required ScaffoldMessengerState scaffoldMessenger,
    bool isAutoPrint = false,
    VoidCallback? onRetry,
  }) async {
    try {
      final footer = printerState.receiptFooter.isNotEmpty
          ? printerState.receiptFooter
          : null;

      bool? directSuccess;

      switch (printerState.printerType) {
        case PrinterTypeOption.bluetooth:
          if (ThermalPrinterService.isAvailable) {
            directSuccess = await ThermalPrinterService.printReceipt(
              bill: bill,
              shopName: user?.shopName,
              shopAddress: user?.address,
              shopPhone: user?.phone,
              gstNumber: user?.gstNumber,
              receiptFooter: footer,
            );
          }
          break;

        case PrinterTypeOption.wifi:
          if (WifiPrinterService.isConnected) {
            directSuccess = await WifiPrinterService.printReceipt(
              bill: bill,
              shopName: user?.shopName,
              shopAddress: user?.address,
              shopPhone: user?.phone,
              gstNumber: user?.gstNumber,
              receiptFooter: footer,
            );
          }
          break;

        case PrinterTypeOption.usb:
          final usbName = UsbPrinterService.getSavedPrinterName();
          if (usbName.isNotEmpty) {
            directSuccess = await UsbPrinterService.printReceipt(
              printerName: usbName,
              bill: bill,
              shopName: user?.shopName,
              shopAddress: user?.address,
              shopPhone: user?.phone,
              gstNumber: user?.gstNumber,
              receiptFooter: footer,
            );
          }
          break;

        case PrinterTypeOption.sunmi:
          if (await SunmiPrinterService.isAvailable) {
            directSuccess = await SunmiPrinterService.printReceipt(
              bill: bill,
              shopName: user?.shopName,
              shopAddress: user?.address,
              shopPhone: user?.phone,
              gstNumber: user?.gstNumber,
              receiptFooter: footer,
            );
          }
          break;

        case PrinterTypeOption.webBluetooth:
          if (WebBluetoothPrinterService.isSupported &&
              WebBluetoothPrinterService.isConnected) {
            directSuccess = await WebBluetoothPrinterService.printReceipt(
              bill: bill,
              shopName: user?.shopName,
              shopAddress: user?.address,
              shopPhone: user?.phone,
              gstNumber: user?.gstNumber,
              receiptFooter: footer,
            );
          }
          break;

        case PrinterTypeOption.system:
          if (isAutoPrint) return; // Never auto-print via system dialog
          await ReceiptService.printReceipt(
            bill: bill,
            shopName: user?.shopName,
            shopAddress: user?.address,
            shopPhone: user?.phone,
            gstNumber: user?.gstNumber,
            receiptFooter: footer,
            shopLogoPath: user?.shopLogoPath,
          );
          return;
      }

      if (directSuccess == false) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text('Print failed: Printer not connected'),
            action: onRetry != null
                ? SnackBarAction(label: 'Retry', onPressed: onRetry)
                : null,
          ),
        );
      } else if (directSuccess == null && !isAutoPrint) {
        // Printer type selected but not available — fallback to system
        await ReceiptService.printReceipt(
          bill: bill,
          shopName: user?.shopName,
          shopAddress: user?.address,
          shopPhone: user?.phone,
          gstNumber: user?.gstNumber,
          receiptFooter: footer,
          shopLogoPath: user?.shopLogoPath,
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Print failed: $e')),
      );
    }
  }
}
