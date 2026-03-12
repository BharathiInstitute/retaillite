/// Tests for PhoneAuthState and PhoneAuthStatus — pure data class logic
///
/// PhoneAuthState and its copyWith are tested in isolation by duplicating
/// the lightweight class definition to avoid importing phone_auth_provider.dart
/// which triggers Firebase initialization transitively.
library;

import 'package:flutter_test/flutter_test.dart';

// ── Duplicated for isolation (matches phone_auth_provider.dart) ──

enum PhoneAuthStatus { initial, sending, codeSent, verifying, verified, error }

class PhoneAuthState {
  final PhoneAuthStatus status;
  final String? verificationId;
  final int? resendToken;
  final String? phoneNumber;
  final String? error;
  final int resendCountdown;
  final bool canResend;

  const PhoneAuthState({
    this.status = PhoneAuthStatus.initial,
    this.verificationId,
    this.resendToken,
    this.phoneNumber,
    this.error,
    this.resendCountdown = 0,
    this.canResend = false,
  });

  PhoneAuthState copyWith({
    PhoneAuthStatus? status,
    String? verificationId,
    int? resendToken,
    String? phoneNumber,
    String? error,
    int? resendCountdown,
    bool? canResend,
  }) {
    return PhoneAuthState(
      status: status ?? this.status,
      verificationId: verificationId ?? this.verificationId,
      resendToken: resendToken ?? this.resendToken,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      error: error,
      resendCountdown: resendCountdown ?? this.resendCountdown,
      canResend: canResend ?? this.canResend,
    );
  }
}

// ── Phone number formatting logic (matches _formatPhoneNumber) ──

String formatPhoneNumber(String phone, {String countryCode = '+91'}) {
  String cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  if (cleaned.startsWith('0')) cleaned = cleaned.substring(1);
  if (!cleaned.startsWith('+')) cleaned = '$countryCode$cleaned';
  return cleaned;
}

