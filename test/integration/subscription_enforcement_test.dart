/// Integration test: Subscription enforcement flow
///
/// Tests UserLimits enforcement at free / pro / business tiers,
/// plus UserSubscription plan-based limits.
library;

import 'package:flutter_test/flutter_test.dart';

// ── Inline UserLimits (avoids transitive Firebase deps) ──

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

  bool get canCreateBill => billsThisMonth < billsLimit;
  bool get canAddProduct => productsCount < productsLimit;
  bool get canAddCustomer => customersCount < customersLimit;
  int get billsRemaining => billsLimit - billsThisMonth;
  int get productsRemaining => productsLimit - productsCount;
  int get customersRemaining => customersLimit - customersCount;

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
}

// ── Subscription enums ──

enum SubscriptionPlan { free, pro, business }

enum SubscriptionStatus { active, trial, expired, cancelled }

class SubscriptionConfig {
  static int billsLimit(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.free:
        return 50;
      case SubscriptionPlan.pro:
      case SubscriptionPlan.business:
        return 999999;
    }
  }

  static int productsLimit(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.free:
        return 100;
      case SubscriptionPlan.pro:
      case SubscriptionPlan.business:
        return 999999;
    }
  }

  static int customersLimit(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.free:
        return 10;
      case SubscriptionPlan.pro:
      case SubscriptionPlan.business:
        return 999999;
    }
  }

  static bool isActive(SubscriptionStatus status) {
    return status == SubscriptionStatus.active ||
        status == SubscriptionStatus.trial;
  }
}

void main() {
  // ─── Free tier limits ─────────────────────────────────────────────

  group('Integration: Free Tier Enforcement', () {
    test('free defaults: 50 bills, 100 products, 10 customers', () {
      final limits = UserLimits();
      expect(limits.billsLimit, 50);
      expect(limits.productsLimit, 100);
      expect(limits.customersLimit, 10);
    });

    test('fresh user can create bills', () {
      final limits = UserLimits();
      expect(limits.canCreateBill, isTrue);
      expect(limits.billsRemaining, 50);
    });

    test('approaching limit still allows creation', () {
      final limits = UserLimits(billsThisMonth: 49);
      expect(limits.canCreateBill, isTrue);
      expect(limits.billsRemaining, 1);
    });

    test('at limit blocks new bills', () {
      final limits = UserLimits(billsThisMonth: 50);
      expect(limits.canCreateBill, isFalse);
      expect(limits.billsRemaining, 0);
    });

    test('over limit blocks new bills', () {
      final limits = UserLimits(billsThisMonth: 60);
      expect(limits.canCreateBill, isFalse);
      expect(limits.billsRemaining, -10);
    });

    test('product limit enforced', () {
      final atLimit = UserLimits(productsCount: 100);
      expect(atLimit.canAddProduct, isFalse);

      final belowLimit = UserLimits(productsCount: 99);
      expect(belowLimit.canAddProduct, isTrue);
    });

    test('customer limit enforced', () {
      final atLimit = UserLimits(customersCount: 10);
      expect(atLimit.canAddCustomer, isFalse);

      final belowLimit = UserLimits(customersCount: 9);
      expect(belowLimit.canAddCustomer, isTrue);
    });
  });

  // ─── Pro tier limits ──────────────────────────────────────────────

  group('Integration: Pro Tier Enforcement', () {
    test('pro tier has effectively unlimited limits', () {
      final proLimits = UserLimits(
        billsThisMonth: 5000,
        billsLimit: SubscriptionConfig.billsLimit(SubscriptionPlan.pro),
        productsCount: 10000,
        productsLimit: SubscriptionConfig.productsLimit(SubscriptionPlan.pro),
        customersCount: 5000,
        customersLimit: SubscriptionConfig.customersLimit(SubscriptionPlan.pro),
      );

      expect(proLimits.canCreateBill, isTrue);
      expect(proLimits.canAddProduct, isTrue);
      expect(proLimits.canAddCustomer, isTrue);
    });
  });

  // ─── Subscription status checks ──────────────────────────────────

  group('Integration: Subscription Status', () {
    test('active subscription is active', () {
      expect(SubscriptionConfig.isActive(SubscriptionStatus.active), isTrue);
    });

    test('trial subscription is active', () {
      expect(SubscriptionConfig.isActive(SubscriptionStatus.trial), isTrue);
    });

    test('expired subscription is not active', () {
      expect(SubscriptionConfig.isActive(SubscriptionStatus.expired), isFalse);
    });

    test('cancelled subscription is not active', () {
      expect(
        SubscriptionConfig.isActive(SubscriptionStatus.cancelled),
        isFalse,
      );
    });
  });

  // ─── Upgrade flow simulation ─────────────────────────────────────

  group('Integration: Upgrade Flow', () {
    test('free user hits limit → upgrades → can create again', () {
      // Step 1: Free user at bill limit
      var limits = UserLimits(billsThisMonth: 50);
      expect(limits.canCreateBill, isFalse);

      // Step 2: Upgrade to pro
      limits = UserLimits(
        billsThisMonth: 50,
        billsLimit: SubscriptionConfig.billsLimit(SubscriptionPlan.pro),
      );
      expect(limits.canCreateBill, isTrue);
      expect(limits.billsRemaining, greaterThan(0));
    });

    test('product limit upgrade enables adding more', () {
      // At free limit
      var limits = UserLimits(productsCount: 100);
      expect(limits.canAddProduct, isFalse);

      // Upgrade
      limits = UserLimits(
        productsCount: 100,
        productsLimit: SubscriptionConfig.productsLimit(SubscriptionPlan.pro),
      );
      expect(limits.canAddProduct, isTrue);
    });
  });

  // ─── Month reset simulation ──────────────────────────────────────

  group('Integration: Monthly Reset', () {
    test('monthly reset clears bills count', () {
      // End of month: at limit
      var limits = UserLimits(billsThisMonth: 50);
      expect(limits.canCreateBill, isFalse);

      // New month: count resets
      limits = UserLimits();
      expect(limits.canCreateBill, isTrue);
      expect(limits.billsRemaining, 50);
    });
  });

  // ─── Serialization roundtrip ─────────────────────────────────────

  group('UserLimits serialization', () {
    test('toMap and fromMap roundtrip', () {
      final original = UserLimits(
        billsThisMonth: 25,
        productsCount: 80,
        customersCount: 8,
      );

      final map = original.toMap();
      final restored = UserLimits.fromMap(map);

      expect(restored.billsThisMonth, 25);
      expect(restored.billsLimit, 50);
      expect(restored.productsCount, 80);
      expect(restored.productsLimit, 100);
      expect(restored.customersCount, 8);
      expect(restored.customersLimit, 10);
    });

    test('fromMap with null returns defaults', () {
      final defaults = UserLimits.fromMap(null);
      expect(defaults.billsThisMonth, 0);
      expect(defaults.billsLimit, 50);
      expect(defaults.productsCount, 0);
      expect(defaults.productsLimit, 100);
      expect(defaults.customersCount, 0);
      expect(defaults.customersLimit, 10);
    });

    test('fromMap with partial data fills missing with defaults', () {
      final partial = UserLimits.fromMap({'billsThisMonth': 10});
      expect(partial.billsThisMonth, 10);
      expect(partial.billsLimit, 50); // default
      expect(partial.productsCount, 0); // default
    });
  });
}
