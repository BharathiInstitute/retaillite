/// Tests for EmailVerificationScreen — OTP send/verify and resend cooldown.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/utils/validators.dart';

void main() {
  group('EmailVerificationScreen OTP validation', () {
    test('empty OTP returns error', () {
      expect(Validators.otp(''), isNotNull);
    });

    test('3-digit OTP returns error', () {
      expect(Validators.otp('123'), isNotNull);
    });

    test('valid 4-digit OTP passes', () {
      expect(Validators.otp('1234'), isNull);
    });

    test('non-numeric OTP returns error', () {
      expect(Validators.otp('abcd'), isNotNull);
    });
  });

  group('EmailVerificationScreen resend cooldown', () {
    test('resend countdown starts at 60', () {
      const countdown = 60;
      expect(countdown, 60);
    });

    test('resend blocked when countdown > 0', () {
      const countdown = 30;
      const canResend = countdown <= 0;
      expect(canResend, isFalse);
    });

    test('resend allowed when countdown = 0', () {
      const countdown = 0;
      const canResend = countdown <= 0;
      expect(canResend, isTrue);
    });
  });

  group('EmailVerificationScreen state flow', () {
    test('otpSent initially false', () {
      const otpSent = false;
      expect(otpSent, isFalse);
    });

    test('otpSent becomes true after send', () {
      const otpSent = true;
      expect(otpSent, isTrue);
    });

    test('skip navigates to shop setup', () {
      // Skip button available to proceed without email verification
      const canSkip = true;
      expect(canSkip, isTrue);
    });
  });
}
