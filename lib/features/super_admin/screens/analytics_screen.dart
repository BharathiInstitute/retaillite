/// Analytics Screen for Super Admin
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/features/super_admin/providers/super_admin_provider.dart';
import 'package:retaillite/features/super_admin/screens/admin_shell_screen.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final platformStatsAsync = ref.watch(platformStatsProvider);
    final featureUsageAsync = ref.watch(featureUsageProvider);
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        leading: MediaQuery.of(context).size.width >= 1024
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  adminShellScaffoldKey.currentState?.openDrawer();
                },
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(adminStatsProvider);
              ref.invalidate(platformStatsProvider);
              ref.invalidate(featureUsageProvider);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Users Section
            const Text(
              'User Activity',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            statsAsync.when(
              data: (stats) => _buildActiveUsersGrid(stats, isWide),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),

            const SizedBox(height: 32),

            // User Growth Section
            const Text(
              'User Growth',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            statsAsync.when(
              data: (stats) => _buildGrowthCards(stats, isWide),
              loading: () => const SizedBox(),
              error: (e, _) => const SizedBox(),
            ),

            const SizedBox(height: 32),

            // Feature Usage (Real data)
            featureUsageAsync.when(
              data: (featureStats) => _buildFeatureUsageCard(featureStats),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) =>
                  Card(child: Text('Error loading feature usage: $e')),
            ),

            const SizedBox(height: 32),

            // Platform Distribution (Real data)
            platformStatsAsync.when(
              data: (platformStats) => _buildPlatformCard(platformStats),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) =>
                  Card(child: Text('Error loading platform stats: $e')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveUsersGrid(dynamic stats, bool isWide) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 900 ? 4 : 2;
        final aspectRatio = crossAxisCount == 4 ? 1.5 : 1.6;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: aspectRatio,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildMetricCard(
              'DAU',
              stats.activeToday.toString(),
              'Daily Active Users',
              Icons.today,
              Colors.blue,
            ),
            _buildMetricCard(
              'WAU',
              stats.activeThisWeek.toString(),
              'Weekly Active Users',
              Icons.date_range,
              Colors.green,
            ),
            _buildMetricCard(
              'MAU',
              stats.activeThisMonth.toString(),
              'Monthly Active Users',
              Icons.calendar_month,
              Colors.orange,
            ),
            _buildMetricCard(
              'Total',
              stats.totalUsers.toString(),
              'Total Registered',
              Icons.people,
              Colors.purple,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthCards(dynamic stats, bool isWide) {
    return Row(
      children: [
        Expanded(
          child: Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                children: [
                  const Icon(Icons.person_add, color: Colors.green, size: 20),
                  const SizedBox(height: 2),
                  Text(
                    stats.newUsersToday.toString(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const Text('New Users Today', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                children: [
                  const Icon(Icons.group_add, color: Colors.blue, size: 20),
                  const SizedBox(height: 2),
                  Text(
                    stats.newUsersThisWeek.toString(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const Text(
                    'New Users This Week',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureUsageCard(Map<String, double> featureStats) {
    // Map feature keys to display names and colors
    final featureConfig = {
      'billing': {'name': 'Billing', 'color': Colors.green},
      'products': {'name': 'Products', 'color': Colors.blue},
      'khata': {'name': 'Customers (Khata)', 'color': Colors.orange},
      'reports': {'name': '~Reports (est.)', 'color': Colors.purple},
      'settings': {'name': '~Settings (est.)', 'color': Colors.grey},
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Feature Usage',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            const SizedBox(height: 8),
            Text(
              'Billing, Products, Khata from data · Reports & Settings estimated',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 20),
            ...featureConfig.entries.map((entry) {
              final usage = featureStats[entry.key] ?? 0.0;
              final config = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(config['name'] as String),
                        Text(
                          '${(usage * 100).toInt()}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: usage.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(
                          config['color'] as Color,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformCard(Map<String, int> platformStats) {
    // Map platform keys to display config
    final platformConfig = {
      'android': {
        'name': 'Android',
        'icon': Icons.android,
        'color': Colors.green,
      },
      'ios': {
        'name': 'iOS',
        'icon': Icons.apple,
        'color': Colors.grey.shade800,
      },
      'web': {'name': 'Web', 'icon': Icons.web, 'color': Colors.blue},
      'windows': {
        'name': 'Windows',
        'icon': Icons.desktop_windows,
        'color': Colors.lightBlue,
      },
      'macos': {
        'name': 'macOS',
        'icon': Icons.laptop_mac,
        'color': Colors.grey.shade700,
      },
      'linux': {
        'name': 'Linux',
        'icon': Icons.computer,
        'color': Colors.orange,
      },
      'unknown': {
        'name': 'Unknown',
        'icon': Icons.device_unknown,
        'color': Colors.grey,
      },
    };

    // Filter only platforms with users
    final activePlatforms = platformStats.entries
        .where((e) => e.value > 0)
        .toList();

    if (activePlatforms.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.devices_other,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No platform data yet',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Platform info is recorded when users log in',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
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
                const Text(
                  'Platform Distribution',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            const SizedBox(height: 8),
            Text(
              'Where users access the app from',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: activePlatforms.map((entry) {
                final config =
                    platformConfig[entry.key] ?? platformConfig['unknown']!;
                return Container(
                  width: 100,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (config['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        config['icon'] as IconData,
                        color: config['color'] as Color,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${entry.value}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: config['color'] as Color,
                        ),
                      ),
                      Text(
                        config['name'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