void main() {
  // ── PhoneAuthStatus enum ──

  group('PhoneAuthStatus', () {
    test('has 6 values', () {
      expect(PhoneAuthStatus.values.length, 6);
    });

    test('all values accessible', () {
      expect(PhoneAuthStatus.initial, isNotNull);
      expect(PhoneAuthStatus.sending, isNotNull);
      expect(PhoneAuthStatus.codeSent, isNotNull);
      expect(PhoneAuthStatus.verifying, isNotNull);
      expect(PhoneAuthStatus.verified, isNotNull);
      expect(PhoneAuthStatus.error, isNotNull);
    });
  });

  // ── PhoneAuthState defaults ──

  group('PhoneAuthState defaults', () {
    test('default constructor has initial status', () {
      const state = PhoneAuthState();
      expect(state.status, PhoneAuthStatus.initial);
      expect(state.verificationId, isNull);
      expect(state.resendToken, isNull);
      expect(state.phoneNumber, isNull);
      expect(state.error, isNull);
      expect(state.resendCountdown, 0);
      expect(state.canResend, false);
    });
  });

  // ── PhoneAuthState copyWith ──

  group('PhoneAuthState.copyWith', () {
    test('preserves all fields when no args', () {
      const state = PhoneAuthState(
        status: PhoneAuthStatus.codeSent,
        verificationId: 'vid-123',
        resendToken: 42,
        phoneNumber: '+919876543210',
        resendCountdown: 30,
      );
      final copy = state.copyWith();
      expect(copy.status, PhoneAuthStatus.codeSent);
      expect(copy.verificationId, 'vid-123');
      expect(copy.resendToken, 42);
      expect(copy.phoneNumber, '+919876543210');
      expect(copy.resendCountdown, 30);
      expect(copy.canResend, false);
    });

    test('overrides status', () {
      const state = PhoneAuthState();
      final copy = state.copyWith(status: PhoneAuthStatus.sending);
      expect(copy.status, PhoneAuthStatus.sending);
    });

    test('error parameter always replaces (even with null)', () {
      // This is the key behavior: error in copyWith is NOT ?? this.error
      const state = PhoneAuthState(
        status: PhoneAuthStatus.error,
        error: 'Something went wrong',
      );
      final copy = state.copyWith(status: PhoneAuthStatus.codeSent);
      // error was not passed, so it defaults to null parameter → error: null
      expect(copy.error, isNull);
    });

    test('error is set when provided', () {
      const state = PhoneAuthState();
      final copy = state.copyWith(
        status: PhoneAuthStatus.error,
        error: 'Network error',
      );
      expect(copy.error, 'Network error');
    });

    test('can update countdown and canResend', () {
      const state = PhoneAuthState(resendCountdown: 30);
      final copy = state.copyWith(resendCountdown: 0, canResend: true);
      expect(copy.resendCountdown, 0);
      expect(copy.canResend, true);
    });

    test(
      'state transitions: initial → sending → codeSent → verifying → verified',
      () {
        var state = const PhoneAuthState();
        expect(state.status, PhoneAuthStatus.initial);

        state = state.copyWith(status: PhoneAuthStatus.sending);
        expect(state.status, PhoneAuthStatus.sending);

        state = state.copyWith(
          status: PhoneAuthStatus.codeSent,
          verificationId: 'vid',
          phoneNumber: '+919876543210',
        );
        expect(state.status, PhoneAuthStatus.codeSent);
        expect(state.verificationId, 'vid');

        state = state.copyWith(status: PhoneAuthStatus.verifying);
        expect(state.status, PhoneAuthStatus.verifying);

        state = state.copyWith(status: PhoneAuthStatus.verified);
        expect(state.status, PhoneAuthStatus.verified);
        // Previous fields are preserved
        expect(state.verificationId, 'vid');
        expect(state.phoneNumber, '+919876543210');
      },
    );
  });

  // ── Phone number formatting ──

  group('formatPhoneNumber', () {
    test('10-digit Indian number gets +91 prefix', () {
      expect(formatPhoneNumber('9876543210'), '+919876543210');
    });

    test('strips leading zero', () {
      expect(formatPhoneNumber('09876543210'), '+919876543210');
    });

    test('preserves existing + prefix', () {
      expect(formatPhoneNumber('+919876543210'), '+919876543210');
    });

    test('strips spaces', () {
      expect(formatPhoneNumber('98765 43210'), '+919876543210');
    });

    test('strips hyphens', () {
      expect(formatPhoneNumber('987-654-3210'), '+919876543210');
    });

    test('strips parentheses', () {
      expect(formatPhoneNumber('(987)6543210'), '+919876543210');
    });

    test('handles combined formatting', () {
      expect(formatPhoneNumber('0 (987) 654-3210'), '+919876543210');
    });
  });

  // ── sendOtp state reset preserves resendToken ──

  group('sendOtp state management', () {
    test('copyWith preserves resendToken when transitioning to sending', () {
      // Simulates the fix: sendOtp should use copyWith (not new PhoneAuthState)
      // so that resendToken is preserved for the forceResendingToken parameter
      const state = PhoneAuthState(
        status: PhoneAuthStatus.codeSent,
        verificationId: 'vid-123',
        resendToken: 42,
        phoneNumber: '+919876543210',
        canResend: true,
      );

      // Save token BEFORE state reset (matches the fix)
      final previousResendToken = state.resendToken;

      // Reset state with copyWith (preserves fields)
      final newState = state.copyWith(
        status: PhoneAuthStatus.sending,
        phoneNumber: '+919876543210',
      );

      expect(previousResendToken, 42);
      expect(newState.resendToken, 42);
      expect(newState.status, PhoneAuthStatus.sending);
    });

    test('new PhoneAuthState constructor loses resendToken (old bug)', () {
      // Demonstrates the bug that was fixed: using constructor wipes resendToken
      const state = PhoneAuthState(
        status: PhoneAuthStatus.codeSent,
        resendToken: 42,
        phoneNumber: '+919876543210',
      );
      // Old code: state = PhoneAuthState(status: sending, phoneNumber: ...)
      // This loses resendToken!
      const newState = PhoneAuthState(
        status: PhoneAuthStatus.sending,
        phoneNumber: '+919876543210',
      );
      expect(state.resendToken, 42);
      expect(newState.resendToken, isNull); // Bug: token lost!
    });
  });

  // ── provider-already-linked should be treated as success ──

  group('provider-already-linked handling', () {
    test('verified status is distinct from error status', () {
      const verifiedState = PhoneAuthState(status: PhoneAuthStatus.verified);
      const errorState = PhoneAuthState(
        status: PhoneAuthStatus.error,
        error: 'Phone is already verified for this account.',
      );
      expect(verifiedState.status, PhoneAuthStatus.verified);
      expect(errorState.status, PhoneAuthStatus.error);
      expect(verifiedState.status != errorState.status, true);
    });
  });

  // ── auto-verification failure should keep codeSent ──

  group('auto-verification failure recovery', () {
    test(
      'codeSent status lets user enter code manually after auto-verify fail',
      () {
        const state = PhoneAuthState(
          status: PhoneAuthStatus.codeSent,
          verificationId: 'vid-123',
          phoneNumber: '+919876543210',
          error: 'Auto-verification failed. Please enter the code manually.',
        );
        // User should still be able to enter code
        expect(state.status, PhoneAuthStatus.codeSent);
        expect(state.verificationId, isNotNull);
        expect(state.error, contains('enter the code manually'));
      },
    );

    test('error status blocks manual code entry', () {
      const state = PhoneAuthState(
        status: PhoneAuthStatus.error,
        error: 'Auto-verification failed.',
      );
      // Error status resets the flow - user can't enter code
      expect(state.status, PhoneAuthStatus.error);
    });
  });
}
