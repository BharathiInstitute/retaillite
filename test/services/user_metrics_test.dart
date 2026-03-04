/// Tests for UserMetricsService — subscription plans, limits, and activity
///
/// Tests pure logic only (no Firebase). Avoids Timestamp-dependent API calls.
/// Uses inline duplicates to avoid transitive Firebase import chain.
library;

import 'package:flutter_test/flutter_test.dart';

// ── Inline duplicates (avoid user_metrics_service → error_logging → main → billing_screen) ──

enum SubscriptionPlan { free, pro, business }

enum SubscriptionStatus { active, trial, expired, cancelled }

class UserSubscription {
  final SubscriptionPlan plan;
  final SubscriptionStatus status;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final String? razorpayCustomerId;
  final String? razorpaySubscriptionId;

  UserSubscription({
    this.plan = SubscriptionPlan.free,
    this.status = SubscriptionStatus.active,
    this.startedAt,
    this.expiresAt,
    this.razorpayCustomerId,
    this.razorpaySubscriptionId,
  });

  factory UserSubscription.fromMap(Map<String, dynamic>? map) {
    if (map == null) return UserSubscription();
    return UserSubscription(
      plan: SubscriptionPlan.values.firstWhere(
        (e) => e.name == map['plan'],
        orElse: () => SubscriptionPlan.free,
      ),
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SubscriptionStatus.active,
      ),
      razorpayCustomerId: map['razorpayCustomerId'] as String?,
      razorpaySubscriptionId: map['razorpaySubscriptionId'] as String?,
    );
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

