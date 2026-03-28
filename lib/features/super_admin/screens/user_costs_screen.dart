/// User Costs Screen - Per-user backend usage and costs
library;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/services/user_usage_service.dart';
import 'package:retaillite/features/super_admin/screens/admin_shell_screen.dart';

/// Provider for usage summary
final usageSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return UserUsageService.getUsageSummary();
});

class UserCostsScreen extends ConsumerWidget {
  const UserCostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(usageSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Costs'),
        backgroundColor: Colors.amber.shade700,
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
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(usageSummaryProvider),
          ),
        ],
      ),
      body: summaryAsync.when(
        data: (summary) => _buildContent(context, ref, summary),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> summary,
  ) {
    final totalUsers = summary['totalUsers'] as int? ?? 0;

    // If no usage data, show empty state with seed option
    if (totalUsers == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 64,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 24),
              const Text(
                'No usage data available',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Per-user cost tracking requires usage instrumentation.\n'
                'View actual usage in the Firebase Console.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Firestore usage is visible in Firebase Console → Usage & Billing',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _SeedUsageButton(
                onSeeded: () => ref.invalidate(usageSummaryProvider),
              ),
            ],
          ),
        ),
      );
    }

    final totalCost = summary['totalCost'] as double? ?? 0.0;
    final adminCost = summary['adminCost'] as double? ?? 0.0;
    final userCost = summary['userCost'] as double? ?? 0.0;
    final adminUsers = summary['adminUsers'] as int? ?? 0;
    final regularUsers = summary['regularUsers'] as int? ?? 0;
    final totalReads = summary['totalReads'] as int? ?? 0;
    final totalWrites = summary['totalWrites'] as int? ?? 0;
    final totalFunctionCalls = summary['totalFunctionCalls'] as int? ?? 0;
    final totalNetworkBytes = summary['totalNetworkBytes'] as int? ?? 0;
    final totalStorageUpload = summary['totalStorageUpload'] as int? ?? 0;
    final totalStorageDownload = summary['totalStorageDownload'] as int? ?? 0;
    final users = summary['users'] as List<UserUsage>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          _buildSummaryCards(
            totalCost: totalCost,
            adminCost: adminCost,
            userCost: userCost,
            totalUsers: totalUsers,
            adminUsers: adminUsers,
            regularUsers: regularUsers,
          ),

          const SizedBox(height: 24),

          // All Operations & Costs
          _buildOperationsCard(
            totalReads,
            totalWrites,
            totalFunctionCalls,
            totalNetworkBytes,
            totalStorageUpload,
            totalStorageDownload,
          ),

          const SizedBox(height: 24),

          // Per User Breakdown
          _buildSectionHeader('Per User Breakdown', Icons.people, Colors.blue),
          const SizedBox(height: 12),
          _buildUserList(users),
        ],
      ),
    );
  }

  Widget _buildSummaryCards({
    required double totalCost,
    required double adminCost,
    required double userCost,
    required int totalUsers,
    required int adminUsers,
    required int regularUsers,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        if (isWide) {
          return Row(
            children: [
              Expanded(child: _buildTotalCostCard(totalCost, totalUsers)),
              const SizedBox(width: 12),
              Expanded(child: _buildAdminCostCard(adminCost, adminUsers)),
              const SizedBox(width: 12),
              Expanded(child: _buildUserCostCard(userCost, regularUsers)),
            ],
          );
        } else {
          return Column(
            children: [
              _buildTotalCostCard(totalCost, totalUsers),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildAdminCostCard(adminCost, adminUsers)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildUserCostCard(userCost, regularUsers)),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildTotalCostCard(double cost, int users) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.amber.shade600, Colors.orange.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(Icons.attach_money, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              '\$${cost.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Total Cost (This Month)',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              '$users users',
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCostCard(double cost, int count) {
    return Builder(
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return Card(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: Colors.purple.shade600,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${cost.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.purple.shade700,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Admin Cost',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
                Text(
                  '$count admin${count != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserCostCard(double cost, int count) {
    return Builder(
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return Card(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.people, color: Colors.blue.shade600, size: 28),
                const SizedBox(height: 8),
                Text(
                  '\$${cost.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Regular Users',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
                Text(
                  '$count user${count != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOperationsCard(
    int reads,
    int writes,
    int functionCalls,
    int networkBytes,
    int storageUpload,
    int storageDownload,
  ) {
    return Builder(
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Operations & Bandwidth',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildOperationStat(
                      'Reads',
                      reads,
                      Icons.visibility,
                      Colors.green,
                    ),
                    Container(width: 1, height: 40, color: cs.outlineVariant),
                    _buildOperationStat(
                      'Writes',
                      writes,
                      Icons.edit,
                      Colors.orange,
                    ),
                    Container(width: 1, height: 40, color: cs.outlineVariant),
                    _buildOperationStat(
                      'Functions',
                      functionCalls,
                      Icons.functions,
                      Colors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildOperationStat(
                      'Bandwidth',
                      _formatBytes(networkBytes),
                      Icons.cloud_download,
                      Colors.blue,
                    ),
                    Container(width: 1, height: 40, color: cs.outlineVariant),
                    _buildOperationStat(
                      'Uploads',
                      _formatBytes(storageUpload),
                      Icons.cloud_upload,
                      Colors.teal,
                    ),
                    Container(width: 1, height: 40, color: cs.outlineVariant),
                    _buildOperationStat(
                      'Downloads',
                      _formatBytes(storageDownload),
                      Icons.download,
                      Colors.indigo,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOperationStat(
    String label,
    dynamic value,
    IconData icon,
    Color color,
  ) {
    final displayValue = value is int ? _formatNumber(value) : value.toString();
    return Builder(
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              displayValue,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        );
      },
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

  Widget _buildUserList(List<UserUsage> users) {
    if (users.isEmpty) {
      return Builder(
        builder: (context) {
          final cs = Theme.of(context).colorScheme;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.hourglass_empty,
                      size: 48,
                      color: cs.onSurface.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    const Text('No usage data yet'),
                    const SizedBox(height: 8),
                    Text(
                      'Usage will appear as users interact with the app',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return Column(children: users.map((user) => _buildUserCard(user)).toList());
  }

  Widget _buildUserCard(UserUsage user) {
    final isAdmin = user.isAdmin;
    final color = isAdmin ? Colors.purple : Colors.blue;
    final breakdown = user.costBreakdown;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isAdmin ? Icons.admin_panel_settings : Icons.person,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.email ?? user.odUserId,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isAdmin)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ADMIN',
                            style: TextStyle(
                              color: Colors.purple,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${user.estimatedCost.toStringAsFixed(4)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade700,
                      ),
                    ),
                    Builder(
                      builder: (context) => Text(
                        'est. cost',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Firestore Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildUserStat('Reads', user.firestoreReads, Icons.visibility),
                _buildUserStat('Writes', user.firestoreWrites, Icons.edit),
                _buildUserStat('Deletes', user.firestoreDeletes, Icons.delete),
                _buildUserStat(
                  'Storage',
                  '${user.storageMB.toStringAsFixed(1)}MB',
                  Icons.storage,
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Bandwidth & Functions Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildUserStat(
                  'Bandwidth',
                  _formatBytes(user.networkEgressBytes),
                  Icons.cloud_download,
                ),
                _buildUserStat(
                  'Functions',
                  user.functionCalls,
                  Icons.functions,
                ),
                _buildUserStat(
                  'Uploads',
                  _formatBytes(user.storageUploadBytes),
                  Icons.cloud_upload,
                ),
                _buildUserStat(
                  'Downloads',
                  _formatBytes(user.storageDownloadBytes),
                  Icons.download,
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Cost Breakdown
            Builder(
              builder: (context) => Text(
                'Cost Breakdown',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: breakdown.entries
                  .where((e) => e.value > 0)
                  .map((e) => _buildCostChip(e.key, e.value))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostChip(String category, double cost) {
    final colors = {
      'reads': Colors.green,
      'writes': Colors.orange,
      'deletes': Colors.red,
      'storage': Colors.blueGrey,
      'functions': Colors.purple,
      'bandwidth': Colors.blue,
      'fileStorage': Colors.teal,
      'downloads': Colors.indigo,
    };
    final labels = {
      'reads': 'Reads',
      'writes': 'Writes',
      'deletes': 'Deletes',
      'storage': 'DB Storage',
      'functions': 'Functions',
      'bandwidth': 'Bandwidth',
      'fileStorage': 'File Storage',
      'downloads': 'Downloads',
    };
    final chipColor = colors[category] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${labels[category] ?? category}: \$${cost.toStringAsFixed(5)}',
        style: TextStyle(
          fontSize: 10,
          color: chipColor.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildUserStat(String label, dynamic value, IconData icon) {
    final displayValue = value is int ? _formatNumber(value) : value.toString();

    return Builder(
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return Column(
          children: [
            Icon(icon, size: 16, color: cs.onSurface.withValues(alpha: 0.6)),
            const SizedBox(height: 2),
            Text(
              displayValue,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(
              label,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.6),
                fontSize: 10,
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

/// Button to seed user_usage data from existing users via Cloud Function
class _SeedUsageButton extends StatefulWidget {
  final VoidCallback onSeeded;
  const _SeedUsageButton({required this.onSeeded});

  @override
  State<_SeedUsageButton> createState() => _SeedUsageButtonState();
}

class _SeedUsageButtonState extends State<_SeedUsageButton> {
  bool _loading = false;
  String? _message;

  Future<void> _seedUsage() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final fn = FirebaseFunctions.instanceFor(region: 'asia-south1');
      final result = await fn.httpsCallable('seedUserUsage').call();
      final data = result.data as Map<String, dynamic>?;
      final seeded = data?['seeded'] ?? 0;
      setState(() => _message = 'Seeded $seeded users');
      widget.onSeeded();
    } catch (e) {
      setState(() => _message = 'Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _loading ? null : _seedUsage,
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_arrow),
          label: Text(
            _loading ? 'Seeding...' : 'Seed Usage Data from Existing Users',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        if (_message != null) ...[
          const SizedBox(height: 12),
          Text(
            _message!,
            style: TextStyle(
              color: _message!.startsWith('Error')
                  ? Colors.red
                  : Colors.green.shade700,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }
}
