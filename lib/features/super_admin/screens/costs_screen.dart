/// Costs Screen for Super Admin — Revenue analytics from real Firestore data
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/features/super_admin/providers/super_admin_provider.dart';
import 'package:retaillite/features/super_admin/screens/admin_shell_screen.dart';

class CostsScreen extends ConsumerWidget {
  const CostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revenue & Costs'),
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
            onPressed: () => ref.invalidate(adminStatsProvider),
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRevenueCard(stats),
              const SizedBox(height: 16),
              _buildBreakdownCards(stats),
              const SizedBox(height: 16),
              _buildCostNote(),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
      ),
    );
  }

  // ─── Revenue Card (real MRR data) ───

  Widget _buildRevenueCard(dynamic stats) {
    final revenuePerUser = (stats.totalUsers as int) > 0
        ? stats.mrr / stats.totalUsers
        : 0.0;
    final paidUsers = stats.proUsers + stats.businessUsers;
    final paidUsersRatio = (stats.totalUsers as int) > 0
        ? (paidUsers / stats.totalUsers * 100)
        : 0.0;

    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade600, Colors.deepPurple.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(Icons.trending_up, size: 40, color: Colors.white70),
            const SizedBox(height: 12),
            Text(
              '₹${stats.mrr.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Monthly Recurring Revenue',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _miniStat('Per User', '₹${revenuePerUser.toStringAsFixed(1)}'),
                _miniStat('Paid Users', '$paidUsers'),
                _miniStat('Paid %', '${paidUsersRatio.toStringAsFixed(1)}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
      ],
    );
  }

  // ─── Subscription Breakdown Cards ───

  Widget _buildBreakdownCards(dynamic stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Subscription Breakdown',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _planCard(
                'Free',
                stats.freeUsers as int,
                '₹0',
                Colors.grey,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _planCard(
                'Pro',
                stats.proUsers as int,
                '₹299/mo',
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _planCard(
                'Business',
                stats.businessUsers as int,
                '₹999/mo',
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _planCard(String plan, int count, String price, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(plan, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
              price,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Cost Note ───

  Widget _buildCostNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'For actual Firebase infrastructure costs, visit the Firebase Console → Usage and billing.',
              style: TextStyle(color: Colors.blue.shade800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
