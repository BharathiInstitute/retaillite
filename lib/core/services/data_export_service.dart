/// Data export service for CSV/PDF generation
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';
import 'package:retaillite/models/bill_model.dart';

/// Export format options
enum ExportFormat {
  csv('CSV', 'csv', 'Spreadsheet format for Excel/Sheets'),
  json('JSON', 'json', 'Raw data backup');

  const ExportFormat(this.label, this.extension, this.description);

  final String label;
  final String extension;
  final String description;
}

/// Export date range options
enum ExportRange {
  today('Today', 0),
  last7Days('Last 7 days', 7),
  last30Days('Last 30 days', 30),
  last90Days('Last 90 days', 90),
  thisMonth('This month', -1),
  lastMonth('Last month', -2),
  allTime('All time', -99);

  const ExportRange(this.label, this.days);

  final String label;
  final int days;

  /// Get date range for this option
  DateTimeRange get dateRange {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (this) {
      case ExportRange.today:
        return DateTimeRange(start: today, end: now);
      case ExportRange.last7Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 7)),
          end: now,
        );
      case ExportRange.last30Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 30)),
          end: now,
        );
      case ExportRange.last90Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 90)),
          end: now,
        );
      case ExportRange.thisMonth:
        return DateTimeRange(start: DateTime(now.year, now.month), end: now);
      case ExportRange.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1);
        final endOfLastMonth = DateTime(now.year, now.month, 0);
        return DateTimeRange(start: lastMonth, end: endOfLastMonth);
      case ExportRange.allTime:
        return DateTimeRange(start: DateTime(2020), end: now);
    }
  }
}

/// Date time range helper
class DateTimeRange {
  const DateTimeRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  bool includes(DateTime date) {
    return !date.isBefore(start) && !date.isAfter(end);
  }
}

/// Data export service
class DataExportService {
  /// Export bills to CSV format
  Future<ExportResult> exportBillsToCSV({
    required ExportRange range,
    String? customFileName,
  }) async {
    try {
      final bills = await _getBillsInRange(range.dateRange);

      if (bills.isEmpty) {
        return const ExportResult(
          success: false,
          error: 'No bills found in the selected date range',
        );
      }

      // Generate CSV content
      final csvContent = StringBuffer();

      // Header row
      csvContent.writeln(
        'Bill Number,Date,Time,Items,Total,Payment Method,Customer,Received Amount',
      );

      // Data rows
      for (final bill in bills) {
        final itemNames = bill.items
            .map((i) => '${i.name} x${i.quantity}')
            .join('; ');
        final time =
            '${bill.createdAt.hour.toString().padLeft(2, '0')}:${bill.createdAt.minute.toString().padLeft(2, '0')}';

        csvContent.writeln(
          '${bill.billNumber},'
          '${bill.date},'
          '$time,'
          '"$itemNames",'
          '${bill.total.toStringAsFixed(2)},'
          '${bill.paymentMethod.name},'
          '"${bill.customerName ?? ''}",'
          '${bill.receivedAmount?.toStringAsFixed(2) ?? ''}',
        );
      }

      // Save file
      final fileName =
          customFileName ??
          'bills_${range.label.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}';

      final filePath = await _saveFile(
        fileName,
        ExportFormat.csv.extension,
        csvContent.toString(),
      );

      // Update last export time
      await OfflineStorageService.saveSetting(
        SettingsKeys.lastExportTime,
        DateTime.now().toIso8601String(),
      );

      return ExportResult(
        success: true,
        filePath: filePath,
        recordCount: bills.length,
        format: ExportFormat.csv,
      );
    } catch (e) {
      return ExportResult(success: false, error: e.toString());
    }
  }

  /// Export bills to JSON format
  Future<ExportResult> exportBillsToJSON({
    required ExportRange range,
    String? customFileName,
  }) async {
    try {
      final bills = await _getBillsInRange(range.dateRange);

      if (bills.isEmpty) {
        return const ExportResult(
          success: false,
          error: 'No bills found in the selected date range',
        );
      }

      // Generate JSON content
      final jsonList = bills.map((b) => b.toMap()).toList();
      final jsonContent = _prettyPrintJson(jsonList);

      // Save file
      final fileName =
          customFileName ??
          'bills_backup_${DateTime.now().millisecondsSinceEpoch}';

      final filePath = await _saveFile(
        fileName,
        ExportFormat.json.extension,
        jsonContent,
      );

      return ExportResult(
        success: true,
        filePath: filePath,
        recordCount: bills.length,
        format: ExportFormat.json,
      );
    } catch (e) {
      return ExportResult(success: false, error: e.toString());
    }
  }

