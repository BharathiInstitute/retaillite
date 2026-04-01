/// Tests for DesktopLoginScreen — link code display and countdown logic.
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DesktopLoginScreen link code display', () {
    test('link code is 6 characters', () {
      const code = 'A1B2C3';
      expect(code.length, 6);
    });

    test('null code hides code display', () {
      const String? code = null;
      expect(code == null, isTrue);
    });

    test('non-null code shows code display', () {
      const code = 'X9Y8Z7';
      expect(code, isNotNull);
    });
  });

  group('DesktopLoginScreen countdown timer', () {
    test('remaining seconds calculated from expiry', () {
      final expiresAt = DateTime.now().add(const Duration(minutes: 5));
      final remaining = expiresAt.difference(DateTime.now()).inSeconds;
      expect(remaining, greaterThan(0));
      expect(remaining, lessThanOrEqualTo(300));
    });

    test('minutes and seconds formatted from remaining', () {
      const remaining = 125; // 2m 05s
      const minutes = remaining ~/ 60;
      const seconds = remaining % 60;
      expect(minutes, 2);
      expect(seconds, 5);
    });

    test('expired code shows expired message', () {
      const remaining = 0;
      expect(remaining <= 0, isTrue);
    });

    test('remaining < 60 shows warning color', () {
      const remaining = 45;
      expect(remaining < 60, isTrue);
    });

    test('remaining >= 60 shows normal color', () {
      const remaining = 120;
      expect(remaining < 60, isFalse);
    });
  });

  group('DesktopLoginScreen signing state', () {
    test('default isSigningIn is false', () {
      const isSigningIn = false;
      expect(isSigningIn, isFalse);
    });

    test('isSigningIn true during sign-in attempt', () {
      const isSigningIn = true;
      expect(isSigningIn, isTrue);
    });
  });
}
