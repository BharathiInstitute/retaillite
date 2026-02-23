/// Subscriptions Screen for Super Admin
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/features/super_admin/models/admin_user_model.dart';
import 'package:retaillite/features/super_admin/providers/super_admin_provider.dart';
import 'package:retaillite/features/super_admin/screens/admin_shell_screen.dart';

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final expiringAsync = ref.watch(expiringSubscriptionsProvider);
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Cards
            statsAsync.when(
              data: (stats) => _buildStatsRow(stats, isWide),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),

            const SizedBox(height: 24),

            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: statsAsync.when(
                      data: (stats) => _buildPlanBreakdownCard(stats),
                      loading: () => const Card(
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Card(child: Text('Error: $e')),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _buildExpiringCard(expiringAsync)),
                ],
              )
            else ...[
              statsAsync.when(
                data: (stats) => _buildPlanBreakdownCard(stats),
                loading: () => const Card(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Card(child: Text('Error: $e')),
              ),
              const SizedBox(height: 16),
              _buildExpiringCard(expiringAsync),
            ],

            const SizedBox(height: 24),

            // Revenue Card
            statsAsync.when(
              data: (stats) => _buildRevenueCard(stats),
              loading: () => const SizedBox(),
              error: (e, _) => const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(AdminStats stats, bool isWide) {
    final cards = [
      _StatCard(
        title: 'MRR',
        value: '₹${stats.mrr.toStringAsFixed(0)}',
        subtitle: 'Monthly Recurring',
        icon: Icons.currency_rupee,
        color: Colors.green,
      ),
      _StatCard(
        title: 'Paid Users',
        value: stats.paidUsers.toString(),
        subtitle: 'Pro + Business',
        icon: Icons.star,
        color: Colors.purple,
      ),
      _StatCard(
        title: 'Free Users',
        value: stats.freeUsers.toString(),
        subtitle: 'On free plan',
        icon: Icons.person_outline,
        color: Colors.grey,
      ),
      _StatCard(
        title: 'Conversion',
        value: '${stats.conversionRate.toStringAsFixed(1)}%',
        subtitle: 'Free to paid',
        icon: Icons.trending_up,
        color: Colors.blue,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 4 : 2,
        childAspectRatio: isWide ? 2 : 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) => cards[index],
    );
  }

  Widget _buildPlanBreakdownCard(AdminStats stats) {
    final plans = [
      {
        'name': 'Free',
        'count': stats.freeUsers,
        'price': 0,
        'color': Colors.grey,
      },
      {
        'name': 'Pro',
        'count': stats.proUsers,
        'price': 299,
        'color': Colors.blue,
      },
      {
        'name': 'Business',
        'count': stats.businessUsers,
        'price': 999,
        'color': Colors.purple,
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Plan Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...plans.map(
              (plan) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: (plan['color'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          (plan['count'] as int).toString(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: plan['color'] as Color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan['name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            (plan['price'] as int) == 0
                                ? 'Free forever'
                                : '₹${plan['price']}/month',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${((plan['count'] as int) * (plan['price'] as int))}/mo',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total MRR',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${stats.mrr.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiringCard(AsyncValue<List<AdminUser>> expiringAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Expiring Soon',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            expiringAsync.when(
              data: (users) {
                if (users.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'No subscriptions expiring in the next 7 days',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }
                return Column(
                  children: users
                      .map(
                        (user) => ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: _getPlanColor(
                              user.subscription.plan,
                            ),
                            child: Text(
                              user.shopName.isNotEmpty ? user.shopName[0] : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          title: Text(user.shopName),
                          subtitle: Text(
                            user.subscription.expiresAt != null
                                ? 'Expires ${user.subscription.expiresAt!.difference(DateTime.now()).inDays} days'
                                : 'Expiring soon',
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard(AdminStats stats) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.deepPurple, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Text(
              'MONTHLY RECURRING REVENUE',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${stats.mrr.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildRevenueInfo('Pro Users', '${stats.proUsers} × ₹299'),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.white30,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                ),
                _buildRevenueInfo(
                  'Business Users',
                  '${stats.businessUsers} × ₹999',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getPlanColor(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.free:
        return Colors.grey;
      case SubscriptionPlan.pro:
        return Colors.blue;
      case SubscriptionPlan.business:
        return Colors.purple;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
