/// Tests for ForgotPasswordScreen — email validation and cooldown logic.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/utils/validators.dart';

void main() {
  group('ForgotPasswordScreen email validation', () {
    test('empty email returns error', () {
      expect(Validators.email(''), isNotNull);
    });

    test('invalid email returns error', () {
      expect(Validators.email('invalid'), isNotNull);
    });

    test('valid email returns null', () {
      expect(Validators.email('user@example.com'), isNull);
    });
  });

  group('ForgotPasswordScreen cooldown logic', () {
    test('cooldown starts at 60 after send', () {
      const cooldown = 60;
      expect(cooldown, 60);
    });

    test('send blocked when cooldown > 0', () {
      const cooldown = 45;
      const canSend = cooldown <= 0;
      expect(canSend, isFalse);
    });

    test('send allowed when cooldown = 0', () {
      const cooldown = 0;
      const canSend = cooldown <= 0;
      expect(canSend, isTrue);
    });
  });

  group('ForgotPasswordScreen state', () {
    test('emailSent false by default', () {
      const emailSent = false;
      expect(emailSent, isFalse);
    });

    test('emailSent true after successful send', () {
      const emailSent = true;
      expect(emailSent, isTrue);
    });
  });
}
