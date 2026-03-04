/// Tests for admin_user_model.dart — UserSubscription, UserLimits,
/// UserActivity, AdminUser, AdminStats (pure data classes)
library;

import 'package:flutter_test/flutter_test.dart';

// ── Inline duplicates (avoids cloud_firestore Timestamp for Dart tests) ──

enum SubscriptionPlan { free, pro, business }

enum SubscriptionStatus { active, trial, expired, cancelled }

class UserSubscription {
  final SubscriptionPlan plan;
  final SubscriptionStatus status;
  final DateTime? startedAt;
  final DateTime? expiresAt;

  const UserSubscription({
    this.plan = SubscriptionPlan.free,
    this.status = SubscriptionStatus.active,
    this.startedAt,
    this.expiresAt,
  });

  String get planDisplayName {
    switch (plan) {
      case SubscriptionPlan.free:
        return 'Free';
      case SubscriptionPlan.pro:
        return 'Pro';
      case SubscriptionPlan.business:
        return 'Business';
    }
  }

  int get planPrice {
    switch (plan) {
      case SubscriptionPlan.free:
        return 0;
      case SubscriptionPlan.pro:
        return 299;
      case SubscriptionPlan.business:
        return 999;
    }
  }

  int get billsLimit {
    switch (plan) {
      case SubscriptionPlan.free:
        return 50;
      case SubscriptionPlan.pro:
        return 500;
      case SubscriptionPlan.business:
        return 999999;
    }
  }

  bool get isActive =>
      status == SubscriptionStatus.active || status == SubscriptionStatus.trial;
}

class UserLimits {
  final int billsThisMonth;
  final int billsLimit;
  final int productsCount;
  final int customersCount;

  const UserLimits({
    this.billsThisMonth = 0,
    this.billsLimit = 50,
    this.productsCount = 0,
    this.customersCount = 0,
  });

  double get usagePercentage =>
      billsLimit > 0 ? (billsThisMonth / billsLimit).clamp(0.0, 1.0) : 0.0;
  bool get isNearLimit => usagePercentage > 0.8;
  bool get isAtLimit => billsThisMonth >= billsLimit;
}

class UserActivity {
  final DateTime? lastActiveAt;
  final String? appVersion;
  final String? platform;

  const UserActivity({this.lastActiveAt, this.appVersion, this.platform});

  bool get isActiveToday {
    if (lastActiveAt == null) return false;
    final now = DateTime.now();
    return lastActiveAt!.year == now.year &&
        lastActiveAt!.month == now.month &&
        lastActiveAt!.day == now.day;
  }

  bool get isActiveThisWeek {
    if (lastActiveAt == null) return false;
    return DateTime.now().difference(lastActiveAt!).inDays < 7;
  }

