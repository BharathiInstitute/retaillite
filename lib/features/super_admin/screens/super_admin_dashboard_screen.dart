/// Super Admin Dashboard - Main overview screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retaillite/features/super_admin/models/admin_user_model.dart';
import 'package:retaillite/features/super_admin/providers/super_admin_provider.dart';
import 'package:retaillite/core/theme/responsive_helper.dart';
import 'package:retaillite/features/notifications/services/notification_firestore_service.dart';

class SuperAdminDashboardScreen extends ConsumerWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if user is authorized as super admin
    final isSuperAdmin = ref.watch(isSuperAdminProvider);

    if (!isSuperAdmin) {
      // Show access denied and redirect to billing
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.red),
              const SizedBox(height: 24),
              const Text(
                'Access Denied',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You are not authorized to access the Super Admin panel.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/billing'),
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      );
    }

    final statsAsync = ref.watch(adminStatsProvider);
    final recentUsersAsync = ref.watch(recentUsersProvider);
    final isWide = !ResponsiveHelper.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Dashboard'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(adminStatsProvider);
              ref.invalidate(recentUsersProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminStatsProvider);
          ref.invalidate(recentUsersProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Cards
              statsAsync.when(
                data: (stats) => _buildStatsGrid(stats, isWide),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),

              const SizedBox(height: 24),

              // Two column layout for desktop
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildRecentUsersCard(recentUsersAsync, context),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: statsAsync.when(
                        data: (stats) => _buildSubscriptionBreakdown(stats),
                        loading: () => const Card(
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, _) => Card(child: Text('Error: $e')),
                      ),
                    ),
                  ],
                )
              else ...[
                _buildRecentUsersCard(recentUsersAsync, context),
                const SizedBox(height: 16),
                statsAsync.when(
                  data: (stats) => _buildSubscriptionBreakdown(stats),
                  loading: () => const Card(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Card(child: Text('Error: $e')),
                ),
                const SizedBox(height: 16),
                _buildNotificationsCard(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(AdminStats stats, bool isWide) {
    final cards = [
      _StatCard(
        title: 'Total Users',
        value: stats.totalUsers.toString(),
        icon: Icons.people,
        color: Colors.blue,
      ),
      _StatCard(
        title: 'Active Today',
        value: stats.activeToday.toString(),
        icon: Icons.trending_up,
        color: Colors.green,
      ),
      _StatCard(
        title: 'MRR',
        value: '₹${stats.mrr.toStringAsFixed(0)}',
        icon: Icons.currency_rupee,
        color: Colors.orange,
      ),
      _StatCard(
        title: 'Paid Users',
        value: stats.paidUsers.toString(),
        icon: Icons.star,
        color: Colors.purple,
      ),
      _StatCard(
        title: 'New This Week',
        value: stats.newUsersThisWeek.toString(),
        icon: Icons.person_add,
        color: Colors.teal,
      ),
      _StatCard(
        title: 'Conversion',
        value: '${stats.conversionRate.toStringAsFixed(1)}%',
        icon: Icons.pie_chart,
        color: Colors.indigo,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 6 : 2,
        childAspectRatio: isWide ? 1.5 : 1.3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) => cards[index],
    );
  }

  Widget _buildRecentUsersCard(
    AsyncValue<List<AdminUser>> usersAsync,
    BuildContext context,
  ) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Users',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => context.go('/super-admin/users'),
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          usersAsync.when(
            data: (users) => ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getPlanColor(user.subscription.plan),
                    child: Text(
                      user.shopName.isNotEmpty
                          ? user.shopName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(user.shopName),
                  subtitle: Text(user.email),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildPlanBadge(user.subscription.plan),
                      Text(
                        user.activity.lastActiveAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => context.go('/super-admin/users/${user.id}'),
                );
              },
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: $e'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionBreakdown(AdminStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Subscription Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPlanRow(
              'Free',
              stats.freeUsers,
              stats.totalUsers,
              Colors.grey,
            ),
            const SizedBox(height: 12),
            _buildPlanRow('Pro', stats.proUsers, stats.totalUsers, Colors.blue),
            const SizedBox(height: 12),
            _buildPlanRow(
              'Business',
              stats.businessUsers,
              stats.totalUsers,
              Colors.purple,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.deepPurple, Colors.purple],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Monthly Revenue',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    '₹${stats.mrr.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanRow(String plan, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(plan, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('$count users (${(percentage * 100).toStringAsFixed(0)}%)'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ],
    );
  }

  Widget _buildPlanBadge(SubscriptionPlan plan) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getPlanColor(plan).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getPlanColor(plan)),
      ),
      child: Text(
        plan.name.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: _getPlanColor(plan),
        ),
      ),
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

  Widget _buildNotificationsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications, color: Colors.deepPurple),
                const SizedBox(width: 8),
                const Text(
                  'Recent Notifications',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => context.go('/super-admin/notifications'),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: NotificationFirestoreService.getNotificationHistory(
                limit: 3,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final history = snapshot.data ?? [];
                if (history.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 40,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No notifications sent yet',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: history.map((notif) {
                    final title = (notif['title'] as String?) ?? 'Untitled';
                    final type = (notif['type'] as String?) ?? 'system';
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        _typeIcon(type),
                        color: _typeColor(type),
                        size: 20,
                      ),
                      title: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        type.toUpperCase(),
                        style: TextStyle(fontSize: 10, color: _typeColor(type)),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.go('/super-admin/notifications'),
                icon: const Icon(Icons.send, size: 16),
                label: const Text('Send New Notification'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    return switch (type) {
      'announcement' => Icons.campaign,
      'alert' => Icons.warning_amber,
      'reminder' => Icons.alarm,
      _ => Icons.info_outline,
    };
  }

  Color _typeColor(String type) {
    return switch (type) {
      'announcement' => Colors.blue,
      'alert' => Colors.orange,
      'reminder' => Colors.green,
      _ => Colors.grey,
    };
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
