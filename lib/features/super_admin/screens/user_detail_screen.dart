/// User Detail Screen for Super Admin
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/features/super_admin/models/admin_user_model.dart';
import 'package:retaillite/features/super_admin/providers/super_admin_provider.dart';
import 'package:retaillite/features/super_admin/services/admin_firestore_service.dart';

class UserDetailScreen extends ConsumerWidget {
  final String userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDetailProvider(userId));
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User not found'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: isWide
                ? _buildWideLayout(context, user, ref)
                : _buildNarrowLayout(context, user, ref),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context, AdminUser user, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side - Profile & Subscription
        Expanded(
          child: Column(
            children: [
              _buildProfileCard(user),
              const SizedBox(height: 16),
              _buildSubscriptionCard(context, user, ref),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Right side - Stats & Activity
        Expanded(
          child: Column(
            children: [
              _buildUsageStatsCard(user),
              const SizedBox(height: 16),
              _buildActivityCard(user),
              const SizedBox(height: 16),
              _buildAdminActionsCard(context, user, ref),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(
    BuildContext context,
    AdminUser user,
    WidgetRef ref,
  ) {
    return Column(
      children: [
        _buildProfileCard(user),
        const SizedBox(height: 16),
        _buildSubscriptionCard(context, user, ref),
        const SizedBox(height: 16),
        _buildUsageStatsCard(user),
        const SizedBox(height: 16),
        _buildActivityCard(user),
        const SizedBox(height: 16),
        _buildAdminActionsCard(context, user, ref),
      ],
    );
  }

  Widget _buildProfileCard(AdminUser user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: _getPlanColor(user.subscription.plan),
              child: Text(
                user.shopName.isNotEmpty ? user.shopName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 32),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.shopName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              user.ownerName,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            _buildPlanBadge(user.subscription.plan, large: true),
            const SizedBox(height: 24),
            _buildInfoRow(Icons.email, user.email),
            if (user.phone != null) _buildInfoRow(Icons.phone, user.phone!),
            if (user.address != null)
              _buildInfoRow(Icons.location_on, user.address!),
            if (user.gstNumber != null)
              _buildInfoRow(Icons.badge, 'GST: ${user.gstNumber}'),
            _buildInfoRow(
              Icons.calendar_today,
              'Joined ${user.daysSinceRegistration} days ago',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(
    BuildContext context,
    AdminUser user,
    WidgetRef ref,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Subscription',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Plan'),
                _buildPlanBadge(user.subscription.plan),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Status'),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: user.subscription.isActive
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.subscription.status.name.toUpperCase(),
                    style: TextStyle(
                      color: user.subscription.isActive
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Price'),
                Text(
                  user.subscription.planPrice > 0
                      ? '₹${user.subscription.planPrice}/month'
                      : 'Free',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (user.subscription.expiresAt != null) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Expires'),
                  Text(
                    '${user.subscription.expiresAt!.day}/${user.subscription.expiresAt!.month}/${user.subscription.expiresAt!.year}',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUsageStatsCard(AdminUser user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Usage Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildUsageRow(
              'Bills This Month',
              user.limits.billsThisMonth,
              user.limits.billsLimit,
              user.limits.usagePercentage,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatBox(
                    'Products',
                    user.limits.productsCount.toString(),
                    Icons.inventory,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatBox(
                    'Customers',
                    user.limits.customersCount.toString(),
                    Icons.people,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageRow(String label, int current, int max, double percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              '$current / $max',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(
              percentage > 0.8 ? Colors.orange : Colors.green,
            ),
          ),
        ),
        if (percentage > 0.8)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '⚠️ Approaching limit',
              style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildActivityCard(AdminUser user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildActivityRow(
              'Last Active',
              user.activity.lastActiveAgo,
              user.activity.isActiveToday ? Colors.green : Colors.grey,
            ),
            if (user.activity.platform != null)
              _buildActivityRow(
                'Platform',
                user.activity.platform!,
                Colors.blue,
              ),
            if (user.activity.appVersion != null)
              _buildActivityRow(
                'App Version',
                user.activity.appVersion!,
                Colors.purple,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityRow(String label, String value, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: dotColor),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildAdminActionsCard(
    BuildContext context,
    AdminUser user,
    WidgetRef ref,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.upgrade),
                label: const Text('Change Subscription'),
                onPressed: () =>
                    _showChangeSubscriptionDialog(context, user, ref),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Reset Monthly Limits'),
                onPressed: () => _resetLimits(context, user),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeSubscriptionDialog(
    BuildContext context,
    AdminUser user,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current plan: ${user.subscription.planDisplayName}'),
            const SizedBox(height: 16),
            ...SubscriptionPlan.values.map(
              (plan) => ListTile(
                title: Text(plan.name.toUpperCase()),
                subtitle: Text(
                  plan == SubscriptionPlan.free
                      ? 'Free'
                      : '₹${UserSubscription(plan: plan).planPrice}/month',
                ),
                trailing: user.subscription.plan == plan
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () async {
                  Navigator.pop(context);
                  final newSubscription = UserSubscription(
                    plan: plan,
                    status: SubscriptionStatus.active,
                    startedAt: DateTime.now(),
                    expiresAt: plan == SubscriptionPlan.free
                        ? null
                        : DateTime.now().add(const Duration(days: 30)),
                  );
                  final success =
                      await AdminFirestoreService.updateUserSubscription(
                        user.id,
                        newSubscription,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Subscription updated!'
                              : 'Failed to update',
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                    if (success) {
                      ref.invalidate(userDetailProvider(user.id));
                    }
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _resetLimits(BuildContext context, AdminUser user) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Limits reset functionality - coming soon')),
    );
  }

  Widget _buildPlanBadge(SubscriptionPlan plan, {bool large = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 8,
        vertical: large ? 6 : 2,
      ),
      decoration: BoxDecoration(
        color: _getPlanColor(plan).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(large ? 16 : 12),
        border: Border.all(color: _getPlanColor(plan)),
      ),
      child: Text(
        plan.name.toUpperCase(),
        style: TextStyle(
          fontSize: large ? 14 : 10,
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
}
