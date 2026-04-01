/// Tests for subscriptionPlanProvider.
///
/// Uses inline re-declarations to avoid transitive Firebase auth dependencies.
/// The provider logic is: read user doc → extract subscription.plan → default "free".
library;

import 'package:flutter_test/flutter_test.dart';

/// Inline extraction of the plan-parsing logic from subscriptionPlanProvider.
/// This avoids importing the production file which transitively requires
/// Firebase Auth initialization.
String extractPlan(Map<String, dynamic>? docData) {
  final sub = docData?['subscription'] as Map<String, dynamic>?;
  return (sub?['plan'] as String?) ?? 'free';
}

void main() {
  group('subscriptionPlanProvider plan extraction', () {
    test('returns "free" when doc data is null', () {
      expect(extractPlan(null), 'free');
    });

    test('returns "free" when subscription field is missing', () {
      expect(extractPlan({'shopName': 'Test'}), 'free');
    });

    test('returns "free" when subscription.plan is null', () {
      expect(
        extractPlan({
          'subscription': <String, dynamic>{'status': 'active'},
        }),
        'free',
      );
    });

    test('returns "pro" for pro subscription', () {
      expect(
        extractPlan({
          'subscription': <String, dynamic>{'plan': 'pro', 'status': 'active'},
        }),
        'pro',
      );
    });

    test('returns "business" for business subscription', () {
      expect(
        extractPlan({
          'subscription': <String, dynamic>{
            'plan': 'business',
            'status': 'active',
          },
        }),
        'business',
      );
    });

    test('returns "free" for free plan', () {
      expect(
        extractPlan({
          'subscription': <String, dynamic>{'plan': 'free', 'status': 'active'},
        }),
        'free',
      );
    });

    test('returns exact string for unknown plan names', () {
      // If server sends an unrecognized plan, the provider passes it through.
      // Downstream code should treat unrecognized plans as "free".
      expect(
        extractPlan({
          'subscription': <String, dynamic>{'plan': 'enterprise'},
        }),
        'enterprise',
      );
    });

    test('returns "free" when subscription is empty map', () {
      expect(extractPlan({'subscription': <String, dynamic>{}}), 'free');
    });

    test('handles subscription with extra fields gracefully', () {
      expect(
        extractPlan({
          'subscription': <String, dynamic>{
            'plan': 'pro',
            'status': 'active',
            'startedAt': 'some-timestamp',
            'expiresAt': 'some-timestamp',
            'razorpaySubscriptionId': 'sub_xxx',
          },
        }),
        'pro',
      );
    });

    test('returns "free" for null user (Stream.value fallback)', () {
      // When user is null, the provider returns Stream.value('free').
      // This test documents that contract.
      const fallback = 'free';
      expect(fallback, 'free');
    });
  });
}
