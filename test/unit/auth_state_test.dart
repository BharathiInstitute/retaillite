import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/models/user_model.dart';

void main() {
  group('AuthState', () {
    test('should have unauthenticated defaults', () {
      const state = AuthState();

      expect(state.status, AuthStatus.unauthenticated);
      expect(state.firebaseUser, isNull);
      expect(state.user, isNull);
      expect(state.isLoggedIn, false);
      expect(state.isShopSetupComplete, false);
      expect(state.isDemoMode, false);
      expect(state.isLoading, true);
      expect(state.error, isNull);
    });

    test('should create authenticated state', () {
      final user = UserModel(
        id: 'u1',
        shopName: 'Test Shop',
        ownerName: 'Test Owner',
        email: 'test@test.com',
        phone: '1234567890',
        settings: const UserSettings(),
        createdAt: DateTime(2024),
      );

      final state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        isLoggedIn: true,
        isShopSetupComplete: true,
        isLoading: false,
      );

      expect(state.status, AuthStatus.authenticated);
      expect(state.isLoggedIn, true);
      expect(state.isShopSetupComplete, true);
      expect(state.isLoading, false);
      expect(state.user?.shopName, 'Test Shop');
    });

    test('should copyWith preserve unchanged fields', () {
      final state = AuthState(
        status: AuthStatus.authenticated,
        isLoggedIn: true,
        isShopSetupComplete: true,
        isLoading: false,
        user: UserModel(
          id: 'u1',
          shopName: 'Shop',
          ownerName: 'Owner',
          email: 'x@x.com',
          phone: '0',
          settings: const UserSettings(),
          createdAt: DateTime(2024),
        ),
      );

      final updated = state.copyWith(isLoading: true);

      expect(updated.isLoading, true);
      expect(updated.isLoggedIn, true);
      expect(updated.status, AuthStatus.authenticated);
      expect(updated.user?.shopName, 'Shop');
    });

    test('should copyWith set error', () {
      const state = AuthState(isLoading: false);
      final withError = state.copyWith(error: 'Something went wrong');

      expect(withError.error, 'Something went wrong');
      expect(withError.isLoading, false);
    });

    test('should copyWith clear error when null not passed', () {
      // error uses a different pattern — check copyWith behavior
      const state = AuthState(error: 'Old error', isLoading: false);

      // copyWith without error parameter clears the error (error defaults to null)
      final cleared = state.copyWith();
      expect(cleared.error, isNull);
    });

    test('should represent demo mode', () {
      const state = AuthState(
        status: AuthStatus.authenticated,
        isLoggedIn: true,
        isShopSetupComplete: true,
        isDemoMode: true,
        isLoading: false,
      );

      expect(state.isDemoMode, true);
      expect(state.isLoggedIn, true);
      expect(state.firebaseUser, isNull); // no real firebase user in demo
    });
  });

  group('AuthStatus', () {
    test('should have correct enum values', () {
      expect(AuthStatus.values.length, 2);
      expect(AuthStatus.values, contains(AuthStatus.unauthenticated));
      expect(AuthStatus.values, contains(AuthStatus.authenticated));
    });
  });
}
