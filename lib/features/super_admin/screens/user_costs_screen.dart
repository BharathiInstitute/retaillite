/// User Costs Screen - Per-user backend usage and costs
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/services/user_usage_service.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(usageSummaryProvider),
          ),
        ],
      ),
      body: summaryAsync.when(
        data: (summary) => _buildContent(summary),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> summary) {
    final totalCost = summary['totalCost'] as double? ?? 0.0;
    final adminCost = summary['adminCost'] as double? ?? 0.0;
    final userCost = summary['userCost'] as double? ?? 0.0;
    final totalUsers = summary['totalUsers'] as int? ?? 0;
    final adminUsers = summary['adminUsers'] as int? ?? 0;
    final regularUsers = summary['regularUsers'] as int? ?? 0;
    final totalReads = summary['totalReads'] as int? ?? 0;
    final totalWrites = summary['totalWrites'] as int? ?? 0;
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

          // Total Operations
          _buildOperationsCard(totalReads, totalWrites),

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
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
            Text(
              '$count admin${count != 1 ? 's' : ''}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCostCard(double cost, int count) {
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
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
            Text(
              '$count user${count != 1 ? 's' : ''}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationsCard(int reads, int writes) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildOperationStat('Reads', reads, Icons.visibility, Colors.green),
            Container(width: 1, height: 40, color: Colors.grey.shade300),
            _buildOperationStat('Writes', writes, Icons.edit, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationStat(
    String label,
    int count,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          _formatNumber(count),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
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
                const Text('No usage data yet'),
                const SizedBox(height: 8),
                Text(
                  'Usage will appear as users interact with the app',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(children: users.map((user) => _buildUserCard(user)).toList());
  }

  Widget _buildUserCard(UserUsage user) {
    final isAdmin = user.isAdmin;
    final color = isAdmin ? Colors.purple : Colors.blue;

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
                      '\$${user.estimatedCost.toStringAsFixed(3)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade700,
                      ),
                    ),
                    const Text(
                      'est. cost',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Stats
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
          ],
        ),
      ),
    );
  }

  Widget _buildUserStat(String label, dynamic value, IconData icon) {
    final displayValue = value is int ? _formatNumber(value) : value.toString();

    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(height: 2),
        Text(
          displayValue,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
        ),
      ],
    );
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