  int get productsLimit {
    switch (plan) {
      case SubscriptionPlan.free:
        return 100;
      case SubscriptionPlan.pro:
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
  final int productsLimit;
  final int customersCount;
  final int customersLimit;

  UserLimits({
    this.billsThisMonth = 0,
    this.billsLimit = 50,
    this.productsCount = 0,
    this.productsLimit = 100,
    this.customersCount = 0,
    this.customersLimit = 10,
  });

  Map<String, dynamic> toMap() => {
    'billsThisMonth': billsThisMonth,
    'billsLimit': billsLimit,
    'productsCount': productsCount,
    'productsLimit': productsLimit,
    'customersCount': customersCount,
    'customersLimit': customersLimit,
  };

  factory UserLimits.fromMap(Map<String, dynamic>? map) {
    if (map == null) return UserLimits();
    return UserLimits(
      billsThisMonth: (map['billsThisMonth'] as int?) ?? 0,
      billsLimit: (map['billsLimit'] as int?) ?? 50,
      productsCount: (map['productsCount'] as int?) ?? 0,
      productsLimit: (map['productsLimit'] as int?) ?? 100,
      customersCount: (map['customersCount'] as int?) ?? 0,
      customersLimit: (map['customersLimit'] as int?) ?? 10,
    );
  }

  bool get canCreateBill => billsThisMonth < billsLimit;
  bool get canAddProduct => productsCount < productsLimit;
  bool get canAddCustomer => customersCount < customersLimit;
  int get billsRemaining => billsLimit - billsThisMonth;
  int get productsRemaining => productsLimit - productsCount;
  int get customersRemaining => customersLimit - customersCount;
}

void main() {
  group('UserSubscription', () {
    test('free plan should have correct limits', () {
      final sub = UserSubscription();

      expect(sub.billsLimit, 50);
      expect(sub.productsLimit, 100);
      expect(sub.isActive, true);
    });

    test('pro plan should have correct limits', () {
      final sub = UserSubscription(plan: SubscriptionPlan.pro);

      expect(sub.billsLimit, 500);
      expect(sub.productsLimit, 999999);
    });

    test('business plan should have unlimited', () {
      final sub = UserSubscription(plan: SubscriptionPlan.business);

      expect(sub.billsLimit, 999999);
      expect(sub.productsLimit, 999999);
    });

    test('active subscription should be active', () {
      final sub = UserSubscription(plan: SubscriptionPlan.pro);
      expect(sub.isActive, true);
    });

    test('trial subscription should be active', () {
      final sub = UserSubscription(
        plan: SubscriptionPlan.pro,
        status: SubscriptionStatus.trial,
      );
      expect(sub.isActive, true);
    });

    test('expired subscription should not be active', () {
      final sub = UserSubscription(
        plan: SubscriptionPlan.pro,
        status: SubscriptionStatus.expired,
      );
      expect(sub.isActive, false);
    });

    test('cancelled subscription should not be active', () {
      final sub = UserSubscription(
        plan: SubscriptionPlan.pro,
        status: SubscriptionStatus.cancelled,
      );
      expect(sub.isActive, false);
    });

    test('default plan is free + active', () {
      final sub = UserSubscription();

      expect(sub.plan, SubscriptionPlan.free);
      expect(sub.status, SubscriptionStatus.active);
      expect(sub.isActive, true);
    });

    test('fromMap handles null gracefully', () {
      final sub = UserSubscription.fromMap(null);

      expect(sub.plan, SubscriptionPlan.free);
      expect(sub.status, SubscriptionStatus.active);
    });

    test('fromMap handles unknown plan gracefully', () {
      final sub = UserSubscription.fromMap({
        'plan': 'unknown_plan',
        'status': 'unknown_status',
      });

      expect(sub.plan, SubscriptionPlan.free);
      expect(sub.status, SubscriptionStatus.active);
    });

    test('fromMap parses valid plan names', () {
      final sub = UserSubscription.fromMap({'plan': 'pro', 'status': 'trial'});

      expect(sub.plan, SubscriptionPlan.pro);
      expect(sub.status, SubscriptionStatus.trial);
    });

    test('fromMap parses razorpay IDs', () {
      final sub = UserSubscription.fromMap({
        'plan': 'business',
        'status': 'active',
        'razorpayCustomerId': 'cust_123',
        'razorpaySubscriptionId': 'sub_456',
      });

      expect(sub.razorpayCustomerId, 'cust_123');
      expect(sub.razorpaySubscriptionId, 'sub_456');
    });
  });

  group('UserLimits', () {
    test('default limits should be free plan values', () {
      final limits = UserLimits();

      expect(limits.billsThisMonth, 0);
      expect(limits.billsLimit, 50);
      expect(limits.productsCount, 0);
      expect(limits.productsLimit, 100);
      expect(limits.customersCount, 0);
      expect(limits.customersLimit, 10);
      expect(limits.canCreateBill, true);
      expect(limits.canAddProduct, true);
      expect(limits.canAddCustomer, true);
    });

    test('canCreateBill false when at limit', () {
      final limits = UserLimits(billsThisMonth: 50);
      expect(limits.canCreateBill, false);
    });

    test('canCreateBill false when over limit', () {
      final limits = UserLimits(billsThisMonth: 51);
      expect(limits.canCreateBill, false);
    });

    test('canAddProduct false when at limit', () {
      final limits = UserLimits(productsCount: 100);
      expect(limits.canAddProduct, false);
    });

    test('canAddCustomer false when at limit', () {
      final limits = UserLimits(customersCount: 10);
      expect(limits.canAddCustomer, false);
    });

    test('canAddCustomer true when under limit', () {
      final limits = UserLimits(customersCount: 5);
      expect(limits.canAddCustomer, true);
    });

    test('canAddCustomer true for pro plan (unlimited)', () {
      final limits = UserLimits(customersCount: 500, customersLimit: 999999);
      expect(limits.canAddCustomer, true);
    });

    test('billsRemaining returns correct count', () {
      final limits = UserLimits(billsThisMonth: 30);
      expect(limits.billsRemaining, 20);
    });

    test('billsRemaining returns 0 when at limit', () {
      final limits = UserLimits(billsThisMonth: 50);
      expect(limits.billsRemaining, 0);
    });

    test('fromMap handles null', () {
      final limits = UserLimits.fromMap(null);
      expect(limits.billsThisMonth, 0);
      expect(limits.billsLimit, 50);
    });

    test('fromMap roundtrip', () {
      final original = UserLimits(
        billsThisMonth: 25,
        billsLimit: 500,
        productsCount: 50,
        productsLimit: 999999,
        customersCount: 10,
        customersLimit: 999999,
      );

      final map = original.toMap();
      final restored = UserLimits.fromMap(map);

      expect(restored.billsThisMonth, 25);
      expect(restored.billsLimit, 500);
      expect(restored.productsCount, 50);
      expect(restored.productsLimit, 999999);
      expect(restored.customersCount, 10);
      expect(restored.customersLimit, 999999);
    });

    test('pro plan limits', () {
      final limits = UserLimits(billsLimit: 500, productsLimit: 999999);

      expect(limits.canCreateBill, true);
      expect(limits.billsRemaining, 500);
    });
  });

  group('SubscriptionPlan enum', () {
    test('should have all expected values', () {
      expect(SubscriptionPlan.values.length, 3);
      expect(SubscriptionPlan.values, contains(SubscriptionPlan.free));
      expect(SubscriptionPlan.values, contains(SubscriptionPlan.pro));
      expect(SubscriptionPlan.values, contains(SubscriptionPlan.business));
    });
  });

  group('SubscriptionStatus enum', () {
    test('should have all expected values', () {
      expect(SubscriptionStatus.values.length, 4);
      expect(SubscriptionStatus.values, contains(SubscriptionStatus.active));
      expect(SubscriptionStatus.values, contains(SubscriptionStatus.trial));
      expect(SubscriptionStatus.values, contains(SubscriptionStatus.expired));
      expect(SubscriptionStatus.values, contains(SubscriptionStatus.cancelled));
    });
  });
}
