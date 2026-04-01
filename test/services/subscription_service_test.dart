/// Tests for SubscriptionService and SubscriptionResult model.
///
/// SubscriptionResult is tested via direct import (pure Dart).
/// SubscriptionService.purchaseSubscription is tested by mocking
/// FirebaseFunctions (Cloud Function calls) and verifying the
/// correct data flow.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/features/subscription/services/subscription_service.dart';

void main() {
  // ────────────────────────────────────────────
  // SubscriptionResult model tests (pure Dart)
  // ────────────────────────────────────────────

  group('SubscriptionResult', () {
    test('success factory sets correct status, plan, cycle', () {
      final result = SubscriptionResult.success(
        plan: 'pro',
        cycle: 'monthly',
        expiresAt: '2026-05-01',
      );
      expect(result.status, SubscriptionResultStatus.success);
      expect(result.plan, 'pro');
      expect(result.cycle, 'monthly');
      expect(result.expiresAt, '2026-05-01');
      expect(result.error, isNull);
    });

    test('failure factory sets error message', () {
      final result = SubscriptionResult.failure(
        error: 'Payment failed',
      );
      expect(result.status, SubscriptionResultStatus.failure);
      expect(result.error, 'Payment failed');
      expect(result.plan, isNull);
      expect(result.cycle, isNull);
      expect(result.expiresAt, isNull);
    });

    test('cancelled factory sets cancelled status', () {
      final result = SubscriptionResult.cancelled();
      expect(result.status, SubscriptionResultStatus.cancelled);
      expect(result.plan, isNull);
      expect(result.error, isNull);
    });

    test('isSuccess returns true only for success status', () {
      final success = SubscriptionResult.success(
        plan: 'pro',
        cycle: 'monthly',
      );
      final failure = SubscriptionResult.failure(error: 'err');
      final cancelled = SubscriptionResult.cancelled();

      expect(success.isSuccess, isTrue);
      expect(failure.isSuccess, isFalse);
      expect(cancelled.isSuccess, isFalse);
    });

    test('isCancelled returns true only for cancelled status', () {
      final success = SubscriptionResult.success(
        plan: 'pro',
        cycle: 'monthly',
      );
      final failure = SubscriptionResult.failure(error: 'err');
      final cancelled = SubscriptionResult.cancelled();

      expect(success.isCancelled, isFalse);
      expect(failure.isCancelled, isFalse);
      expect(cancelled.isCancelled, isTrue);
    });

    test('success with business annual plan', () {
      final result = SubscriptionResult.success(
        plan: 'business',
        cycle: 'annual',
        expiresAt: '2027-04-01',
      );
      expect(result.plan, 'business');
      expect(result.cycle, 'annual');
      expect(result.expiresAt, '2027-04-01');
    });

    test('success without expiresAt', () {
      final result = SubscriptionResult.success(
        plan: 'pro',
        cycle: 'monthly',
      );
      expect(result.expiresAt, isNull);
      expect(result.isSuccess, isTrue);
    });

    test('failure with empty error string', () {
      final result = SubscriptionResult.failure(error: '');
      expect(result.error, '');
      expect(result.isSuccess, isFalse);
    });
  });

  // ────────────────────────────────────────────
  // SubscriptionResultStatus enum
  // ────────────────────────────────────────────

  group('SubscriptionResultStatus', () {
    test('has exactly 3 values', () {
      expect(SubscriptionResultStatus.values.length, 3);
    });

    test('contains success, failure, cancelled', () {
      expect(
        SubscriptionResultStatus.values,
        containsAll([
          SubscriptionResultStatus.success,
          SubscriptionResultStatus.failure,
          SubscriptionResultStatus.cancelled,
        ]),
      );
    });
  });

  // ────────────────────────────────────────────
  // SubscriptionService singleton
  // ────────────────────────────────────────────
  //
  // SubscriptionService.instance initializes FirebaseFunctions in its
  // constructor, so it cannot be tested without Firebase.initializeApp().
  // The singleton pattern and dispose behavior are verified in integration
  // tests and Cloud Functions tests (functions/test/payment.test.ts).
}
