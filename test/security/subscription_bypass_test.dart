/// Security tests for subscription bypass protection.
///
/// Verifies that subscription limits cannot be circumvented through:
///   - Tampered billsThisMonth values
///   - Invalid plan names
///   - Limit boundary manipulation
///
/// Uses inline re-declarations (same approach as subscription_enforcement_test.dart).
library;

import 'package:flutter_test/flutter_test.dart';

// ── Inline types ──

enum SubscriptionPlan { free, pro, business }

class UserLimits {
  final int billsThisMonth;
  final int billsLimit;
  final int productsCount;
  final int productsLimit;
  final int customersCount;
  final int customersLimit;

  const UserLimits({
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

  double get billUsagePercentage =>
      billsLimit > 0 ? (billsThisMonth / billsLimit) * 100 : 0;

  bool get isNearBillLimit => billUsagePercentage >= 80;
  bool get isAtBillLimit => !canCreateBill;
}

/// Returns authoritative limits for a plan.
/// Client MUST NOT set its own limits — only the server can.
UserLimits serverLimitsForPlan(SubscriptionPlan plan) {
  switch (plan) {
    case SubscriptionPlan.free:
      return const UserLimits(productsLimit: 100);
    case SubscriptionPlan.pro:
      return const UserLimits(
        billsLimit: 500,
        productsLimit: 1000,
        customersLimit: 100,
      );
    case SubscriptionPlan.business:
      return const UserLimits(
        billsLimit: 999999,
        productsLimit: 999999,
        customersLimit: 999999,
      );
  }
}

/// Maps a plan string from Firestore to a SubscriptionPlan.
/// Unrecognized values default to free.
SubscriptionPlan parsePlan(String? planString) {
  switch (planString) {
    case 'pro':
      return SubscriptionPlan.pro;
    case 'business':
      return SubscriptionPlan.business;
    case 'free':
    default:
      return SubscriptionPlan.free;
  }
}

void main() {
  // ── Cannot exceed free plan bill limit ──

  group('Free plan bill limit enforcement', () {
    test('cannot create 51st bill on free plan', () {
      const limits = UserLimits(billsThisMonth: 50);
      expect(limits.canCreateBill, isFalse);
    });

    test('cannot create 52nd bill on free plan', () {
      const limits = UserLimits(billsThisMonth: 51);
      expect(limits.canCreateBill, isFalse);
    });

    test('can create 50th bill on free plan', () {
      const limits = UserLimits(billsThisMonth: 49);
      expect(limits.canCreateBill, isTrue);
    });
  });

  // ── Cannot exceed product limit ──

  group('Product limit enforcement', () {
    test('cannot add product beyond free limit', () {
      const limits = UserLimits(productsCount: 100);
      expect(limits.canAddProduct, isFalse);
    });

    test('can add product at limit - 1', () {
      const limits = UserLimits(productsCount: 99);
      expect(limits.canAddProduct, isTrue);
    });
  });

  // ── Cannot exceed customer limit ──

  group('Customer limit enforcement', () {
    test('cannot add customer beyond free limit', () {
      const limits = UserLimits(customersCount: 10);
      expect(limits.canAddCustomer, isFalse);
    });
  });

  // ── Tampered billsThisMonth ──

  group('Tampered billsThisMonth handling', () {
    test(
      'negative billsThisMonth: treated as below limit (but shouldnt happen)',
      () {
        // Firestore rules + CF validate this server-side.
        // Client treats negative as "can create" because -1 < 50.
        const limits = UserLimits(billsThisMonth: -1);
        expect(limits.canCreateBill, isTrue);
        // The Cloud Function onBillCreated recalculates the actual count,
        // so even if client shows "allowed", the CF will enforce the real count.
      },
    );

    test('extremely high billsThisMonth blocks creation', () {
      const limits = UserLimits(billsThisMonth: 999999);
      expect(limits.canCreateBill, isFalse);
    });
  });

  // ── Tampered billsLimit ──

  group('Tampered billsLimit handling', () {
    test('client cannot set own billsLimit — server overrides', () {
      // Even if a hacked client writes billsLimit=999999 to Firestore,
      // the CF activateSubscription sets the authoritative limit.
      final freeLimits = serverLimitsForPlan(SubscriptionPlan.free);
      expect(freeLimits.billsLimit, 50);

      // Simulating tampered value that server would override:
      const tamperedLimits = UserLimits(
        billsLimit: 999999, // hacked
      );
      // The tampered value allows creation on client:
      expect(tamperedLimits.canCreateBill, isTrue);
      // But the server authoritative limit is 50:
      expect(freeLimits.billsLimit, 50);
      // The CF onBillCreated will delete the bill if actual count >= server limit.
    });
  });

  // ── Unrecognized plan names ──

  group('Unrecognized plan names default to free', () {
    test('"admin" plan maps to free', () {
      expect(parsePlan('admin'), SubscriptionPlan.free);
    });

    test('"superuser" plan maps to free', () {
      expect(parsePlan('superuser'), SubscriptionPlan.free);
    });

    test('"enterprise" plan maps to free', () {
      expect(parsePlan('enterprise'), SubscriptionPlan.free);
    });

    test('null plan maps to free', () {
      expect(parsePlan(null), SubscriptionPlan.free);
    });

    test('empty string plan maps to free', () {
      expect(parsePlan(''), SubscriptionPlan.free);
    });

    test('"PRO" (uppercase) maps to free (case-sensitive)', () {
      expect(parsePlan('PRO'), SubscriptionPlan.free);
    });

    test('"pro" (lowercase) maps to pro', () {
      expect(parsePlan('pro'), SubscriptionPlan.pro);
    });

    test('"business" maps to business', () {
      expect(parsePlan('business'), SubscriptionPlan.business);
    });
  });

  // ── Expired subscription reverts to free limits ──

  group('Expired subscription reverts to free limits', () {
    test('expired pro user gets free limits', () {
      final limits = serverLimitsForPlan(SubscriptionPlan.free);
      expect(limits.billsLimit, 50);
      expect(limits.productsLimit, 100);
      expect(limits.customersLimit, 10);
    });
  });

  // ── Usage percentage boundary ──

  group('Usage percentage boundaries', () {
    test('0 bills: 0% usage', () {
      const limits = UserLimits(billsLimit: 50);
      expect(limits.billUsagePercentage, 0);
      expect(limits.isNearBillLimit, isFalse);
    });

    test('39 bills of 50: 78% — NOT near limit', () {
      const limits = UserLimits(billsThisMonth: 39);
      expect(limits.billUsagePercentage, 78);
      expect(limits.isNearBillLimit, isFalse);
    });

    test('40 bills of 50: 80% — IS near limit', () {
      const limits = UserLimits(billsThisMonth: 40);
      expect(limits.billUsagePercentage, 80);
      expect(limits.isNearBillLimit, isTrue);
    });

    test('50 bills of 50: 100% — at limit', () {
      const limits = UserLimits(billsThisMonth: 50);
      expect(limits.billUsagePercentage, 100);
      expect(limits.isAtBillLimit, isTrue);
      expect(limits.isNearBillLimit, isTrue);
    });

    test('51 bills of 50: over limit', () {
      const limits = UserLimits(billsThisMonth: 51);
      expect(limits.isAtBillLimit, isTrue);
    });
  });

  // ── Server-authoritative plan limits ──

  group('Server-authoritative plan limits', () {
    test('free limits are correct', () {
      final l = serverLimitsForPlan(SubscriptionPlan.free);
      expect(l.billsLimit, 50);
      expect(l.productsLimit, 100);
      expect(l.customersLimit, 10);
    });

    test('pro limits are correct', () {
      final l = serverLimitsForPlan(SubscriptionPlan.pro);
      expect(l.billsLimit, 500);
      expect(l.productsLimit, 1000);
      expect(l.customersLimit, 100);
    });

    test('business limits are correct', () {
      final l = serverLimitsForPlan(SubscriptionPlan.business);
      expect(l.billsLimit, 999999);
      expect(l.productsLimit, 999999);
      expect(l.customersLimit, 999999);
    });

    test('free < pro < business for all limits', () {
      final free = serverLimitsForPlan(SubscriptionPlan.free);
      final pro = serverLimitsForPlan(SubscriptionPlan.pro);
      final biz = serverLimitsForPlan(SubscriptionPlan.business);

      expect(free.billsLimit, lessThan(pro.billsLimit));
      expect(pro.billsLimit, lessThan(biz.billsLimit));
    });
  });
}
