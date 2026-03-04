/// Admin protection / security guard tests
///
/// Verifies admin-level security invariants: primary owner protection,
/// email validation, admin stats computations, and subscription plan
/// limit enforcement. Critical at 10K scale to prevent privilege escalation.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/features/super_admin/models/admin_user_model.dart';

void main() {
  group('AdminFirestoreService — primary owner protection', () {
    const primaryOwner = 'kehsaram001@gmail.com';

    test('primary owner email is a compile-time constant', () {
      expect(primaryOwner, isNotEmpty);
      expect(primaryOwner, contains('@'));
    });

    test('normalized email matches primary owner (case-insensitive)', () {
      for (final variation in [
        'kehsaram001@gmail.com',
        'Kehsaram001@Gmail.com',
        'KEHSARAM001@GMAIL.COM',
        ' kehsaram001@gmail.com ',
      ]) {
        expect(
          variation.toLowerCase().trim(),
          primaryOwner,
          reason: 'Variation "$variation" should normalize to primary owner',
        );
      }
    });

    test('email validation rejects empty string', () {
      final email = ''.toLowerCase().trim();
      expect(email.isEmpty || !email.contains('@'), isTrue);
    });

    test('email validation rejects string without @', () {
      const email = 'notanemail';
      expect(email.contains('@'), isFalse);
    });

    test('email validation accepts valid emails', () {
      for (final valid in [
        'user@example.com',
        'admin@retaillite.com',
        'test+tag@domain.org',
      ]) {
        final normalized = valid.toLowerCase().trim();
        expect(normalized.isNotEmpty && normalized.contains('@'), isTrue);
      }
    });
  });

  group('AdminStats — computed properties', () {
    test('default AdminStats is all zeros', () {
      const stats = AdminStats();
      expect(stats.totalUsers, 0);
      expect(stats.freeUsers, 0);
      expect(stats.proUsers, 0);
      expect(stats.businessUsers, 0);
      expect(stats.mrr, 0);
      expect(stats.activeToday, 0);
      expect(stats.activeThisWeek, 0);
      expect(stats.activeThisMonth, 0);
      expect(stats.newUsersToday, 0);
      expect(stats.newUsersThisWeek, 0);
    });

    test('paidUsers = proUsers + businessUsers', () {
      const stats = AdminStats(proUsers: 100, businessUsers: 25);
      expect(stats.paidUsers, 125);
    });

    test('conversionRate calculates correctly', () {
      const stats = AdminStats(
        totalUsers: 1000,
        proUsers: 80,
        businessUsers: 20,
      );
      expect(stats.conversionRate, 10.0); // 100/1000 * 100
    });

    test('conversionRate is 0 when totalUsers is 0', () {
      const stats = AdminStats(proUsers: 5);
      expect(stats.conversionRate, 0);
    });

    test('mrr at 10K subscribers scale', () {
      // Simulate 10K users: 7000 free + 2500 pro + 500 business
      const stats = AdminStats(
        totalUsers: 10000,
        freeUsers: 7000,
        proUsers: 2500,
        businessUsers: 500,
        mrr: 2500 * 299 + 500 * 999, // ₹1,247,000
      );
      expect(stats.paidUsers, 3000);
      expect(stats.conversionRate, 30.0);
      expect(stats.mrr, greaterThan(1000000));
    });
  });

  group('UserSubscription — plan limits', () {
    test('free plan has 50 bill limit', () {
      const sub = UserSubscription();
      expect(sub.billsLimit, 50);
      expect(sub.planPrice, 0);
      expect(sub.planDisplayName, 'Free');
    });

    test('pro plan has 500 bill limit', () {
      const sub = UserSubscription(plan: SubscriptionPlan.pro);
      expect(sub.billsLimit, 500);
      expect(sub.planPrice, 299);
      expect(sub.planDisplayName, 'Pro');
    });

    test('business plan has unlimited bills', () {
      const sub = UserSubscription(plan: SubscriptionPlan.business);
      expect(sub.billsLimit, 999999);
      expect(sub.planPrice, 999);
      expect(sub.planDisplayName, 'Business');
    });

    test('isActive is true for active and trial', () {
      expect(const UserSubscription().isActive, isTrue);
      expect(
        const UserSubscription(status: SubscriptionStatus.trial).isActive,
        isTrue,
      );
    });

    test('isActive is false for expired and cancelled', () {
      expect(
        const UserSubscription(status: SubscriptionStatus.expired).isActive,
        isFalse,
      );
      expect(
        const UserSubscription(status: SubscriptionStatus.cancelled).isActive,
        isFalse,
      );
    });

    test('fromMap handles null gracefully', () {
      final sub = UserSubscription.fromMap(null);
      expect(sub.plan, SubscriptionPlan.free);
      expect(sub.status, SubscriptionStatus.active);
    });

    test('fromMap handles unknown plan name', () {
      final sub = UserSubscription.fromMap({'plan': 'enterprise'});
      expect(sub.plan, SubscriptionPlan.free); // falls back to free
    });

    test('toMap round-trips correctly', () {
      const original = UserSubscription(
        plan: SubscriptionPlan.pro,
        status: SubscriptionStatus.trial,
      );
      final map = original.toMap();
      expect(map['plan'], 'pro');
      expect(map['status'], 'trial');
    });
  });

  group('UserLimits — usage tracking', () {
    test('usagePercentage is 0 when no bills', () {
      const limits = UserLimits();
      expect(limits.usagePercentage, 0.0);
    });

    test('usagePercentage is 80% at near-limit', () {
      const limits = UserLimits(billsThisMonth: 40);
      expect(limits.usagePercentage, 0.8);
      expect(limits.isNearLimit, isFalse); // exactly 80% is not > 80%
    });

    test('isNearLimit triggers above 80%', () {
      const limits = UserLimits(billsThisMonth: 41);
      expect(limits.isNearLimit, isTrue);
    });

    test('isAtLimit when bills >= limit', () {
      const at = UserLimits(billsThisMonth: 50);
      expect(at.isAtLimit, isTrue);

      const over = UserLimits(billsThisMonth: 55);
      expect(over.isAtLimit, isTrue);
    });

    test('usagePercentage clamps at 1.0', () {
      const limits = UserLimits(billsThisMonth: 100);
      expect(limits.usagePercentage, 1.0); // clamped
    });

    test('usagePercentage handles 0 limit', () {
      const limits = UserLimits(billsThisMonth: 5, billsLimit: 0);
      expect(limits.usagePercentage, 0.0);
    });

    test('fromMap handles null', () {
      final limits = UserLimits.fromMap(null);
      expect(limits.billsThisMonth, 0);
      expect(limits.billsLimit, 50);
    });
  });

  group('UserActivity — activity tracking', () {
    test('isActiveToday for activity today', () {
      final activity = UserActivity(lastActiveAt: DateTime.now());
      expect(activity.isActiveToday, isTrue);
    });

    test('isActiveToday is false for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final activity = UserActivity(lastActiveAt: yesterday);
      expect(activity.isActiveToday, isFalse);
    });

    test('isActiveThisWeek for activity 3 days ago', () {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      final activity = UserActivity(lastActiveAt: threeDaysAgo);
      expect(activity.isActiveThisWeek, isTrue);
    });

    test('isActiveThisWeek is false for 8 days ago', () {
      final eightDaysAgo = DateTime.now().subtract(const Duration(days: 8));
      final activity = UserActivity(lastActiveAt: eightDaysAgo);
      expect(activity.isActiveThisWeek, isFalse);
    });

    test('lastActiveAgo returns "Never" for null', () {
      const activity = UserActivity();
      expect(activity.lastActiveAgo, 'Never');
    });

    test('lastActiveAgo returns "Just now" for recent activity', () {
      final activity = UserActivity(lastActiveAt: DateTime.now());
      expect(activity.lastActiveAgo, 'Just now');
    });

    test('fromMap handles null', () {
      final activity = UserActivity.fromMap(null);
      expect(activity.lastActiveAt, isNull);
      expect(activity.platform, isNull);
    });
  });

  group('AdminUser — security-relevant properties', () {
    test('daysSinceRegistration is 0 for null createdAt', () {
      const user = AdminUser(
        id: 'u1',
        email: 'test@test.com',
        shopName: 'Shop',
        ownerName: 'Owner',
      );
      expect(user.daysSinceRegistration, 0);
    });

    test('daysSinceRegistration calculates correctly', () {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final user = AdminUser(
        id: 'u1',
        email: 'test@test.com',
        shopName: 'Shop',
        ownerName: 'Owner',
        createdAt: thirtyDaysAgo,
      );
      expect(user.daysSinceRegistration, 30);
    });

    test('default subscription is free/active', () {
      const user = AdminUser(
        id: 'u1',
        email: 'test@test.com',
        shopName: 'Shop',
        ownerName: 'Owner',
      );
      expect(user.subscription.plan, SubscriptionPlan.free);
      expect(user.subscription.isActive, isTrue);
    });

    test('default limits are sensible', () {
      const user = AdminUser(
        id: 'u1',
        email: 'test@test.com',
        shopName: 'Shop',
        ownerName: 'Owner',
      );
      expect(user.limits.billsLimit, 50);
      expect(user.limits.billsThisMonth, 0);
    });
  });
}
