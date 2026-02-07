/// Super Admin Dashboard - Main overview screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:retaillite/features/super_admin/models/admin_user_model.dart';
import 'package:retaillite/features/super_admin/providers/super_admin_provider.dart';
import 'package:retaillite/core/theme/responsive_helper.dart';

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
      drawer: isWide ? null : _buildDrawer(context),
      body: Row(
        children: [
          // Sidebar for desktop
          if (isWide) _buildSidebar(context),

          // Main content
          Expanded(
            child: RefreshIndicator(
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
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
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
                            child: _buildRecentUsersCard(
                              recentUsersAsync,
                              context,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: statsAsync.when(
                              data: (stats) =>
                                  _buildSubscriptionBreakdown(stats),
                              loading: () => const Card(
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
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
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 220,
      color: Colors.grey.shade100,
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildNavItem(
            context,
            Icons.dashboard,
            'Overview',
            '/super-admin',
            true,
          ),
          _buildNavItem(
            context,
            Icons.people,
            'Users',
            '/super-admin/users',
            false,
          ),
          _buildNavItem(
            context,
            Icons.credit_card,
            'Subscriptions',
            '/super-admin/subscriptions',
            false,
          ),
          _buildNavItem(
            context,
            Icons.analytics,
            'Analytics',
            '/super-admin/analytics',
            false,
          ),
          _buildNavItem(
            context,
            Icons.bug_report,
            'Errors',
            '/super-admin/errors',
            false,
          ),
          _buildNavItem(
            context,
            Icons.speed,
            'Performance',
            '/super-admin/performance',
            false,
          ),
          _buildNavItem(
            context,
            Icons.monetization_on,
            'User Costs',
            '/super-admin/user-costs',
            false,
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.deepPurple, Colors.purple],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Text(
                    'Super Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Full Access',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          // Logout button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    String route,
    bool isActive,
  ) {
    return ListTile(
      leading: Icon(icon, color: isActive ? Colors.deepPurple : Colors.grey),
      title: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.deepPurple : Colors.grey.shade700,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isActive,
      selectedTileColor: Colors.deepPurple.withValues(alpha: 0.1),
      onTap: () => context.go(route),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.purple],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Super Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Full Access',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Overview'),
            onTap: () => context.go('/super-admin'),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Users'),
            onTap: () => context.go('/super-admin/users'),
          ),
          ListTile(
            leading: const Icon(Icons.credit_card),
            title: const Text('Subscriptions'),
            onTap: () => context.go('/super-admin/subscriptions'),
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Analytics'),
            onTap: () => context.go('/super-admin/analytics'),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Errors'),
            onTap: () => context.go('/super-admin/errors'),
          ),
          ListTile(
            leading: const Icon(Icons.speed),
            title: const Text('Performance'),
            onTap: () => context.go('/super-admin/performance'),
          ),
          ListTile(
            leading: const Icon(Icons.monetization_on),
            title: const Text('User Costs'),
            onTap: () => context.go('/super-admin/user-costs'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Back to App'),
            onTap: () => context.go('/billing'),
          ),
        ],
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout from Super Admin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
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
