/// Performance Dashboard Screen - Comprehensive metrics UI
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/services/performance_service.dart';

/// Provider for screen performance data
final screenPerformanceProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  return PerformanceService.getScreenPerformanceSummary();
});

/// Provider for network health data
final networkHealthProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return PerformanceService.getNetworkHealthSummary();
});

/// Provider for crash-free stats
final crashFreeStatsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  return PerformanceService.getCrashFreeStats();
});

class PerformanceScreen extends ConsumerWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenPerfAsync = ref.watch(screenPerformanceProvider);
    final networkHealthAsync = ref.watch(networkHealthProvider);
    final crashFreeAsync = ref.watch(crashFreeStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh data',
            onPressed: () {
              ref.invalidate(screenPerformanceProvider);
              ref.invalidate(networkHealthProvider);
              ref.invalidate(crashFreeStatsProvider);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Cards Row
            crashFreeAsync.when(
              data: (stats) => _buildOverviewCards(
                stats,
                screenPerfAsync.valueOrNull,
                networkHealthAsync.valueOrNull,
              ),
              loading: () => _buildLoadingCard(),
              error: (e, _) => Text('Error: $e'),
            ),

            const SizedBox(height: 24),

            // Screen Performance Section
            _buildSectionHeader('Screen Performance', Icons.speed, Colors.blue),
            const SizedBox(height: 12),
            screenPerfAsync.when(
              data: (data) => _buildScreenPerformanceCard(data),
              loading: () => _buildLoadingCard(),
              error: (e, _) => Text('Error: $e'),
            ),

            const SizedBox(height: 24),

            // Network Health Section
            _buildSectionHeader('Network Health', Icons.wifi, Colors.green),
            const SizedBox(height: 12),
            networkHealthAsync.when(
              data: (data) => _buildNetworkHealthCard(data),
              loading: () => _buildLoadingCard(),
              error: (e, _) => Text('Error: $e'),
            ),

            const SizedBox(height: 24),

            // Breadcrumbs Section
            _buildSectionHeader(
              'Recent Breadcrumbs',
              Icons.timeline,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildBreadcrumbsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildOverviewCards(
    Map<String, dynamic> crashStats,
    Map<String, dynamic>? screenStats,
    Map<String, dynamic>? networkStats,
  ) {
    final crashFree = crashStats['crashFreePercent'] ?? 100.0;
    final avgScreenLoad = screenStats?['avgLoadTime'] ?? 0;
    final avgNetworkLatency = networkStats?['avgLatency'] ?? 0;
    final networkSuccessRate = networkStats?['successRate'] ?? 100;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;

        if (isWide) {
          return Row(
            children: [
              Expanded(child: _buildCrashFreeCard(crashFree)),
              const SizedBox(width: 12),
              Expanded(child: _buildAvgScreenLoadCard(avgScreenLoad)),
              const SizedBox(width: 12),
              Expanded(child: _buildAvgLatencyCard(avgNetworkLatency)),
              const SizedBox(width: 12),
              Expanded(child: _buildSuccessRateCard(networkSuccessRate)),
            ],
          );
        } else {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildCrashFreeCard(crashFree)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildAvgScreenLoadCard(avgScreenLoad)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildAvgLatencyCard(avgNetworkLatency)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSuccessRateCard(networkSuccessRate)),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildCrashFreeCard(double percent) {
    final isHealthy = percent >= 99;
    final isWarning = percent >= 95 && percent < 99;

    // Use MaterialColor for gradient
    MaterialColor materialColor = isHealthy
        ? Colors.green
        : (isWarning ? Colors.orange : Colors.red);

    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [materialColor.shade600, materialColor.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              isHealthy
                  ? Icons.verified
                  : (isWarning ? Icons.warning : Icons.error),
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              '${percent.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Crash-Free Users',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvgScreenLoadCard(int avgMs) {
    final isGood = avgMs < 300;
    final isOkay = avgMs >= 300 && avgMs < 600;

    Color color = isGood ? Colors.blue : (isOkay ? Colors.orange : Colors.red);

    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.speed, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              '${avgMs}ms',
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Avg Screen Load',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvgLatencyCard(int avgMs) {
    final isGood = avgMs < 200;
    final isOkay = avgMs >= 200 && avgMs < 500;

    Color color = isGood ? Colors.teal : (isOkay ? Colors.orange : Colors.red);

    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.network_check, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              '${avgMs}ms',
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Avg API Latency',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessRateCard(int rate) {
    final isGood = rate >= 99;
    final isOkay = rate >= 95 && rate < 99;

    Color color = isGood ? Colors.green : (isOkay ? Colors.orange : Colors.red);

    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.check_circle, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              '$rate%',
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'API Success Rate',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenPerformanceCard(Map<String, dynamic> data) {
    final screens = data['screens'] as Map<String, int>? ?? {};
    final totalMeasurements = data['totalMeasurements'] ?? 0;

    if (screens.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.hourglass_empty,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                const Text('No screen data yet'),
                const SizedBox(height: 8),
                Text(
                  'Data will appear as users navigate the app',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Sort screens by load time (slowest first)
    final sortedScreens = screens.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '$totalMeasurements measurements (24h)',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...sortedScreens.map(
              (entry) => _buildScreenRow(entry.key, entry.value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenRow(String screenName, int avgMs) {
    // Normalize for progress bar (max 1000ms)
    final progress = (avgMs / 1000).clamp(0.0, 1.0);

    // Color based on performance
    Color color;
    String status;
    if (avgMs < 300) {
      color = Colors.green;
      status = 'Fast';
    } else if (avgMs < 600) {
      color = Colors.orange;
      status = 'OK';
    } else {
      color = Colors.red;
      status = 'Slow!';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  screenName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${avgMs}ms',
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkHealthCard(Map<String, dynamic> data) {
    final operations =
        data['operations'] as Map<String, Map<String, dynamic>>? ?? {};
    final totalRequests = data['totalRequests'] ?? 0;

    if (operations.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text('No network data yet'),
                const SizedBox(height: 8),
                Text(
                  'Data will appear as API calls are made',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '$totalRequests requests (24h)',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...operations.entries.map(
              (entry) => _buildNetworkRow(
                entry.key,
                entry.value['avgLatency'] as int? ?? 0,
                entry.value['successRate'] as int? ?? 100,
                entry.value['count'] as int? ?? 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkRow(
    String type,
    int avgLatency,
    int successRate,
    int count,
  ) {
    // Determine icon based on type
    IconData icon;
    switch (type.toLowerCase()) {
      case 'firestore':
        icon = Icons.storage;
        break;
      case 'auth':
        icon = Icons.security;
        break;
      case 'storage':
        icon = Icons.cloud;
        break;
      default:
        icon = Icons.http;
    }

    // Color based on success rate
    Color rateColor = successRate >= 99
        ? Colors.green
        : (successRate >= 95 ? Colors.orange : Colors.red);

    // Color based on latency
    Color latencyColor = avgLatency < 200
        ? Colors.green
        : (avgLatency < 500 ? Colors.orange : Colors.red);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.grey.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '$count calls',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer, size: 14, color: latencyColor),
                  const SizedBox(width: 4),
                  Text(
                    '${avgLatency}ms',
                    style: TextStyle(
                      color: latencyColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 14, color: rateColor),
                  const SizedBox(width: 4),
                  Text(
                    '$successRate%',
                    style: TextStyle(color: rateColor, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbsCard() {
    final breadcrumbs = PerformanceService.getBreadcrumbs();

    if (breadcrumbs.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.timeline, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text('No breadcrumbs recorded'),
                const SizedBox(height: 8),
                Text(
                  'Breadcrumbs track user actions for debugging',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show last 10 breadcrumbs
    final recentBreadcrumbs = breadcrumbs.reversed.take(10).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${breadcrumbs.length} total breadcrumbs',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    PerformanceService.clearBreadcrumbs();
                  },
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...recentBreadcrumbs.map((b) => _buildBreadcrumbRow(b)),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumbRow(Breadcrumb breadcrumb) {
    // Icon based on type
    IconData icon;
    Color color;
    switch (breadcrumb.type) {
      case BreadcrumbType.navigation:
        icon = Icons.navigation;
        color = Colors.blue;
        break;
      case BreadcrumbType.tap:
        icon = Icons.touch_app;
        color = Colors.purple;
        break;
      case BreadcrumbType.input:
        icon = Icons.edit;
        color = Colors.orange;
        break;
      case BreadcrumbType.api:
        icon = Icons.cloud;
        color = Colors.green;
        break;
      case BreadcrumbType.lifecycle:
        icon = Icons.refresh;
        color = Colors.grey;
        break;
      case BreadcrumbType.custom:
        icon = Icons.label;
        color = Colors.teal;
        break;
    }

    final timeAgo = DateTime.now().difference(breadcrumb.timestamp);
    String timeStr;
    if (timeAgo.inSeconds < 60) {
      timeStr = '${timeAgo.inSeconds}s ago';
    } else if (timeAgo.inMinutes < 60) {
      timeStr = '${timeAgo.inMinutes}m ago';
    } else {
      timeStr = '${timeAgo.inHours}h ago';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              breadcrumb.message,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text(
            timeStr,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
