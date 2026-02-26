import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/features/super_admin/models/admin_user_model.dart';

void main() {
  // ── UserSubscription ──

  group('UserSubscription', () {
    test('defaults to free/active', () {
      const sub = UserSubscription();
      expect(sub.plan, SubscriptionPlan.free);
      expect(sub.status, SubscriptionStatus.active);
    });

    test('planDisplayName for free', () {
      const sub = UserSubscription();
      expect(sub.planDisplayName, 'Free');
    });

    test('planDisplayName for pro', () {
      const sub = UserSubscription(plan: SubscriptionPlan.pro);
      expect(sub.planDisplayName, 'Pro');
    });

    test('planDisplayName for business', () {
      const sub = UserSubscription(plan: SubscriptionPlan.business);
      expect(sub.planDisplayName, 'Business');
    });

    test('planPrice for free is 0', () {
      const sub = UserSubscription();
      expect(sub.planPrice, 0);
    });

    test('planPrice for pro is 299', () {
      const sub = UserSubscription(plan: SubscriptionPlan.pro);
      expect(sub.planPrice, 299);
    });

    test('planPrice for business is 999', () {
      const sub = UserSubscription(plan: SubscriptionPlan.business);
      expect(sub.planPrice, 999);
    });

    test('billsLimit for free is 50', () {
      const sub = UserSubscription();
      expect(sub.billsLimit, 50);
    });

    test('billsLimit for pro is 500', () {
      const sub = UserSubscription(plan: SubscriptionPlan.pro);
      expect(sub.billsLimit, 500);
    });

    test('billsLimit for business is unlimited', () {
      const sub = UserSubscription(plan: SubscriptionPlan.business);
      expect(sub.billsLimit, 999999);
    });

    test('isActive for active status', () {
      const sub = UserSubscription();
      expect(sub.isActive, isTrue);
    });

    test('isActive for trial status', () {
      const sub = UserSubscription(status: SubscriptionStatus.trial);
      expect(sub.isActive, isTrue);
    });

    test('isActive is false for expired', () {
      const sub = UserSubscription(status: SubscriptionStatus.expired);
      expect(sub.isActive, isFalse);
    });

    test('isActive is false for cancelled', () {
      const sub = UserSubscription(status: SubscriptionStatus.cancelled);
      expect(sub.isActive, isFalse);
    });

    test('toMap includes all fields', () {
      const sub = UserSubscription(plan: SubscriptionPlan.pro);
      final map = sub.toMap();
      expect(map['plan'], 'pro');
      expect(map['status'], 'active');
    });

    test('fromMap with null returns defaults', () {
      final sub = UserSubscription.fromMap(null);
      expect(sub.plan, SubscriptionPlan.free);
      expect(sub.status, SubscriptionStatus.active);
    });

    test('fromMap parses plan and status', () {
      final sub = UserSubscription.fromMap({
        'plan': 'business',
        'status': 'trial',
      });
      expect(sub.plan, SubscriptionPlan.business);
      expect(sub.status, SubscriptionStatus.trial);
    });

    test('fromMap handles unknown plan gracefully', () {
      final sub = UserSubscription.fromMap({
        'plan': 'enterprise',
        'status': 'active',
      });
      expect(sub.plan, SubscriptionPlan.free);
    });
  });

  // ── UserLimits ──

  group('UserLimits', () {
    test('defaults to zero usage', () {
      const limits = UserLimits();
      expect(limits.billsThisMonth, 0);
      expect(limits.billsLimit, 50);
      expect(limits.productsCount, 0);
    });

    test('usagePercentage at half', () {
      const limits = UserLimits(billsThisMonth: 25);
      expect(limits.usagePercentage, closeTo(0.5, 0.01));
    });

    test('usagePercentage at full', () {
      const limits = UserLimits(billsThisMonth: 50);
      expect(limits.usagePercentage, 1.0);
    });

    test('usagePercentage clamped above 1', () {
      const limits = UserLimits(billsThisMonth: 100);
      expect(limits.usagePercentage, 1.0);
    });

    test('usagePercentage is 0 when limit is 0', () {
      const limits = UserLimits(billsThisMonth: 10, billsLimit: 0);
      expect(limits.usagePercentage, 0.0);
    });

    test('isNearLimit when over 80%', () {
      const limits = UserLimits(billsThisMonth: 41);
      expect(limits.isNearLimit, isTrue);
    });

    test('isNearLimit is false when under 80%', () {
      const limits = UserLimits(billsThisMonth: 30);
      expect(limits.isNearLimit, isFalse);
    });

    test('isAtLimit when at exact limit', () {
      const limits = UserLimits(billsThisMonth: 50);
      expect(limits.isAtLimit, isTrue);
    });

    test('isAtLimit when over limit', () {
      const limits = UserLimits(billsThisMonth: 51);
      expect(limits.isAtLimit, isTrue);
    });

    test('isAtLimit is false when under limit', () {
      const limits = UserLimits(billsThisMonth: 49);
      expect(limits.isAtLimit, isFalse);
    });

    test('fromMap with null returns defaults', () {
      final limits = UserLimits.fromMap(null);
      expect(limits.billsThisMonth, 0);
      expect(limits.billsLimit, 50);
    });

    test('fromMap parses values', () {
      final limits = UserLimits.fromMap({
        'billsThisMonth': 25,
        'billsLimit': 100,
        'productsCount': 50,
        'customersCount': 30,
      });
      expect(limits.billsThisMonth, 25);
      expect(limits.billsLimit, 100);
      expect(limits.productsCount, 50);
      expect(limits.customersCount, 30);
    });
  });

  // ── UserActivity ──

  group('UserActivity', () {
    test('defaults to null values', () {
      const activity = UserActivity();
      expect(activity.lastActiveAt, isNull);
      expect(activity.appVersion, isNull);
      expect(activity.platform, isNull);
    });

    test('isActiveToday when last active now', () {
      final activity = UserActivity(lastActiveAt: DateTime.now());
      expect(activity.isActiveToday, isTrue);
    });

    test('isActiveToday is false for yesterday', () {
      final activity = UserActivity(
        lastActiveAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(activity.isActiveToday, isFalse);
    });

    test('isActiveToday is false when null', () {
      const activity = UserActivity();
      expect(activity.isActiveToday, isFalse);
    });

    test('isActiveThisWeek for recent activity', () {
      final activity = UserActivity(
        lastActiveAt: DateTime.now().subtract(const Duration(days: 3)),
      );
      expect(activity.isActiveThisWeek, isTrue);
    });

    test('isActiveThisWeek is false for old activity', () {
      final activity = UserActivity(
        lastActiveAt: DateTime.now().subtract(const Duration(days: 10)),
      );
      expect(activity.isActiveThisWeek, isFalse);
    });

    test('lastActiveAgo returns Never when null', () {
      const activity = UserActivity();
      expect(activity.lastActiveAgo, 'Never');
    });

    test('lastActiveAgo returns Just now', () {
      final activity = UserActivity(lastActiveAt: DateTime.now());
      expect(activity.lastActiveAgo, 'Just now');
    });

    test('lastActiveAgo returns minutes', () {
      final activity = UserActivity(
        lastActiveAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );
      expect(activity.lastActiveAgo, contains('m ago'));
    });

    test('lastActiveAgo returns hours', () {
      final activity = UserActivity(
        lastActiveAt: DateTime.now().subtract(const Duration(hours: 5)),
      );
      expect(activity.lastActiveAgo, contains('h ago'));
    });

    test('lastActiveAgo returns days', () {
      final activity = UserActivity(
        lastActiveAt: DateTime.now().subtract(const Duration(days: 3)),
      );
      expect(activity.lastActiveAgo, contains('d ago'));
    });

    test('lastActiveAgo returns weeks', () {
      final activity = UserActivity(
        lastActiveAt: DateTime.now().subtract(const Duration(days: 14)),
      );
      expect(activity.lastActiveAgo, contains('w ago'));
    });

    test('fromMap with null returns defaults', () {
      final activity = UserActivity.fromMap(null);
      expect(activity.lastActiveAt, isNull);
    });

    test('fromMap parses string fields', () {
      final activity = UserActivity.fromMap({
        'appVersion': '1.2.3',
        'platform': 'android',
      });
      expect(activity.appVersion, '1.2.3');
      expect(activity.platform, 'android');
    });
  });

  // ── AdminStats ──

  group('AdminStats', () {
    test('defaults to zeros', () {
      const stats = AdminStats();
      expect(stats.totalUsers, 0);
      expect(stats.paidUsers, 0);
      expect(stats.mrr, 0);
    });

    test('paidUsers is sum of pro and business', () {
      const stats = AdminStats(proUsers: 10, businessUsers: 5);
      expect(stats.paidUsers, 15);
    });

    test('conversionRate calculates correctly', () {
      const stats = AdminStats(totalUsers: 100, proUsers: 15, businessUsers: 5);
      expect(stats.conversionRate, 20.0);
    });

    test('conversionRate is 0 when no users', () {
      const stats = AdminStats();
      expect(stats.conversionRate, 0);
    });

    test('conversionRate at 100%', () {
      const stats = AdminStats(totalUsers: 50, proUsers: 30, businessUsers: 20);
      expect(stats.conversionRate, 100.0);
    });
  });

  // ── AdminUser ──

  group('AdminUser', () {
    test('daysSinceRegistration is 0 when null', () {
      const user = AdminUser(
        id: '1',
        email: 'test@example.com',
        shopName: 'Test Shop',
        ownerName: 'Test Owner',
      );
      expect(user.daysSinceRegistration, 0);
    });

    test('daysSinceRegistration calculates from creation date', () {
      final user = AdminUser(
        id: '1',
        email: 'test@example.com',
        shopName: 'Test Shop',
        ownerName: 'Test Owner',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      );
      expect(user.daysSinceRegistration, closeTo(30, 1));
    });
  });
}
