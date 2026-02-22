/// Tests for UserMetricsService — subscription plans, limits, and activity
///
/// Tests pure logic only (no Firebase). Avoids Timestamp-dependent API calls.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/services/user_metrics_service.dart';

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
      expect(limits.canCreateBill, true);
      expect(limits.canAddProduct, true);
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
      );

      final map = original.toMap();
      final restored = UserLimits.fromMap(map);

      expect(restored.billsThisMonth, 25);
      expect(restored.billsLimit, 500);
      expect(restored.productsCount, 50);
      expect(restored.productsLimit, 999999);
      expect(restored.customersCount, 10);
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
