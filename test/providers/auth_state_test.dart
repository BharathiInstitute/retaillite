import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';

void main() {
  group('AuthStatus enum', () {
    test('has 2 values', () {
      expect(AuthStatus.values.length, 2);
    });

    test('contains unauthenticated and authenticated', () {
      expect(AuthStatus.values, contains(AuthStatus.unauthenticated));
      expect(AuthStatus.values, contains(AuthStatus.authenticated));
    });
  });

  group('AuthState', () {
    test('default constructor has sensible defaults', () {
      const state = AuthState();
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.firebaseUser, isNull);
      expect(state.user, isNull);
      expect(state.isLoggedIn, isFalse);
      expect(state.isShopSetupComplete, isFalse);
      expect(state.isEmailVerified, isFalse);
      expect(state.isDemoMode, isFalse);
      expect(state.isLoading, isTrue); // loading by default
      expect(state.error, isNull);
      expect(state.desktopLinkCode, isNull);
      expect(state.desktopLinkExpiresAt, isNull);
    });

    test('copyWith preserves all fields when no args given', () {
      final expires = DateTime(2026, 3, 4);
      final state = AuthState(
        status: AuthStatus.authenticated,
        isLoggedIn: true,
        isShopSetupComplete: true,
        isEmailVerified: true,
        isDemoMode: true,
        isLoading: false,
        error: 'something',
        desktopLinkCode: 'ABC123',
        desktopLinkExpiresAt: expires,
      );
      final copy = state.copyWith();
      expect(copy.status, AuthStatus.authenticated);
      expect(copy.isLoggedIn, isTrue);
      expect(copy.isShopSetupComplete, isTrue);
      expect(copy.isEmailVerified, isTrue);
      expect(copy.isDemoMode, isTrue);
      expect(copy.isLoading, isFalse);
      expect(copy.desktopLinkCode, 'ABC123');
      expect(copy.desktopLinkExpiresAt, expires);
    });

    test('copyWith overrides status', () {
      const state = AuthState();
      final copy = state.copyWith(status: AuthStatus.authenticated);
      expect(copy.status, AuthStatus.authenticated);
    });

    test('copyWith overrides isLoggedIn', () {
      const state = AuthState();
      final copy = state.copyWith(isLoggedIn: true);
      expect(copy.isLoggedIn, isTrue);
    });

    test('copyWith overrides isDemoMode', () {
      const state = AuthState();
      final copy = state.copyWith(isDemoMode: true);
      expect(copy.isDemoMode, isTrue);
    });

    test('copyWith overrides isLoading', () {
      const state = AuthState();
      final copy = state.copyWith(isLoading: false);
      expect(copy.isLoading, isFalse);
    });

    test('copyWith overrides error', () {
      const state = AuthState();
      final copy = state.copyWith(error: 'Network error');
      expect(copy.error, 'Network error');
    });

    test('copyWith clears error when not provided', () {
      const state = AuthState(error: 'old error');
      final copy = state.copyWith(isLoading: false);
      // error param defaults to null in copyWith, so it should clear
      expect(copy.error, isNull);
    });

    test('copyWith overrides desktopLinkCode', () {
      const state = AuthState();
      final copy = state.copyWith(desktopLinkCode: 'XYZ');
      expect(copy.desktopLinkCode, 'XYZ');
    });

    test('copyWith overrides isShopSetupComplete', () {
      const state = AuthState();
      final copy = state.copyWith(isShopSetupComplete: true);
      expect(copy.isShopSetupComplete, isTrue);
    });

    test('copyWith overrides isEmailVerified', () {
      const state = AuthState();
      final copy = state.copyWith(isEmailVerified: true);
      expect(copy.isEmailVerified, isTrue);
    });

    test('copyWith with sentinel pattern allows setting firebaseUser to null', () {
      const state = AuthState();
      final copy = state.copyWith(firebaseUser: null);
      expect(copy.firebaseUser, isNull);
    });

    test('copyWith with sentinel pattern allows setting user to null', () {
      const state = AuthState();
      final copy = state.copyWith(user: null);
      expect(copy.user, isNull);
    });
  });
}