  /// Generate monthly summary report
  Future<ExportResult> exportMonthlySummary({
    required int year,
    required int month,
  }) async {
    try {
      final startDate = DateTime(year, month);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
      final range = DateTimeRange(start: startDate, end: endDate);

      final bills = await _getBillsInRange(range);

      // Calculate summary
      double totalSales = 0;
      double cashAmount = 0;
      double upiAmount = 0;
      double udharAmount = 0;
      final int billCount = bills.length;

      for (final bill in bills) {
        totalSales += bill.total;
        switch (bill.paymentMethod) {
          case PaymentMethod.cash:
            cashAmount += bill.total;
            break;
          case PaymentMethod.upi:
            upiAmount += bill.total;
            break;
          case PaymentMethod.udhar:
            udharAmount += bill.total;
            break;
          case PaymentMethod.unknown:
            break;
        }
      }

      // Generate summary CSV
      final monthName = _getMonthName(month);
      final csvContent = StringBuffer();

      csvContent.writeln('Monthly Summary Report');
      csvContent.writeln('Period,$monthName $year');
      csvContent.writeln('Generated,${DateTime.now().toIso8601String()}');
      csvContent.writeln();
      csvContent.writeln('Metric,Value');
      csvContent.writeln('Total Bills,$billCount');
      csvContent.writeln('Total Sales,₹${totalSales.toStringAsFixed(2)}');
      csvContent.writeln('Cash Sales,₹${cashAmount.toStringAsFixed(2)}');
      csvContent.writeln('UPI Sales,₹${upiAmount.toStringAsFixed(2)}');
      csvContent.writeln('Credit Sales,₹${udharAmount.toStringAsFixed(2)}');
      csvContent.writeln(
        'Average Bill,₹${billCount > 0 ? (totalSales / billCount).toStringAsFixed(2) : '0.00'}',
      );

      final fileName = 'summary_${monthName.toLowerCase()}_$year';

      final filePath = await _saveFile(fileName, 'csv', csvContent.toString());

      return ExportResult(
        success: true,
        filePath: filePath,
        recordCount: billCount,
        format: ExportFormat.csv,
      );
    } catch (e) {
      return ExportResult(success: false, error: e.toString());
    }
  }

  /// Get bills within date range from Firestore
  Future<List<BillModel>> _getBillsInRange(DateTimeRange range) async {
    try {
      final bills = await OfflineStorageService.getCachedBillsInRange(
        range.start,
        range.end,
      );

      // Sort by date descending
      bills.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return bills;
    } catch (e) {
      debugPrint('Error getting bills: $e');
      return [];
    }
  }

  /// Save file to downloads/documents folder
  Future<String> _saveFile(String name, String ext, String content) async {
    Directory directory;

    if (Platform.isAndroid) {
      // Use external storage on Android
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        directory = await getApplicationDocumentsDirectory();
      }
    } else if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    } else {
      // Desktop/Web
      directory = await getApplicationDocumentsDirectory();
    }

    // Create RetailLite subfolder
    final exportDir = Directory('${directory.path}/RetailLite_Exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final file = File('${exportDir.path}/$name.$ext');
    await file.writeAsString(content);

    return file.path;
  }

  String _prettyPrintJson(List<Map<String, dynamic>> data) {
    final buffer = StringBuffer();
    buffer.writeln('[');
    for (int i = 0; i < data.length; i++) {
      buffer.write('  ${data[i]}');
      if (i < data.length - 1) buffer.write(',');
      buffer.writeln();
    }
    buffer.writeln(']');
    return buffer.toString();
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  /// Get last export time
  static DateTime? getLastExportTime() {
    final str = OfflineStorageService.getSetting<String>(
      SettingsKeys.lastExportTime,
    );
    if (str == null) return null;
    return DateTime.tryParse(str);
  }
}

/// Result of an export operation
class ExportResult {
  const ExportResult({
    required this.success,
    this.filePath,
    this.recordCount,
    this.format,
    this.error,
  });

  final bool success;
  final String? filePath;
  final int? recordCount;
  final ExportFormat? format;
  final String? error;
}

/// Provider for data export service
final dataExportServiceProvider = Provider<DataExportService>((ref) {
  return DataExportService();
});
