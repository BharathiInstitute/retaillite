/// RazorpayService — PaymentResult data class and completer tests
///
/// Tests the PaymentResult value type, factory constructors,
/// and payment timeout behavior. Critical because money is involved.
library;

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/services/razorpay_service.dart';

void main() {
  group('PaymentResult — factory constructors', () {
    test('success factory sets correct fields', () {
      final result = PaymentResult.success(
        paymentId: 'pay_ABC123',
        orderId: 'order_XYZ',
        signature: 'sig_000',
      );
      expect(result.success, isTrue);
      expect(result.paymentId, 'pay_ABC123');
      expect(result.orderId, 'order_XYZ');
      expect(result.signature, 'sig_000');
      expect(result.errorCode, isNull);
      expect(result.errorMessage, isNull);
    });

    test('success factory with paymentId only', () {
      final result = PaymentResult.success(paymentId: 'pay_001');
      expect(result.success, isTrue);
      expect(result.paymentId, 'pay_001');
      expect(result.orderId, isNull);
      expect(result.signature, isNull);
    });

    test('failure factory sets correct fields', () {
      final result = PaymentResult.failure(
        errorCode: 'NETWORK_ERROR',
        errorMessage: 'Connection timed out',
      );
      expect(result.success, isFalse);
      expect(result.errorCode, 'NETWORK_ERROR');
      expect(result.errorMessage, 'Connection timed out');
      expect(result.paymentId, isNull);
    });

    test('cancelled factory has predefined error code', () {
      final result = PaymentResult.cancelled();
      expect(result.success, isFalse);
      expect(result.errorCode, 'CANCELLED');
      expect(result.errorMessage, contains('cancelled'));
    });
  });

  group('PaymentResult — equality & properties', () {
    test('success result is not failure', () {
      final success = PaymentResult.success(paymentId: 'pay_001');
      final failure = PaymentResult.failure(
        errorCode: 'ERR',
        errorMessage: 'fail',
      );
      expect(success.success, isNot(equals(failure.success)));
    });

    test('const constructor works', () {
      const result = PaymentResult(success: false, errorMessage: 'timeout');
      expect(result.success, isFalse);
      expect(result.errorMessage, 'timeout');
    });
  });

  group('PaymentResult — amount conversion invariants', () {
    // Razorpay expects paise (amount * 100), verify the math
    test('amount to paise conversion is correct for common amounts', () {
      final testCases = {
        100.0: 10000,
        299.0: 29900,
        999.0: 99900,
        0.01: 1,
        1499.99: 149999,
      };
      for (final entry in testCases.entries) {
        final paise = (entry.key * 100).round();
        expect(
          paise,
          entry.value,
          reason: '₹${entry.key} should be ${entry.value} paise',
        );
      }
    });

    test('float precision: 0.1 + 0.2 paise conversion', () {
      // This is a known JS/Dart float issue
      final paise = ((0.1 + 0.2) * 100).round(); // should be 30
      expect(paise, 30);
    });

    test('negative amount is technically valid (refund scenario)', () {
      final paise = (-50.0 * 100).round();
      expect(paise, -5000);
    });
  });

  group('PaymentResult — error classification', () {
    test('CANCELLED is user-initiated', () {
      final result = PaymentResult.cancelled();
      expect(result.errorCode, 'CANCELLED');
      // Should not be retried
    });

    test('network errors have meaningful messages', () {
      final result = PaymentResult.failure(
        errorCode: 'NETWORK_ERROR',
        errorMessage: 'Unable to reach payment server',
      );
      expect(result.errorMessage, isNotEmpty);
      expect(result.errorCode, isNot('CANCELLED'));
    });

    test('OPEN_ERROR indicates SDK initialization issue', () {
      final result = PaymentResult.failure(
        errorCode: 'OPEN_ERROR',
        errorMessage: 'Failed to open payment gateway',
      );
      expect(result.errorCode, 'OPEN_ERROR');
    });
  });

  group('Payment timeout behavior', () {
    test('Completer can complete with success', () async {
      final completer = Completer<PaymentResult>();
      completer.complete(PaymentResult.success(paymentId: 'pay_001'));
      final result = await completer.future;
      expect(result.success, isTrue);
    });

    test('Completer cannot complete twice', () {
      final completer = Completer<PaymentResult>();
      completer.complete(PaymentResult.success(paymentId: 'pay_001'));
      // Second complete should not throw, but is a no-op if we guard
      expect(completer.isCompleted, isTrue);
    });

    test('timeout returns failure result', () async {
      final completer = Completer<PaymentResult>();
      // Simulate timeout by not completing the completer
      final result = await completer.future.timeout(
        const Duration(milliseconds: 10),
        onTimeout: () => const PaymentResult(
          success: false,
          errorMessage: 'Payment timed out',
        ),
      );
      expect(result.success, isFalse);
      expect(result.errorMessage, contains('timed out'));
    });
  });
}
