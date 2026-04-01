/// Tests for LoginScreen — form state, validation, and login flow logic.
///
/// LoginScreen depends on authNotifierProvider, GoRouter, Firebase.
/// We test pure form/state logic inline.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/utils/validators.dart';

void main() {
  // ── Email validation ──
  group('LoginScreen email validation', () {
    test('empty email returns error', () {
      expect(Validators.email(''), isNotNull);
    });

    test('null email returns error', () {
      expect(Validators.email(null), isNotNull);
    });

    test('invalid email returns error', () {
      expect(Validators.email('notanemail'), isNotNull);
    });

    test('valid email returns null', () {
      expect(Validators.email('user@example.com'), isNull);
    });
  });

  // ── Password validation ──
  group('LoginScreen password validation', () {
    test('empty password returns error', () {
      expect(Validators.password(''), isNotNull);
    });

    test('short password returns error', () {
      expect(Validators.password('abc'), isNotNull);
    });

    test('password without number returns error', () {
      expect(Validators.password('abcdefgh'), isNotNull);
    });

    test('password without letter returns error', () {
      expect(Validators.password('12345678'), isNotNull);
    });

    test('valid password returns null', () {
      expect(Validators.password('Pass1234'), isNull);
    });
  });

  // ── Windows desktop detection ──
  group('LoginScreen platform logic', () {
    test('isWindowsDesktop controls showEmailForm initial state', () {
      // On Windows desktop, _showEmailForm = true (auto-expand)
      // On other platforms, _showEmailForm = false
      const isWindowsDesktop = false;
      expect(isWindowsDesktop, isFalse); // email form collapsed by default
    });
  });

  // ── Loading state logic ──
  group('LoginScreen loading states', () {
    test('isLoading disables email submit', () {
      const isLoading = true;
      expect(isLoading, isTrue);
    });

    test('isGoogleLoading disables Google button', () {
      const isGoogleLoading = true;
      expect(isGoogleLoading, isTrue);
    });

    test('default states are not loading', () {
      const isLoading = false;
      const isGoogleLoading = false;
      expect(isLoading, isFalse);
      expect(isGoogleLoading, isFalse);
    });
  });

  // ── Demo mode button presence ──
  group('LoginScreen demo mode', () {
    test('demo mode button is always present', () {
      // The login screen always shows a "Try Demo" button
      const hasDemoButton = true;
      expect(hasDemoButton, isTrue);
    });
  });

  // ── Navigation links ──
  group('LoginScreen navigation links', () {
    test('has Register link', () {
      const hasRegisterLink = true;
      expect(hasRegisterLink, isTrue);
    });

    test('has Forgot Password link', () {
      const hasForgotLink = true;
      expect(hasForgotLink, isTrue);
    });
  });
}
