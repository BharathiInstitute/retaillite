/// Subscriptions Screen for Super Admin
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:retaillite/features/super_admin/models/admin_user_model.dart';
import 'package:retaillite/features/super_admin/providers/super_admin_provider.dart';
import 'package:retaillite/features/super_admin/screens/admin_shell_screen.dart';
import 'package:retaillite/features/super_admin/services/admin_firestore_service.dart';

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

            const SizedBox(height: 24),

            // Manage Subscriptions — full user list
            _buildManageSection(ref),
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

  Color _getStatusColor(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.active:
        return Colors.green;
      case SubscriptionStatus.trial:
        return Colors.orange;
      case SubscriptionStatus.expired:
        return Colors.red;
      case SubscriptionStatus.cancelled:
        return Colors.grey;
    }
  }

  /// Manage Subscriptions section with user list and edit buttons
  Widget _buildManageSection(WidgetRef ref) {
    final usersAsync = ref.watch(usersListProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.manage_accounts, color: Colors.deepPurple),
                const SizedBox(width: 8),
                const Text(
                  'Manage Subscriptions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: () => ref.invalidate(usersListProvider),
                ),
              ],
            ),
            const SizedBox(height: 16),
            usersAsync.when(
              data: (users) {
                if (users.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No users found'),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _buildUserTile(context, ref, user);
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTile(BuildContext context, WidgetRef ref, AdminUser user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getPlanColor(user.subscription.plan),
        child: Text(
          user.shopName.isNotEmpty ? user.shopName[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        user.shopName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text('${user.email} • ${user.ownerName}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Plan badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getPlanColor(
                user.subscription.plan,
              ).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              user.subscription.planDisplayName,
              style: TextStyle(
                color: _getPlanColor(user.subscription.plan),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(
                user.subscription.status,
              ).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              user.subscription.status.name.toUpperCase(),
              style: TextStyle(
                color: _getStatusColor(user.subscription.status),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Edit button
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            tooltip: 'Edit subscription',
            onPressed: () => _showEditDialog(context, ref, user),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, AdminUser user) {
    var selectedPlan = user.subscription.plan;
    var selectedStatus = user.subscription.status;
    var expiresAt = user.subscription.expiresAt;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text('Edit: ${user.shopName}'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Owner: ${user.ownerName}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    Text(
                      'Email: ${user.email}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),

                    // Plan selector
                    const Text(
                      'Plan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<SubscriptionPlan>(
                      segments: SubscriptionPlan.values.map((p) {
                        return ButtonSegment(
                          value: p,
                          label: Text(
                            p.name[0].toUpperCase() + p.name.substring(1),
                          ),
                        );
                      }).toList(),
                      selected: {selectedPlan},
                      onSelectionChanged: (val) {
                        setDialogState(() => selectedPlan = val.first);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Status selector
                    const Text(
                      'Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<SubscriptionStatus>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: SubscriptionStatus.values.map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 10,
                                color: _getStatusColor(s),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                s.name[0].toUpperCase() + s.name.substring(1),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null)
                          setDialogState(() => selectedStatus = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Expiry date
                    const Text(
                      'Expires At',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate:
                              expiresAt ??
                              DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setDialogState(() => expiresAt = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              expiresAt != null
                                  ? DateFormat('dd MMM yyyy').format(expiresAt!)
                                  : 'No expiry (Free plan)',
                            ),
                            const Spacer(),
                            if (expiresAt != null)
                              InkWell(
                                onTap: () =>
                                    setDialogState(() => expiresAt = null),
                                child: const Icon(Icons.clear, size: 18),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final newSub = UserSubscription(
                      plan: selectedPlan,
                      status: selectedStatus,
                      startedAt: user.subscription.startedAt ?? DateTime.now(),
                      expiresAt: expiresAt,
                      razorpaySubscriptionId:
                          user.subscription.razorpaySubscriptionId,
                    );
                    await AdminFirestoreService.updateUserSubscription(
                      user.id,
                      newSub,
                    );
                    // Refresh providers
                    ref.invalidate(usersListProvider);
                    ref.invalidate(adminStatsProvider);
                    ref.invalidate(expiringSubscriptionsProvider);
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Updated ${user.shopName} to ${selectedPlan.name} / ${selectedStatus.name}',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
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
