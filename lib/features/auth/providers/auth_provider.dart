/// Firebase Authentication Provider
/// Handles user authentication with Firebase Auth
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/models/user_model.dart';

/// Auth state
enum AuthStatus { unauthenticated, authenticated }

/// Auth state class
class AuthState {
  final AuthStatus status;
  final User? firebaseUser;
  final UserModel? user;
  final bool isLoggedIn;
  final bool isShopSetupComplete;
  final bool isDemoMode;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.firebaseUser,
    this.user,
    this.isLoggedIn = false,
    this.isShopSetupComplete = false,
    this.isDemoMode = false,
    this.isLoading = true,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? firebaseUser,
    UserModel? user,
    bool? isLoggedIn,
    bool? isShopSetupComplete,
    bool? isDemoMode,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      firebaseUser: firebaseUser ?? this.firebaseUser,
      user: user ?? this.user,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isShopSetupComplete: isShopSetupComplete ?? this.isShopSetupComplete,
      isDemoMode: isDemoMode ?? this.isDemoMode,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Firebase Auth Notifier
class FirebaseAuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseAuthNotifier() : super(const AuthState()) {
    _init();
  }

  /// Initialize - listen to auth state changes
  void _init() {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        debugPrint('🔐 Firebase Auth: User logged in - ${user.email}');
        await _loadUserProfile(user);
      } else {
        debugPrint('🔐 Firebase Auth: User logged out');
        state = const AuthState(isLoading: false);
      }
    });
  }

  /// Load user profile from Firestore
  Future<void> _loadUserProfile(User firebaseUser) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final isShopSetupComplete =
            data['isShopSetupComplete'] as bool? ?? false;

        state = AuthState(
          status: AuthStatus.authenticated,
          firebaseUser: firebaseUser,
          isLoggedIn: true,
          isShopSetupComplete: isShopSetupComplete,
          isLoading: false,
          user: UserModel(
            id: firebaseUser.uid,
            shopName: data['shopName'] as String? ?? '',
            ownerName: data['ownerName'] as String? ?? '',
            email: firebaseUser.email,
            phone: data['phone'] as String? ?? '',
            address: data['address'] as String?,
            gstNumber: data['gstNumber'] as String?,
            settings: const UserSettings(),
            createdAt:
                (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          ),
        );
      } else {
        // User exists in Auth but not in Firestore - new user needs shop setup
        state = AuthState(
          status: AuthStatus.authenticated,
          firebaseUser: firebaseUser,
          isLoggedIn: true,
          isShopSetupComplete: false,
          isLoading: false,
          user: UserModel(
            id: firebaseUser.uid,
            shopName: '',
            ownerName: '',
            email: firebaseUser.email,
            phone: '',
            settings: const UserSettings(),
            createdAt: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      debugPrint('🔐 Error loading user profile: $e');
      state = AuthState(
        status: AuthStatus.authenticated,
        firebaseUser: firebaseUser,
        isLoggedIn: true,
        isShopSetupComplete: false,
        isLoading: false,
        error: 'Failed to load user profile',
      );
    }
  }

  /// Register a new user
  Future<bool> register({
    String? email,
    String? phone,
    required String password,
  }) async {
    // Firebase Auth requires email - phone auth would need different flow
    if (email == null || email.isEmpty) {
      state = state.copyWith(error: 'Email is required for registration');
      return false;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        // Create user document in Firestore
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'email': email.trim().toLowerCase(),
          'phone': phone ?? '',
          'isShopSetupComplete': false,
          'createdAt': FieldValue.serverTimestamp(),
          'subscription': {
            'plan': 'free',
            'startDate': FieldValue.serverTimestamp(),
          },
        });

        debugPrint('✅ User registered: ${credential.user!.email}');
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered. Please login.';
          break;
        case 'weak-password':
          message = 'Password is too weak. Use at least 6 characters.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        default:
          message = 'Registration failed: ${e.message}';
      }
      state = state.copyWith(isLoading: false, error: message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Registration failed: $e',
      );
      return false;
    }
  }

  /// Sign in with email and password
  Future<bool> signIn({
    String? email,
    String? phone,
    required String password,
  }) async {
    if (email == null && phone == null) {
      state = state.copyWith(error: 'Email is required');
      return false;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      final credential = await _auth.signInWithEmailAndPassword(
        email: (email ?? phone)!.trim(),
        password: password,
      );

      if (credential.user != null) {
        debugPrint('✅ User signed in: ${credential.user!.email}');
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email. Please register.';
          break;
        case 'wrong-password':
          message = 'Incorrect password. Please try again.';
          break;
        case 'invalid-credential':
          message = 'Invalid email or password.';
          break;
        case 'invalid-email':
          message = 'Invalid email format.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;
        default:
          message = 'Login failed: ${e.message}';
      }
      state = state.copyWith(isLoading: false, error: message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Login failed: $e');
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      state = const AuthState(isLoading: false);
    } catch (e) {
      debugPrint('🔐 Error signing out: $e');
    }
  }

  /// Complete shop setup
  Future<bool> completeShopSetup({
    required String shopName,
    required String ownerName,
    String? address,
    String? gstNumber,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'shopName': shopName,
        'ownerName': ownerName,
        'address': address,
        'gstNumber': gstNumber,
        'isShopSetupComplete': true,
      }, SetOptions(merge: true));

      state = state.copyWith(
        isShopSetupComplete: true,
        user: state.user?.copyWith(
          shopName: shopName,
          ownerName: ownerName,
          address: address,
          gstNumber: gstNumber,
        ),
      );

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to save shop details: $e');
      return false;
    }
  }

  /// Update shop details
  Future<bool> updateShopDetails({
    required String shopName,
    required String ownerName,
    String? address,
    String? gstNumber,
  }) async {
    return completeShopSetup(
      shopName: shopName,
      ownerName: ownerName,
      address: address,
      gstNumber: gstNumber,
    );
  }

  /// Update shop logo
  Future<bool> updateShopLogo(String logoPath) async {
    try {
      final user = state.firebaseUser;
      if (user == null) return false;

      // Update Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'shopLogoPath': logoPath,
      });

      // Update local state
      if (state.user != null) {
        state = state.copyWith(
          user: state.user!.copyWith(shopLogoPath: logoPath),
        );
      }

      return true;
    } catch (e) {
      debugPrint('🔐 Error updating shop logo: $e');
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Check if user is registered (for forgot password)
  Future<bool> isUserRegistered(String emailOrPhone) async {
    try {
      // Try to fetch sign-in methods for the email
      final methods = await _auth.fetchSignInMethodsForEmail(
        emailOrPhone.trim(),
      );
      return methods.isNotEmpty;
    } catch (e) {
      debugPrint('🔐 Error checking if user registered: $e');
      return false;
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to send reset email: $e');
      return false;
    }
  }

  /// Start demo mode (keeps local data for demo)
  Future<void> startDemoMode() async {
    state = AuthState(
      status: AuthStatus.authenticated,
      isLoggedIn: true,
      isShopSetupComplete: true,
      isDemoMode: true,
      isLoading: false,
      user: UserModel(
        id: 'demo_user',
        shopName: 'Demo Shop',
        ownerName: 'Demo Owner',
        email: 'demo@retaillite.com',
        phone: '9876543210',
        settings: const UserSettings(),
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Exit demo mode
  Future<void> exitDemoMode() async {
    state = const AuthState(isLoading: false, isDemoMode: false);
  }

  /// Register from demo mode (placeholder - needs implementation)
  Future<bool> registerFromDemoMode({
    String? email,
    String? phone,
    required String password,
    required bool keepDemoData,
  }) async {
    // First exit demo mode
    await exitDemoMode();

    // Then register with Firebase
    return register(email: email ?? '', password: password, phone: phone);
  }
}

/// Auth provider (Firebase mode)
final authNotifierProvider =
    StateNotifierProvider<FirebaseAuthNotifier, AuthState>(
      (ref) => FirebaseAuthNotifier(),
    );

/// Current user provider
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authNotifierProvider).user;
});

/// Is logged in provider
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isLoggedIn;
});

/// Is shop setup complete provider
final isShopSetupCompleteProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isShopSetupComplete;
});

/// Auth error provider
final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authNotifierProvider).error;
});

/// Is demo mode provider
final isDemoModeProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isDemoMode;
});
