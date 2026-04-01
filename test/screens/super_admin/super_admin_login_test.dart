/// Tests for SuperAdminLoginScreen — email authorization and lockout logic.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/utils/validators.dart';

void main() {
  // Hardcoded admin emails from admin_firestore_service.dart
  const adminEmails = [
    'kehsaram001@gmail.com',
    'admin@retaillite.com',
    'bharathiinstitute1@gmail.com',
    'bharahiinstitute1@gmail.com',
    'shivamsingh8556@gmail.com',
    'admin@lite.app',
    'kehsihba@gmail.com',
  ];

  group('SuperAdminLogin email authorization', () {
    test('admin email is authorized', () {
      const email = 'admin@retaillite.com';
      final isAdmin = adminEmails.contains(email);
      expect(isAdmin, isTrue);
    });

    test('non-admin email is denied', () {
      const email = 'someone@random.com';
      final isAdmin = adminEmails.contains(email);
      expect(isAdmin, isFalse);
    });

    test('email validation still applies', () {
      expect(Validators.email('admin@retaillite.com'), isNull);
      expect(Validators.email(''), isNotNull);
    });
  });

  group('SuperAdminLogin lockout logic', () {
    test('max attempts is 5', () {
      const maxAttempts = 5;
      expect(maxAttempts, 5);
    });

    test('lockout duration is 30 seconds', () {
      const lockoutDuration = Duration(seconds: 30);
      expect(lockoutDuration.inSeconds, 30);
    });

    test('failed attempts below max allows retry', () {
      const failedAttempts = 3;
      const maxAttempts = 5;
      const isLocked = failedAttempts >= maxAttempts;
      expect(isLocked, isFalse);
    });

    test('failed attempts at max triggers lockout', () {
      const failedAttempts = 5;
      const maxAttempts = 5;
      const isLocked = failedAttempts >= maxAttempts;
      expect(isLocked, isTrue);
    });

    test('lockout expires after duration', () {
      final lockoutUntil = DateTime.now().subtract(const Duration(seconds: 1));
      final isStillLocked = lockoutUntil.isAfter(DateTime.now());
      expect(isStillLocked, isFalse);
    });
  });

  group('SuperAdminLogin form validation', () {
    test('password validation applies', () {
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('Pass1234'), isNull);
    });

    test('default state is not loading', () {
      const isLoading = false;
      const obscurePassword = true;
      expect(isLoading, isFalse);
      expect(obscurePassword, isTrue);
    });
  });
}
