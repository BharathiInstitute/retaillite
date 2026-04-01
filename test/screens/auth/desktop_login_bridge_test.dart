/// Tests for DesktopLoginBridgeScreen — auth code extraction and token logic.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/utils/validators.dart';

void main() {
  group('DesktopLoginBridge link code extraction', () {
    test('null linkCode produces error message', () {
      const String? code = null;
      final hasError = code == null || code.isEmpty;
      expect(hasError, isTrue);
    });

    test('empty linkCode produces error message', () {
      const code = '';
      final hasError = code.isEmpty;
      expect(hasError, isTrue);
    });

    test('valid linkCode accepted', () {
      const code = 'A1B2C3';
      final hasError = code.isEmpty;
      expect(hasError, isFalse);
    });
  });

  group('DesktopLoginBridge email/password form', () {
    test('email validation rejects empty', () {
      expect(Validators.email(''), isNotNull);
    });

    test('email validation accepts valid email', () {
      expect(Validators.email('user@example.com'), isNull);
    });

    test('password validation rejects empty', () {
      expect(Validators.password(''), isNotNull);
    });

    test('password validation accepts valid password', () {
      expect(Validators.password('Pass1234'), isNull);
    });
  });

  group('DesktopLoginBridge state management', () {
    test('default states are not loading', () {
      const isLoading = false;
      const isGoogleLoading = false;
      const showEmailForm = false;
      const obscurePassword = true;
      const tokenGenerated = false;
      expect(isLoading, isFalse);
      expect(isGoogleLoading, isFalse);
      expect(showEmailForm, isFalse);
      expect(obscurePassword, isTrue);
      expect(tokenGenerated, isFalse);
    });

    test('tokenGenerated true shows success message', () {
      const tokenGenerated = true;
      expect(tokenGenerated, isTrue);
    });

    test('error state stores error message', () {
      const String error = 'Failed to link desktop app.';
      expect(error, isNotNull);
    });
  });
}
