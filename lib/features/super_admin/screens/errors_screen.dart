/// Errors Screen for Super Admin - View crash reports and errors
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:retaillite/core/services/app_health_service.dart';
import 'package:retaillite/core/services/error_logging_service.dart';

/// Provider for error logs
final errorLogsProvider = FutureProvider<List<ErrorLogEntry>>((ref) async {
  return ErrorLoggingService.getRecentErrors();
});

/// Provider for health summary
final healthSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return AppHealthService.getHealthSummary();
});

/// Provider for error count by platform
final errorsByPlatformProvider = FutureProvider<Map<String, int>>((ref) async {
  return ErrorLoggingService.getErrorCountByPlatform();
});

class ErrorsScreen extends ConsumerWidget {
  const ErrorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorsAsync = ref.watch(errorLogsProvider);
    final healthAsync = ref.watch(healthSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Errors & Health'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(errorLogsProvider);
              ref.invalidate(healthSummaryProvider);
              ref.invalidate(errorsByPlatformProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Open Firebase Crashlytics',
            onPressed: () {
              // Could open Firebase Console URL
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Health Summary
            healthAsync.when(
              data: (health) => _buildHealthSummary(health),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => Card(child: Text('Error: $e')),
            ),

            const SizedBox(height: 24),

            // Error Logs
            const Text(
              'Recent Errors',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Web errors logged to Firestore. Mobile crashes in Firebase Crashlytics.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 16),
            errorsAsync.when(
              data: (errors) => errors.isEmpty
                  ? _buildNoErrorsCard()
                  : _buildErrorsList(errors),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading logs: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthSummary(Map<String, dynamic> health) {
    final sessions = (health['sessionsLast24h'] as int?) ?? 0;
    final errors = (health['errorsLast24h'] as int?) ?? 0;
    final avgStartup = ((health['avgStartupTimeMs'] as num?) ?? 0).toDouble();
    final errorRate = ((health['errorRate'] as num?) ?? 0).toDouble();

    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              errorRate > 5 ? Colors.red.shade600 : Colors.green.shade600,
              errorRate > 5 ? Colors.red.shade400 : Colors.green.shade400,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.health_and_safety, color: Colors.white),
                const SizedBox(width: 8),
                const Text(
                  'App Health (Last 24h)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    errorRate < 1
                        ? 'HEALTHY'
                        : (errorRate < 5 ? 'WARNING' : 'CRITICAL'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHealthMetric(
                  'Sessions',
                  sessions.toString(),
                  Icons.login,
                ),
                _buildHealthMetric('Errors', errors.toString(), Icons.error),
                _buildHealthMetric(
                  'Avg Startup',
                  '${avgStartup.toStringAsFixed(0)}ms',
                  Icons.timer,
                ),
                _buildHealthMetric(
                  'Error Rate',
                  '${errorRate.toStringAsFixed(1)}%',
                  Icons.percent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildNoErrorsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.check_circle, size: 64, color: Colors.green.shade400),
              const SizedBox(height: 16),
              const Text(
                'No recent errors!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Your app is running smoothly',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorsList(List<ErrorLogEntry> errors) {
    return Column(
      children: errors.map((error) => _buildErrorCard(error)).toList(),
    );
  }

  Widget _buildErrorCard(ErrorLogEntry error) {
    final dateFormat = DateFormat('MMM d, h:mm a');

    Color severityColor;
    IconData severityIcon;
    switch (error.severity) {
      case ErrorSeverity.critical:
        severityColor = Colors.red;
        severityIcon = Icons.dangerous;
        break;
      case ErrorSeverity.error:
        severityColor = Colors.orange;
        severityIcon = Icons.error;
        break;
      case ErrorSeverity.warning:
        severityColor = Colors.amber;
        severityIcon = Icons.warning;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: severityColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(severityIcon, color: severityColor, size: 20),
        ),
        title: Text(
          error.message.length > 60
              ? '${error.message.substring(0, 60)}...'
              : error.message,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        subtitle: Row(
          children: [
            Icon(
              _getPlatformIcon(error.platform),
              size: 14,
              color: Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              error.platform.toUpperCase(),
              style: const TextStyle(fontSize: 11),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.access_time, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              dateFormat.format(error.timestamp),
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Full Message:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(error.message),
                if (error.stackTrace != null) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Stack Trace:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        error.stackTrace!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
                if (error.userId != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'User ID: ${error.userId}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
                if (error.screenName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Screen: ${error.screenName}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'android':
        return Icons.android;
      case 'ios':
        return Icons.apple;
      case 'web':
        return Icons.web;
      case 'windows':
        return Icons.desktop_windows;
      case 'macos':
        return Icons.laptop_mac;
      case 'linux':
        return Icons.computer;
      default:
        return Icons.device_unknown;
    }
  }
}
