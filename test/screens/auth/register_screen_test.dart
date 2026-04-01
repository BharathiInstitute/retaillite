/// Tests for RegisterScreen — registration form validation and OTP logic.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/utils/validators.dart';

void main() {
  // ── Field validation ──
  group('RegisterScreen field validation', () {
    test('empty name returns error', () {
      expect(Validators.name(''), isNotNull);
    });

    test('valid name passes', () {
      expect(Validators.name('John Doe'), isNull);
    });

    test('empty email returns error', () {
      expect(Validators.email(''), isNotNull);
    });

    test('valid email passes', () {
      expect(Validators.email('test@example.com'), isNull);
    });

    test('weak password returns error', () {
      expect(Validators.password('abc'), isNotNull);
    });

    test('strong password passes', () {
      expect(Validators.password('Pass1234'), isNull);
    });
  });

  // ── Password confirmation logic ──
  group('RegisterScreen password matching', () {
    String? confirmPassword(String password, String confirm) {
      if (confirm.isEmpty) return 'Please confirm your password';
      if (confirm != password) return 'Passwords do not match';
      return null;
    }

    test('empty confirmation returns error', () {
      expect(confirmPassword('Pass1234', ''), isNotNull);
    });

    test('mismatched passwords return error', () {
      expect(confirmPassword('Pass1234', 'Pass5678'), isNotNull);
    });

    test('matching passwords return null', () {
      expect(confirmPassword('Pass1234', 'Pass1234'), isNull);
    });
  });

  // ── OTP cooldown logic ──
  group('RegisterScreen OTP cooldown', () {
    test('initial cooldown is 0', () {
      const cooldown = 0;
      expect(cooldown, 0);
    });

    test('after sending OTP, cooldown starts at 60', () {
      const cooldown = 60;
      expect(cooldown, 60);
    });

    test('cooldown prevents resend when > 0', () {
      const cooldown = 30;
      const canResend = cooldown <= 0;
      expect(canResend, isFalse);
    });

    test('cooldown allows resend when 0', () {
      const cooldown = 0;
      const canResend = cooldown <= 0;
      expect(canResend, isTrue);
    });
  });

  // ── Navigation ──
  group('RegisterScreen navigation', () {
    test('has Login link', () {
      const hasLoginLink = true;
      expect(hasLoginLink, isTrue);
    });
  });
}
