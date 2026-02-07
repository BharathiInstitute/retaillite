/// Usage tracking service for monitoring app operations and cost tracking
library;

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Types of operations to track
enum OperationType {
  billCreated,
  billUpdated,
  productAdded,
  productUpdated,
  productDeleted,
  customerAdded,
  customerUpdated,
  reportGenerated,
  receiptPrinted,
  syncToCloud,
  syncFromCloud,
}

/// Daily usage summary
class DailyUsage {
  final String date;
  final Map<OperationType, int> operations;
  final double estimatedCost;

  DailyUsage({
    required this.date,
    required this.operations,
    required this.estimatedCost,
  });

  int get totalOperations => operations.values.fold(0, (a, b) => a + b);

  Map<String, dynamic> toMap() => {
    'date': date,
    'operations': operations.map((k, v) => MapEntry(k.name, v)),
    'estimatedCost': estimatedCost,
  };

  factory DailyUsage.fromMap(Map<String, dynamic> map) {
    return DailyUsage(
      date: map['date'] as String,
      operations: (map['operations'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(
          OperationType.values.firstWhere((e) => e.name == k),
          v as int,
        ),
      ),
      estimatedCost: (map['estimatedCost'] as num).toDouble(),
    );
  }
}

/// Service for tracking app usage and estimating costs
class UsageTrackingService {
  UsageTrackingService._();

  static SharedPreferences? _prefs;
  static const String _keyPrefix = 'usage_';

  // Estimated cost per operation (in INR paisa for precision)
  static const Map<OperationType, double> _costPerOperation = {
    OperationType.billCreated: 0.05, // 5 paisa
    OperationType.billUpdated: 0.02, // 2 paisa
    OperationType.productAdded: 0.03, // 3 paisa
    OperationType.productUpdated: 0.02, // 2 paisa
    OperationType.productDeleted: 0.01, // 1 paisa
    OperationType.customerAdded: 0.03, // 3 paisa
    OperationType.customerUpdated: 0.02, // 2 paisa
    OperationType.reportGenerated: 0.10, // 10 paisa
    OperationType.receiptPrinted: 0.05, // 5 paisa
    OperationType.syncToCloud: 0.20, // 20 paisa
    OperationType.syncFromCloud: 0.15, // 15 paisa
  };

  /// Initialize the service
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ==================== Tracking ====================

  /// Track an operation
  static Future<void> trackOperation(OperationType type) async {
    _prefs ??= await SharedPreferences.getInstance();
    final today = _getToday();
    final key = '$_keyPrefix${type.name}_$today';

    final count = _prefs?.getInt(key) ?? 0;
    await _prefs?.setInt(key, count + 1);

    debugPrint(
      '📈 UsageTracking: ${type.name} tracked (total today: ${count + 1})',
    );
  }

  /// Track multiple operations at once
  static Future<void> trackBatch(Map<OperationType, int> operations) async {
    _prefs ??= await SharedPreferences.getInstance();
    final today = _getToday();

    for (final entry in operations.entries) {
      final key = '$_keyPrefix${entry.key.name}_$today';
      final count = _prefs?.getInt(key) ?? 0;
      await _prefs?.setInt(key, count + entry.value);
    }
  }

  // ==================== Retrieval ====================

  /// Get today's date string
  static String _getToday() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  /// Get usage count for a specific operation on a date
  static int getOperationCount(OperationType type, String date) {
    final key = '$_keyPrefix${type.name}_$date';
    return _prefs?.getInt(key) ?? 0;
  }

  /// Get daily summary for a specific date
  static DailyUsage getDailySummary(String date) {
    final operations = <OperationType, int>{};
    double totalCost = 0;

    for (final type in OperationType.values) {
      final key = '$_keyPrefix${type.name}_$date';
      final count = _prefs?.getInt(key) ?? 0;
      if (count > 0) {
        operations[type] = count;
        totalCost += count * (_costPerOperation[type] ?? 0);
      }
    }

    return DailyUsage(
      date: date,
      operations: operations,
      estimatedCost: totalCost,
    );
  }

  /// Get usage summary for last N days
  static List<DailyUsage> getUsageSummary({int days = 30}) {
    final summaries = <DailyUsage>[];
    final now = DateTime.now();

    for (var i = 0; i < days; i++) {
      final date = DateFormat(
        'yyyy-MM-dd',
      ).format(now.subtract(Duration(days: i)));
      final summary = getDailySummary(date);
      if (summary.totalOperations > 0) {
        summaries.add(summary);
      }
    }

    return summaries;
  }

  /// Get total estimated cost for a date range
  static double getTotalCost({int days = 30}) {
    return getUsageSummary(
      days: days,
    ).fold(0.0, (sum, usage) => sum + usage.estimatedCost);
  }

  /// Get total operations count for a date range
  static int getTotalOperations({int days = 30}) {
    return getUsageSummary(
      days: days,
    ).fold(0, (sum, usage) => sum + usage.totalOperations);
  }

  // ==================== Monthly Summary ====================

  /// Get monthly summary
  static Map<String, dynamic> getMonthlySummary() {
    final summaries = getUsageSummary(days: 30);
    final totalOps = summaries.fold(0, (sum, u) => sum + u.totalOperations);
    final totalCost = summaries.fold(0.0, (sum, u) => sum + u.estimatedCost);

    // Operation breakdown
    final opBreakdown = <OperationType, int>{};
    for (final summary in summaries) {
      for (final entry in summary.operations.entries) {
        opBreakdown[entry.key] = (opBreakdown[entry.key] ?? 0) + entry.value;
      }
    }

    return {
      'totalOperations': totalOps,
      'totalCost': totalCost,
      'operationBreakdown': opBreakdown,
      'avgDailyOperations': summaries.isEmpty
          ? 0
          : totalOps ~/ summaries.length,
      'avgDailyCost': summaries.isEmpty ? 0.0 : totalCost / summaries.length,
    };
  }

  // ==================== Cleanup ====================

  /// Clear old usage data (older than N days)
  static Future<void> cleanupOldData({int keepDays = 90}) async {
    _prefs ??= await SharedPreferences.getInstance();
    final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));
    final cutoffString = DateFormat('yyyy-MM-dd').format(cutoffDate);

    final keysToDelete = <String>[];
    final allKeys = _prefs?.getKeys() ?? {};

    for (final key in allKeys) {
      if (key.startsWith(_keyPrefix) && key.contains('_')) {
        final parts = key.split('_');
        if (parts.length >= 3) {
          final date = parts.last;
          if (date.compareTo(cutoffString) < 0) {
            keysToDelete.add(key);
          }
        }
      }
    }

    for (final key in keysToDelete) {
      await _prefs?.remove(key);
    }

    debugPrint(
      '🧹 UsageTracking: Cleaned up ${keysToDelete.length} old records',
    );
  }
}
