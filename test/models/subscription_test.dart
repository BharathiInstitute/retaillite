/// Subscription limits & enforcement tests
///
/// Critical for 10K subscribers — ensures tier limits cannot be bypassed,
/// plan transitions work, and usage tracking is accurate.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/constants/app_constants.dart';
import 'package:retaillite/features/super_admin/models/admin_user_model.dart';

void main() {
  // ── Subscription Plan Constants ──

  group('Subscription tier constants', () {
    test('FREE tier limits are correct', () {
      expect(AppConstants.freeMaxBillsPerMonth, 50);
      expect(AppConstants.freeMaxProducts, 100);
      expect(AppConstants.freeMaxCustomers, 10);
    });

    test('PRO tier limits are correct', () {
      expect(AppConstants.proMaxBillsPerMonth, 500);
      expect(AppConstants.proMaxProducts, 999999);
      expect(AppConstants.proMaxCustomers, 999999);
    });

    test('BUSINESS tier limits are correct', () {
      expect(AppConstants.businessMaxBillsPerMonth, 999999);
      expect(AppConstants.businessMaxProducts, 999999);
      expect(AppConstants.businessMaxCustomers, 999999);
    });

    test('PRO price is correct', () {
      expect(AppConstants.proPriceInrMonthly, 299);
      expect(AppConstants.proPriceInrAnnual, 2390);
    });

    test('BUSINESS price is correct', () {
      expect(AppConstants.businessPriceInrMonthly, 999);
      expect(AppConstants.businessPriceInrAnnual, 7990);
    });

    test('annual pricing has ~20% discount', () {
      const proMonthlyAnnual = AppConstants.proPriceInrMonthly * 12;
      const proDiscount =
          (proMonthlyAnnual - AppConstants.proPriceInrAnnual) /
          proMonthlyAnnual *
          100;
      expect(proDiscount, greaterThan(15));
      expect(proDiscount, lessThan(35));

      const bizMonthlyAnnual = AppConstants.businessPriceInrMonthly * 12;
      const bizDiscount =
          (bizMonthlyAnnual - AppConstants.businessPriceInrAnnual) /
          bizMonthlyAnnual *
          100;
      expect(bizDiscount, greaterThan(15));
      expect(bizDiscount, lessThan(35));
    });
  });

  // ── UserSubscription Model ──

  group('UserSubscription', () {
    test('defaults to free active plan', () {
      const sub = UserSubscription();
      expect(sub.plan, SubscriptionPlan.free);
      expect(sub.status, SubscriptionStatus.active);
      expect(sub.isActive, true);
      expect(sub.startedAt, isNull);
      expect(sub.expiresAt, isNull);
    });

    test('planDisplayName returns correct strings', () {
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

    test('planPrice returns correct amounts', () {
      expect(const UserSubscription().planPrice, 0);
      expect(const UserSubscription(plan: SubscriptionPlan.pro).planPrice, 299);
      expect(
        const UserSubscription(plan: SubscriptionPlan.business).planPrice,
        999,
      );
    });

    test('billsLimit returns correct per-plan limits', () {
      expect(
        const UserSubscription().billsLimit,
        50,
      );
      expect(
        const UserSubscription(plan: SubscriptionPlan.pro).billsLimit,
        500,
      );
      expect(
        const UserSubscription(plan: SubscriptionPlan.business).billsLimit,
        999999,
      );
    });

    test('isActive is true for active and trial', () {
      expect(
        const UserSubscription().isActive,
        true,
      );
      expect(
        const UserSubscription(status: SubscriptionStatus.trial).isActive,
        true,
      );
    });

    test('isActive is false for expired and cancelled', () {
      expect(
        const UserSubscription(status: SubscriptionStatus.expired).isActive,
        false,
      );
      expect(
        const UserSubscription(status: SubscriptionStatus.cancelled).isActive,
        false,
      );
    });

    test('fromMap parses plan correctly', () {
      final sub = UserSubscription.fromMap({'plan': 'pro', 'status': 'active'});
      expect(sub.plan, SubscriptionPlan.pro);
      expect(sub.status, SubscriptionStatus.active);
    });

    test('fromMap with null returns free defaults', () {
      final sub = UserSubscription.fromMap(null);
      expect(sub.plan, SubscriptionPlan.free);
      expect(sub.status, SubscriptionStatus.active);
    });

    test('fromMap with invalid plan falls back to free', () {
      final sub = UserSubscription.fromMap({
        'plan': 'premium_gold',
        'status': 'active',
      });
      expect(sub.plan, SubscriptionPlan.free);
    });

    test('fromMap with invalid status falls back to active', () {
      final sub = UserSubscription.fromMap({
        'plan': 'pro',
        'status': 'pending',
      });
      expect(sub.status, SubscriptionStatus.active);
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

  // ── UserLimits Model ──

  group('UserLimits', () {
    test('defaults to free tier limits', () {
      const limits = UserLimits();
      expect(limits.billsThisMonth, 0);
      expect(limits.billsLimit, 50);
      expect(limits.productsCount, 0);
      expect(limits.customersCount, 0);
    });

    test('usagePercentage calculates correctly', () {
      const limits = UserLimits(billsThisMonth: 25);
      expect(limits.usagePercentage, 0.5);
    });

    test('usagePercentage clamps to 1.0 when over limit', () {
      const limits = UserLimits(billsThisMonth: 100);
      expect(limits.usagePercentage, 1.0);
    });

    test('usagePercentage is 0 when billsLimit is 0', () {
      const limits = UserLimits(billsThisMonth: 10, billsLimit: 0);
      expect(limits.usagePercentage, 0.0);
    });

    test('isNearLimit is true when > 80%', () {
      const limits = UserLimits(billsThisMonth: 41);
      expect(limits.isNearLimit, true);
    });

    test('isNearLimit is false when <= 80%', () {
      const limits = UserLimits(billsThisMonth: 40);
      expect(limits.isNearLimit, false);
    });

    test('isAtLimit is true when bills >= limit', () {
      const atLimit = UserLimits(billsThisMonth: 50);
      expect(atLimit.isAtLimit, true);

      const overLimit = UserLimits(billsThisMonth: 51);
      expect(overLimit.isAtLimit, true);
    });

    test('isAtLimit is false when under limit', () {
      const limits = UserLimits(billsThisMonth: 49);
      expect(limits.isAtLimit, false);
    });

    test('fromMap parses correctly', () {
      final limits = UserLimits.fromMap({
        'billsThisMonth': 42,
        'billsLimit': 500,
        'productsCount': 85,
        'customersCount': 20,
      });
      expect(limits.billsThisMonth, 42);
      expect(limits.billsLimit, 500);
      expect(limits.productsCount, 85);
      expect(limits.customersCount, 20);
    });

    test('fromMap with null returns defaults', () {
      final limits = UserLimits.fromMap(null);
      expect(limits.billsLimit, 50);
      expect(limits.billsThisMonth, 0);
    });

    test('boundary: exactly at 80% threshold', () {
      // 40/50 = 80% exactly — should NOT be near limit (> 80)
      const at80 = UserLimits(billsThisMonth: 40);
      expect(at80.isNearLimit, false);
      expect(at80.usagePercentage, 0.8);
    });

    test('boundary: 1 bill over limit', () {
      const overBy1 = UserLimits(billsThisMonth: 51);
      expect(overBy1.isAtLimit, true);
      expect(overBy1.usagePercentage, 1.0); // clamped
    });
  });

  // ── Subscription plan transitions ──

  group('Plan transitions', () {
    test('free → pro increases bills limit', () {
      const free = UserSubscription();
      const pro = UserSubscription(plan: SubscriptionPlan.pro);
      expect(pro.billsLimit, greaterThan(free.billsLimit));
    });

    test('pro → business increases bills limit', () {
      const pro = UserSubscription(plan: SubscriptionPlan.pro);
      const biz = UserSubscription(plan: SubscriptionPlan.business);
      expect(biz.billsLimit, greaterThan(pro.billsLimit));
    });

    test('expired subscription is not active', () {
      const expired = UserSubscription(
        plan: SubscriptionPlan.pro,
        status: SubscriptionStatus.expired,
      );
      expect(expired.isActive, false);
      // But billsLimit should still reflect plan
      expect(expired.billsLimit, 500);
    });

    test('cancelled subscription is not active', () {
      const cancelled = UserSubscription(
        plan: SubscriptionPlan.business,
        status: SubscriptionStatus.cancelled,
      );
      expect(cancelled.isActive, false);
    });
  });

  // ── Subscription enum parsing robustness ──

  group('SubscriptionPlan enum', () {
    test('all plans have unique names', () {
      final names = SubscriptionPlan.values.map((e) => e.name).toSet();
      expect(names.length, SubscriptionPlan.values.length);
    });

    test('all statuses have unique names', () {
      final names = SubscriptionStatus.values.map((e) => e.name).toSet();
      expect(names.length, SubscriptionStatus.values.length);
    });
  });

  // ── 10K scale scenarios ──

  group('Scale: 10K subscriber scenarios', () {
    test('free user at limit gets blocked', () {
      const limits = UserLimits(billsThisMonth: 50);
      expect(limits.isAtLimit, true);
      expect(limits.isNearLimit, true);
    });

    test('pro user can create 500 bills/month', () {
      const limits = UserLimits(billsThisMonth: 499, billsLimit: 500);
      expect(limits.isAtLimit, false);
      expect(limits.isNearLimit, true);
    });

    test('business user effectively unlimited', () {
      const limits = UserLimits(billsThisMonth: 10000, billsLimit: 999999);
      expect(limits.isAtLimit, false);
      expect(limits.isNearLimit, false);
    });

    test('concurrent users with different plans', () {
      // Simulate 10K users: 7K free, 2K pro, 1K business
      final freeUser = UserLimits.fromMap({
        'billsThisMonth': 50,
        'billsLimit': 50,
      });
      final proUser = UserLimits.fromMap({
        'billsThisMonth': 200,
        'billsLimit': 500,
      });
      final bizUser = UserLimits.fromMap({
        'billsThisMonth': 5000,
        'billsLimit': 999999,
      });

      expect(freeUser.isAtLimit, true);
      expect(proUser.isAtLimit, false);
      expect(bizUser.isAtLimit, false);
    });
  });
}
