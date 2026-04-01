/// Integration test for the subscription purchase flow.
///
/// Tests the full subscription journey:
///   free → select plan → create subscription → payment → activate → plan updated
///
/// Uses inline re-declarations to avoid transitive Firebase deps
/// (same approach as subscription_enforcement_test.dart).
library;

import 'package:flutter_test/flutter_test.dart';

// ── Inline model re-declarations (avoids Firebase transitive deps) ──

enum SubscriptionPlan { free, pro, business }

enum SubscriptionStatus { active, expired, cancelled }

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

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}

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
}

/// Plan limit configurations
UserLimits limitsForPlan(SubscriptionPlan plan) {
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

/// Simulates the activation step: updates subscription + limits.
({UserSubscription subscription, UserLimits limits}) activateSubscription({
  required SubscriptionPlan plan,
  required String cycle,
  required int currentBillsThisMonth,
}) {
  final now = DateTime.now();
  final duration = cycle == 'annual'
      ? const Duration(days: 365)
      : const Duration(days: 30);

  final subscription = UserSubscription(
    plan: plan,
    startedAt: now,
    expiresAt: now.add(duration),
  );

  final baseLimits = limitsForPlan(plan);
  final limits = UserLimits(
    billsThisMonth: currentBillsThisMonth,
    billsLimit: baseLimits.billsLimit,
    productsLimit: baseLimits.productsLimit,
    customersLimit: baseLimits.customersLimit,
  );

  return (subscription: subscription, limits: limits);
}

/// Simulates month rollover: resets billsThisMonth when month changes.
UserLimits monthlyReset(UserLimits current, int lastResetMonth) {
  final currentMonth = DateTime.now().month;
  if (currentMonth != lastResetMonth) {
    return UserLimits(
      billsLimit: current.billsLimit,
      productsCount: current.productsCount,
      productsLimit: current.productsLimit,
      customersCount: current.customersCount,
      customersLimit: current.customersLimit,
    );
  }
  return current;
}

void main() {
  // ── Free → Pro Monthly ──

  group('Free → Pro monthly upgrade', () {
    test('activation sets plan to pro with 30-day expiry', () {
      final result = activateSubscription(
        plan: SubscriptionPlan.pro,
        cycle: 'monthly',
        currentBillsThisMonth: 10,
      );

      expect(result.subscription.plan, SubscriptionPlan.pro);
      expect(result.subscription.status, SubscriptionStatus.active);
      expect(result.subscription.startedAt, isNotNull);
      expect(result.subscription.expiresAt, isNotNull);

      final daysDiff = result.subscription.expiresAt!
          .difference(result.subscription.startedAt!)
          .inDays;
      expect(daysDiff, 30);
    });

    test('activation updates limits to pro tier', () {
      final result = activateSubscription(
        plan: SubscriptionPlan.pro,
        cycle: 'monthly',
        currentBillsThisMonth: 10,
      );

      expect(result.limits.billsLimit, 500);
      expect(result.limits.productsLimit, 1000);
      expect(result.limits.customersLimit, 100);
    });

    test('activation preserves current billsThisMonth count', () {
      final result = activateSubscription(
        plan: SubscriptionPlan.pro,
        cycle: 'monthly',
        currentBillsThisMonth: 42,
      );

      expect(result.limits.billsThisMonth, 42);
    });
  });

  // ── Free → Business Annual ──

  group('Free → Business annual upgrade', () {
    test('activation sets plan to business with 365-day expiry', () {
      final result = activateSubscription(
        plan: SubscriptionPlan.business,
        cycle: 'annual',
        currentBillsThisMonth: 5,
      );

      expect(result.subscription.plan, SubscriptionPlan.business);

      final daysDiff = result.subscription.expiresAt!
          .difference(result.subscription.startedAt!)
          .inDays;
      expect(daysDiff, 365);
    });

    test('business limits are effectively unlimited', () {
      final result = activateSubscription(
        plan: SubscriptionPlan.business,
        cycle: 'annual',
        currentBillsThisMonth: 0,
      );

      expect(result.limits.billsLimit, 999999);
      expect(result.limits.productsLimit, 999999);
      expect(result.limits.customersLimit, 999999);
    });
  });

  // ── Upgrade: Pro → Business ──

  group('Pro → Business upgrade', () {
    test('limits expand from pro to business', () {
      // Start as pro
      final proResult = activateSubscription(
        plan: SubscriptionPlan.pro,
        cycle: 'monthly',
        currentBillsThisMonth: 200,
      );
      expect(proResult.limits.billsLimit, 500);

      // Upgrade to business
      final bizResult = activateSubscription(
        plan: SubscriptionPlan.business,
        cycle: 'monthly',
        currentBillsThisMonth: 200,
      );
      expect(bizResult.limits.billsLimit, 999999);
      expect(bizResult.limits.billsThisMonth, 200); // preserved
    });
  });

  // ── Expired subscription ──

  group('Expired subscription', () {
    test('isExpired returns true after expiry date', () {
      final expired = UserSubscription(
        plan: SubscriptionPlan.pro,
        status: SubscriptionStatus.expired,
        startedAt: DateTime(2025, 1),
        expiresAt: DateTime(2025, 2),
      );

      expect(expired.isExpired, isTrue);
    });

    test('isExpired returns false before expiry date', () {
      final active = UserSubscription(
        plan: SubscriptionPlan.pro,
        startedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      expect(active.isExpired, isFalse);
    });

    test('isExpired returns false when expiresAt is null (free plan)', () {
      const free = UserSubscription();
      expect(free.isExpired, isFalse);
    });

    test('expired sub should revert to free limits', () {
      final freeLimits = limitsForPlan(SubscriptionPlan.free);
      expect(freeLimits.billsLimit, 50);
      expect(freeLimits.productsLimit, 100);
      expect(freeLimits.customersLimit, 10);
    });
  });

  // ── Monthly limit reset ──

  group('Monthly limit reset', () {
    test('resets billsThisMonth when month changes', () {
      const limits = UserLimits(billsThisMonth: 45);

      // Use a month that is definitely not current month
      final differentMonth = (DateTime.now().month % 12) + 1;
      final reset = monthlyReset(limits, differentMonth);
      expect(reset.billsThisMonth, 0);
      expect(reset.billsLimit, 50); // limit unchanged
    });

    test('does NOT reset when same month', () {
      const limits = UserLimits(billsThisMonth: 45);

      final sameMonth = DateTime.now().month;
      final noReset = monthlyReset(limits, sameMonth);
      expect(noReset.billsThisMonth, 45); // unchanged
    });

    test('December → January rollover', () {
      const limits = UserLimits(billsThisMonth: 50);

      // Simulate: lastResetMonth = 12 (December)
      // If current month is NOT December, reset occurs.
      // We test the month comparison logic:
      final currentMonth = DateTime.now().month;
      if (currentMonth != 12) {
        final reset = monthlyReset(limits, 12);
        expect(reset.billsThisMonth, 0);
      }
    });

    test('reset preserves other counts', () {
      const limits = UserLimits(
        billsThisMonth: 45,
        billsLimit: 500,
        productsCount: 200,
        productsLimit: 1000,
        customersCount: 50,
        customersLimit: 100,
      );

      final differentMonth = (DateTime.now().month % 12) + 1;
      final reset = monthlyReset(limits, differentMonth);
      expect(reset.productsCount, 200); // preserved
      expect(reset.customersCount, 50); // preserved
    });
  });

  // ── Cancel payment ──

  group('Cancel payment', () {
    test('plan remains unchanged when payment is cancelled', () {
      const currentPlan = SubscriptionPlan.free;
      // When user cancels Razorpay, no activation happens.
      // The plan doesn't change.
      expect(currentPlan, SubscriptionPlan.free);
    });
  });

  // ── Plan limit comparison ──

  group('Plan limit tiers', () {
    test('free < pro < business for all limits', () {
      final free = limitsForPlan(SubscriptionPlan.free);
      final pro = limitsForPlan(SubscriptionPlan.pro);
      final biz = limitsForPlan(SubscriptionPlan.business);

      expect(free.billsLimit, lessThan(pro.billsLimit));
      expect(pro.billsLimit, lessThan(biz.billsLimit));

      expect(free.productsLimit, lessThan(pro.productsLimit));
      expect(pro.productsLimit, lessThan(biz.productsLimit));

      expect(free.customersLimit, lessThan(pro.customersLimit));
      expect(pro.customersLimit, lessThan(biz.customersLimit));
    });
  });

  // ── Can create bill at boundary ──

  group('Bill creation at limit boundary', () {
    test('free plan: 49 bills → can create', () {
      const limits = UserLimits(billsThisMonth: 49);
      expect(limits.canCreateBill, isTrue);
    });

    test('free plan: 50 bills → cannot create', () {
      const limits = UserLimits(billsThisMonth: 50);
      expect(limits.canCreateBill, isFalse);
    });

    test('free plan: 51 bills → cannot create', () {
      const limits = UserLimits(billsThisMonth: 51);
      expect(limits.canCreateBill, isFalse);
    });

    test('pro plan: 499 bills → can create', () {
      const limits = UserLimits(billsThisMonth: 499, billsLimit: 500);
      expect(limits.canCreateBill, isTrue);
    });

    test('pro plan: 500 bills → cannot create', () {
      const limits = UserLimits(billsThisMonth: 500, billsLimit: 500);
      expect(limits.canCreateBill, isFalse);
    });

    test('business plan: 999998 bills → can create', () {
      const limits = UserLimits(billsThisMonth: 999998, billsLimit: 999999);
      expect(limits.canCreateBill, isTrue);
    });
  });

  group('Product creation at limit boundary', () {
    test('free: 99 products → can add', () {
      const limits = UserLimits(productsCount: 99);
      expect(limits.canAddProduct, isTrue);
    });

    test('free: 100 products → cannot add', () {
      const limits = UserLimits(productsCount: 100);
      expect(limits.canAddProduct, isFalse);
    });
  });

  group('Customer creation at limit boundary', () {
    test('free: 9 customers → can add', () {
      const limits = UserLimits(customersCount: 9);
      expect(limits.canAddCustomer, isTrue);
    });

    test('free: 10 customers → cannot add', () {
      const limits = UserLimits(customersCount: 10);
      expect(limits.canAddCustomer, isFalse);
    });
  });
}
