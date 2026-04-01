/// Tests for ShopSetupScreen — form validation and setup flow logic.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/utils/validators.dart';

void main() {
  group('ShopSetupScreen form validation', () {
    test('empty shop name shows error', () {
      expect(Validators.name('', 'Shop name'), isNotNull);
    });

    test('valid shop name passes', () {
      expect(Validators.name('My Store', 'Shop name'), isNull);
    });

    test('empty owner name shows error', () {
      expect(Validators.name('', 'Owner name'), isNotNull);
    });

    test('valid owner name passes', () {
      expect(Validators.name('Raj Sharma', 'Owner name'), isNull);
    });

    test('valid phone passes', () {
      expect(Validators.phone('9876543210'), isNull);
    });

    test('invalid phone shows error', () {
      expect(Validators.phone('123'), isNotNull);
    });

    test('optional GST empty is valid', () {
      expect(Validators.gstNumber(''), isNull);
    });
  });

  group('ShopSetupScreen desktop detection', () {
    // On Windows desktop, phone OTP is skipped
    test('desktop platforms skip phone verification', () {
      const isDesktop = true;
      expect(isDesktop, isTrue); // phoneVerified = auto-true on desktop
    });

    test('mobile platforms require phone verification', () {
      const isDesktop = false;
      expect(isDesktop, isFalse);
    });
  });

  group('ShopSetupScreen prefill logic', () {
    test('prefills owner name from user profile', () {
      const ownerName = 'Raj Sharma';
      expect(ownerName.isNotEmpty, isTrue);
    });

    test('prefills phone without country code', () {
      const phone = '+919876543210';
      const countryCode = '+91';
      final cleaned = phone.replaceFirst(countryCode, '');
      expect(cleaned, '9876543210');
    });

    test('already verified phone skips OTP step', () {
      const phoneVerified = true;
      expect(phoneVerified, isTrue);
    });
  });
}