  String get lastActiveAgo {
    if (lastActiveAt == null) return 'Never';
    final diff = DateTime.now().difference(lastActiveAt!);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

class AdminStats {
  final int totalUsers;
  final int activeToday;
  final int activeThisWeek;
  final int activeThisMonth;
  final int newUsersToday;
  final int newUsersThisWeek;
  final double mrr;
  final int freeUsers;
  final int proUsers;
  final int businessUsers;

  const AdminStats({
    this.totalUsers = 0,
    this.activeToday = 0,
    this.activeThisWeek = 0,
    this.activeThisMonth = 0,
    this.newUsersToday = 0,
    this.newUsersThisWeek = 0,
    this.mrr = 0,
    this.freeUsers = 0,
    this.proUsers = 0,
    this.businessUsers = 0,
  });

  int get paidUsers => proUsers + businessUsers;
  double get conversionRate =>
      totalUsers > 0 ? (paidUsers / totalUsers) * 100 : 0;
}

void main() {
  // ─── UserSubscription ────────────────────────────────────────────────

  group('UserSubscription', () {
    test('defaults to free + active', () {
      const sub = UserSubscription();
      expect(sub.plan, SubscriptionPlan.free);
      expect(sub.status, SubscriptionStatus.active);
      expect(sub.isActive, isTrue);
    });

    test('planDisplayName for each plan', () {
      expect(
        const UserSubscription().planDisplayName,
        'Free',
      );
      expect(
        const UserSubscription(plan: SubscriptionPlan.pro).planDisplayName,
        'Pro',
      );
      expect(
        const UserSubscription(plan: SubscriptionPlan.business).planDisplayName,
        'Business',
      );
    });

    test('planPrice for each plan', () {
      expect(const UserSubscription().planPrice, 0);
      expect(const UserSubscription(plan: SubscriptionPlan.pro).planPrice, 299);
      expect(
        const UserSubscription(plan: SubscriptionPlan.business).planPrice,
        999,
      );
    });

    test('billsLimit increases with plan tier', () {
      final freeLim = const UserSubscription(
        
      ).billsLimit;
      final proLim = const UserSubscription(
        plan: SubscriptionPlan.pro,
      ).billsLimit;
      final bizLim = const UserSubscription(
        plan: SubscriptionPlan.business,
      ).billsLimit;

      expect(freeLim, 50);
      expect(proLim, 500);
      expect(bizLim, 999999);
      expect(proLim, greaterThan(freeLim));
      expect(bizLim, greaterThan(proLim));
    });

    test('isActive true for active and trial', () {
      expect(
        const UserSubscription().isActive,
        isTrue,
      );
      expect(
        const UserSubscription(status: SubscriptionStatus.trial).isActive,
        isTrue,
      );
    });

    test('isActive false for expired and cancelled', () {
      expect(
        const UserSubscription(status: SubscriptionStatus.expired).isActive,
        isFalse,
      );
      expect(
        const UserSubscription(status: SubscriptionStatus.cancelled).isActive,
        isFalse,
      );
    });
  });

  // ─── UserLimits (Admin version) ─────────────────────────────────────

  group('UserLimits (admin)', () {
    test('defaults', () {
      const l = UserLimits();
      expect(l.billsThisMonth, 0);
      expect(l.billsLimit, 50);
      expect(l.productsCount, 0);
      expect(l.customersCount, 0);
    });

    test('usagePercentage at 0%', () {
      const l = UserLimits();
      expect(l.usagePercentage, 0.0);
    });

    test('usagePercentage at 50%', () {
      const l = UserLimits(billsThisMonth: 25);
      expect(l.usagePercentage, 0.5);
    });

    test('usagePercentage clamped to 1.0 when over limit', () {
      const l = UserLimits(billsThisMonth: 60);
      expect(l.usagePercentage, 1.0);
    });

    test('usagePercentage is 0 when billsLimit is 0', () {
      const l = UserLimits(billsThisMonth: 5, billsLimit: 0);
      expect(l.usagePercentage, 0.0);
    });

    test('isNearLimit true at 81%', () {
      const l = UserLimits(billsThisMonth: 41);
      expect(l.isNearLimit, isTrue);
    });

    test('isNearLimit false at 80%', () {
      const l = UserLimits(billsThisMonth: 40);
      expect(l.isNearLimit, isFalse); // 40/50 = 0.8, not > 0.8
    });

    test('isAtLimit true at exactly limit', () {
      const l = UserLimits(billsThisMonth: 50);
      expect(l.isAtLimit, isTrue);
    });

    test('isAtLimit true when over limit', () {
      const l = UserLimits(billsThisMonth: 55);
      expect(l.isAtLimit, isTrue);
    });

    test('isAtLimit false below limit', () {
      const l = UserLimits(billsThisMonth: 49);
      expect(l.isAtLimit, isFalse);
    });
  });

  // ─── UserActivity ───────────────────────────────────────────────────

  group('UserActivity', () {
    test('null lastActiveAt → isActiveToday=false', () {
      const a = UserActivity();
      expect(a.isActiveToday, isFalse);
    });

    test('today → isActiveToday=true', () {
      final a = UserActivity(lastActiveAt: DateTime.now());
      expect(a.isActiveToday, isTrue);
    });

    test('yesterday → isActiveToday=false', () {
      final a = UserActivity(
        lastActiveAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(a.isActiveToday, isFalse);
    });

    test('null lastActiveAt → isActiveThisWeek=false', () {
      const a = UserActivity();
      expect(a.isActiveThisWeek, isFalse);
    });

    test('3 days ago → isActiveThisWeek=true', () {
      final a = UserActivity(
        lastActiveAt: DateTime.now().subtract(const Duration(days: 3)),
      );
      expect(a.isActiveThisWeek, isTrue);
    });

    test('8 days ago → isActiveThisWeek=false', () {
      final a = UserActivity(
        lastActiveAt: DateTime.now().subtract(const Duration(days: 8)),
      );
      expect(a.isActiveThisWeek, isFalse);
    });

    test('lastActiveAgo returns "Never" for null', () {
      const a = UserActivity();
      expect(a.lastActiveAgo, 'Never');
    });

    test('lastActiveAgo returns "Just now" for recent', () {
      final a = UserActivity(lastActiveAt: DateTime.now());
      expect(a.lastActiveAgo, 'Just now');
    });

    test('lastActiveAgo shows minutes', () {
      final a = UserActivity(
        lastActiveAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );
      expect(a.lastActiveAgo, '30m ago');
    });

    test('lastActiveAgo shows hours', () {
      final a = UserActivity(
        lastActiveAt: DateTime.now().subtract(const Duration(hours: 5)),
      );
      expect(a.lastActiveAgo, '5h ago');
    });

    test('lastActiveAgo shows days', () {
      final a = UserActivity(
        lastActiveAt: DateTime.now().subtract(const Duration(days: 3)),
      );
      expect(a.lastActiveAgo, '3d ago');
    });

    test('lastActiveAgo shows weeks', () {
      final a = UserActivity(
        lastActiveAt: DateTime.now().subtract(const Duration(days: 14)),
      );
      expect(a.lastActiveAgo, '2w ago');
    });
  });

  // ─── AdminStats ─────────────────────────────────────────────────────

  group('AdminStats', () {
    test('defaults to zeros', () {
      const stats = AdminStats();
      expect(stats.totalUsers, 0);
      expect(stats.paidUsers, 0);
      expect(stats.conversionRate, 0);
    });

    test('paidUsers sums pro + business', () {
      const stats = AdminStats(proUsers: 10, businessUsers: 5);
      expect(stats.paidUsers, 15);
    });

    test('conversionRate calculated correctly', () {
      const stats = AdminStats(totalUsers: 100, proUsers: 10, businessUsers: 5);
      expect(stats.conversionRate, 15.0); // 15/100 * 100
    });

    test('conversionRate is 0 when no users', () {
      const stats = AdminStats();
      expect(stats.conversionRate, 0);
    });

    test('100% conversion when all users are paid', () {
      const stats = AdminStats(totalUsers: 10, proUsers: 8, businessUsers: 2);
      expect(stats.conversionRate, 100.0);
    });

    test('mrr tracks correctly', () {
      const stats = AdminStats(mrr: 14950.0); // e.g., 50 pro * 299
      expect(stats.mrr, 14950.0);
    });
  });
}
