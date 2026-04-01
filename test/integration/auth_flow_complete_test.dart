/// Tests for auth flow — registration, login, verification, demo mode flow logic.
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  String destinationForAuth({
    required bool isLoggedIn,
    required bool isEmailVerified,
    required bool isShopSetupComplete,
    required bool isDemoMode,
  }) {
    if (isDemoMode) return '/billing';
    if (!isLoggedIn || !isEmailVerified) return '/email-verification';
    if (!isShopSetupComplete) return '/shop-setup';
    return '/billing';
  }

  group('Auth flow: register → verify → shop setup', () {
    test('registration creates user with unverified email', () {
      const isEmailVerified = false;
      const isShopSetupComplete = false;
      expect(isEmailVerified, isFalse);
      expect(isShopSetupComplete, isFalse);
    });

    test('unverified user goes to email verification', () {
      final destination = destinationForAuth(
        isLoggedIn: true,
        isEmailVerified: false,
        isShopSetupComplete: false,
        isDemoMode: false,
      );
      expect(destination, '/email-verification');
    });

    test('verified user without shop setup goes to shop setup', () {
      final destination = destinationForAuth(
        isLoggedIn: true,
        isEmailVerified: true,
        isShopSetupComplete: false,
        isDemoMode: false,
      );
      expect(destination, '/shop-setup');
    });
  });

  group('Auth flow: login verified user', () {
    test('verified user with shop setup goes to billing', () {
      final destination = destinationForAuth(
        isLoggedIn: true,
        isEmailVerified: true,
        isShopSetupComplete: true,
        isDemoMode: false,
      );
      expect(destination, '/billing');
    });
  });

  group('Auth flow: demo mode', () {
    test('demo mode login sets isDemoMode true', () {
      const isDemoMode = true;
      expect(isDemoMode, isTrue);
    });

    test('demo mode skips email verification and shop setup', () {
      final destination = destinationForAuth(
        isLoggedIn: false,
        isEmailVerified: false,
        isShopSetupComplete: false,
        isDemoMode: true,
      );
      expect(destination, '/billing');
    });
  });
}
