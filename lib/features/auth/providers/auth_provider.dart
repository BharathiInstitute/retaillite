/// Firebase Authentication Provider
/// Handles user authentication with Firebase Auth
library;

import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:retaillite/core/services/demo_data_service.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';
import 'package:retaillite/core/services/payment_link_service.dart';
import 'package:retaillite/features/settings/providers/theme_settings_provider.dart';
import 'package:retaillite/features/notifications/services/fcm_token_service.dart';
import 'package:retaillite/features/notifications/services/windows_notification_service.dart';
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
  final bool isEmailVerified;
  final bool isDemoMode;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.firebaseUser,
    this.user,
    this.isLoggedIn = false,
    this.isShopSetupComplete = false,
    this.isEmailVerified = false,
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
    bool? isEmailVerified,
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
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
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
  final Ref _ref;

  FirebaseAuthNotifier(this._ref) : super(const AuthState()) {
    _init();
  }

  /// Initialize - listen to auth state changes
  void _init() {
    // Safety timeout: if authStateChanges doesn't fire within 5 seconds,
    // resolve loading state based on currentUser (prevents stuck loading screen on web)
    Future.delayed(const Duration(seconds: 5), () {
      if (state.isLoading) {
        debugPrint('🔐 Auth timeout - resolving from currentUser');
        final user = _auth.currentUser;
        if (user != null) {
          _loadUserProfile(user);
        } else {
          state = const AuthState(isLoading: false);
        }
      }
    });

    // Handle redirect result when page returns from Google sign-in (Layer 3 fallback)
    if (kIsWeb) {
      _auth
          .getRedirectResult()
          .then((result) async {
            if (result.user != null) {
              debugPrint(
                '🔐 Google redirect sign-in complete: ${result.user!.email}',
              );
              await _ensureFirestoreDoc(result.user!);
            }
          })
          .catchError((e) {
            debugPrint('🔐 Redirect result check: $e');
          });
    }
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

  /// Ensure Firestore user document exists (called after redirect sign-in)
  Future<void> _ensureFirestoreDoc(User user) async {
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email?.toLowerCase() ?? '',
          'ownerName': user.displayName ?? '',
          'phone': user.phoneNumber ?? '',
          'photoUrl': user.photoURL ?? '',
          'isShopSetupComplete': false,
          'emailVerified': true,
          'phoneVerified': false,
          'authProvider': 'google',
          'createdAt': FieldValue.serverTimestamp(),
          'subscription': {
            'plan': 'free',
            'startDate': FieldValue.serverTimestamp(),
          },
        });
        debugPrint('✅ Created Firestore doc for redirect user: ${user.email}');
      } else {
        // Update Google profile data
        final data = doc.data()!;
        final updates = <String, dynamic>{};
        if (!(data['emailVerified'] as bool? ?? false)) {
          updates['emailVerified'] = true;
        }
        if (user.photoURL != null && user.photoURL!.isNotEmpty) {
          updates['photoUrl'] = user.photoURL;
        }
        if (updates.isNotEmpty) {
          await _firestore.collection('users').doc(user.uid).update(updates);
        }
      }
    } catch (e) {
      debugPrint('🔐 Error ensuring Firestore doc: $e');
    }
  }

  /// Load user profile from Firestore
  Future<void> _loadUserProfile(User firebaseUser) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      // Google sign-in users are always email-verified
      final isGoogleUser = firebaseUser.providerData.any(
        (p) => p.providerId == 'google.com',
      );

      if (doc.exists) {
        final data = doc.data()!;
        final isShopSetupComplete =
            data['isShopSetupComplete'] as bool? ?? false;

        // Load this user's cloud settings into local SharedPreferences
        await OfflineStorageService.loadAllSettingsFromCloud();

        final emailVerified =
            isGoogleUser ||
            (data['emailVerified'] as bool?) == true ||
            firebaseUser.emailVerified;

        state = AuthState(
          status: AuthStatus.authenticated,
          firebaseUser: firebaseUser,
          isLoggedIn: true,
          isShopSetupComplete: isShopSetupComplete,
          isEmailVerified: emailVerified,
          isLoading: false,
          user: UserModel(
            id: firebaseUser.uid,
            shopName: data['shopName'] as String? ?? '',
            ownerName: data['ownerName'] as String? ?? '',
            email: firebaseUser.email,
            phone: data['phone'] as String? ?? '',
            address: data['address'] as String?,
            gstNumber: data['gstNumber'] as String?,
            shopLogoPath: data['shopLogoPath'] as String?,
            profileImagePath: data['profileImagePath'] as String?,
            photoUrl: data['photoUrl'] as String? ?? firebaseUser.photoURL,
            upiId: data['upiId'] as String?,
            settings: const UserSettings(),
            phoneVerified: (data['phoneVerified'] as bool?) ?? false,
            emailVerified: emailVerified,
            phoneVerifiedAt: (data['phoneVerifiedAt'] as Timestamp?)?.toDate(),
            createdAt:
                (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          ),
        );

        // Save FCM token for push notifications (non-blocking)
        // ignore: unawaited_futures
        FCMTokenService.initAndSaveToken(firebaseUser.uid);
        // Start Windows desktop notification listener
        WindowsNotificationService.startListening(firebaseUser.uid);
        // Load UPI ID from user document into PaymentLinkService
        final userUpiId = data['upiId'] as String? ?? '';
        if (userUpiId.isNotEmpty) {
          PaymentLinkService.setUpiId(userUpiId);
        }
      } else {
        // User exists in Auth but not in Firestore - new user needs shop setup
        state = AuthState(
          status: AuthStatus.authenticated,
          firebaseUser: firebaseUser,
          isLoggedIn: true,
          isEmailVerified: isGoogleUser || firebaseUser.emailVerified,
          isLoading: false,
          user: UserModel(
            id: firebaseUser.uid,
            shopName: '',
            ownerName: firebaseUser.displayName ?? '',
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
        isLoading: false,
        error: 'Failed to load user profile',
      );
    }
  }

  /// Sign in with Google — multi-layer approach for maximum reliability
  /// Web: signInWithPopup → GoogleSignIn package → signInWithRedirect
  /// Mobile: GoogleSignIn package directly
  /// Desktop: Use signInDesktop() instead (opens web app in browser)
  Future<bool> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        return await _googleSignInWeb();
      } else {
        return await _googleSignInMobile();
      }
    } catch (e) {
      debugPrint('🔐 Google sign-in error (all layers failed): $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Google sign-in failed. Please try again.',
      );
      return false;
    }
  }

  /// Web Layer 1: Firebase signInWithPopup
  Future<bool> _googleSignInWeb() async {
    // --- Layer 1: signInWithPopup ---
    try {
      debugPrint('🔐 Google Sign-In: Trying Layer 1 (signInWithPopup)...');
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      final userCredential = await _auth.signInWithPopup(googleProvider);
      final user = userCredential.user;
      if (user != null) {
        await _ensureFirestoreDoc(user);
        debugPrint('✅ Google Sign-In Layer 1 success: ${user.email}');
        return true;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('🔐 Layer 1 failed: ${e.code} - ${e.message}');

      // If user deliberately cancelled, don't try other layers
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        return false;
      }

      // Account conflict - show specific message, don't try other layers
      if (e.code == 'account-exists-with-different-credential') {
        state = state.copyWith(
          isLoading: false,
          error:
              'An account already exists with this email using a different sign-in method.',
        );
        return false;
      }

      // For popup-blocked or other errors, try Layer 2
    } catch (e) {
      debugPrint('🔐 Layer 1 failed: $e');
      // Continue to Layer 2
    }

    // --- Layer 2: GoogleSignIn package (GIS flow) ---
    try {
      debugPrint('🔐 Google Sign-In: Trying Layer 2 (GoogleSignIn package)...');
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId:
            '576503526807-gjpgq9da62trcc0t09gediob7uina6g0.apps.googleusercontent.com',
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return false; // User cancelled
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        await _ensureFirestoreDoc(user);
        debugPrint('✅ Google Sign-In Layer 2 success: ${user.email}');
        return true;
      }
    } catch (e) {
      debugPrint('🔐 Layer 2 failed: $e');
      // Continue to Layer 3
    }

    // --- Layer 3: signInWithRedirect (last resort) ---
    try {
      debugPrint('🔐 Google Sign-In: Trying Layer 3 (signInWithRedirect)...');
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      await _auth.signInWithRedirect(googleProvider);
      // Page will redirect — on return, authStateChanges handles login
      return true;
    } catch (e) {
      debugPrint('🔐 Layer 3 failed: $e');
      state = state.copyWith(
        isLoading: false,
        error:
            'Google sign-in failed. Please check your internet connection and try again.',
      );
      return false;
    }
  }

  /// Windows Desktop: Web-based auth via browser
  /// Opens the hosted web app for full auth (Google, email, phone, shop setup)
  /// then polls Firestore for a custom auth token
  Future<bool> signInDesktop() async {
    try {
      state = state.copyWith(isLoading: true);
      debugPrint('🖥️ Desktop: Starting web-based auth flow...');

      // 1. Generate a random 6-character link code
      final random = math.Random.secure();
      const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No ambiguous chars
      final linkCode = List.generate(
        6,
        (_) => chars[random.nextInt(chars.length)],
      ).join();

      debugPrint('🖥️ Desktop: Link code: $linkCode');

      // 2. Store pending session in Firestore
      await _firestore.collection('desktop_auth_sessions').doc(linkCode).set({
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Open web app in browser
      const webAppUrl = 'https://stores.tulasierp.com/desktop-login';
      final fullUrl = Uri.parse('$webAppUrl?code=$linkCode');

      if (!await launchUrl(fullUrl, mode: LaunchMode.externalApplication)) {
        state = state.copyWith(
          isLoading: false,
          error: 'Could not open browser. Please try again.',
        );
        return false;
      }

      debugPrint('🖥️ Desktop: Opened browser, polling for auth token...');

      // 4. Poll Firestore for the custom token (max 10 minutes)
      const pollInterval = Duration(seconds: 3);
      const maxWait = Duration(minutes: 10);
      final startTime = DateTime.now();

      while (DateTime.now().difference(startTime) < maxWait) {
        await Future.delayed(pollInterval);

        final sessionDoc = await _firestore
            .collection('desktop_auth_sessions')
            .doc(linkCode)
            .get();

        if (!sessionDoc.exists) {
          debugPrint('🖥️ Desktop: Session deleted (expired)');
          break;
        }

        final data = sessionDoc.data();
        if (data?['status'] == 'ready' && data?['customToken'] != null) {
          final customToken = data!['customToken'] as String;

          debugPrint('🖥️ Desktop: Got custom token, signing in...');

          // 5. Sign in with the custom token
          await _auth.signInWithCustomToken(customToken);

          // 6. Clean up the session document
          await _firestore
              .collection('desktop_auth_sessions')
              .doc(linkCode)
              .delete();

          debugPrint('✅ Desktop: Signed in successfully!');
          return true;
        }
      }

      // Timed out
      debugPrint('🖥️ Desktop: Auth timed out');
      await _firestore
          .collection('desktop_auth_sessions')
          .doc(linkCode)
          .delete();

      state = state.copyWith(
        isLoading: false,
        error: 'Sign-in timed out. Please try again.',
      );
      return false;
    } catch (e) {
      debugPrint('🖥️ Desktop auth error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Sign-in failed. Please try again.',
      );
      return false;
    }
  }

  /// Mobile: GoogleSignIn package
  Future<bool> _googleSignInMobile() async {
    final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      return false;
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user != null) {
      await _ensureFirestoreDoc(user);
      debugPrint('✅ Google Sign-In: ${user.email}');
      return true;
    }
    return false;
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
      state = state.copyWith(isLoading: true);

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
        case 'user-disabled':
          message = 'This account has been disabled. Please contact support.';
          break;
        default:
          message =
              'Login failed. Please check your credentials and try again.';
      }
      state = state.copyWith(isLoading: false, error: message);
      return false;
    } catch (e) {
      debugPrint('🔐 Login error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Login failed. Please try again.',
      );
      return false;
    }
  }

  /// Register with email and password
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    bool emailVerified = false,
  }) async {
    try {
      state = state.copyWith(isLoading: true);

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // Update display name
        await user.updateDisplayName(name.trim());

        // Send email verification only if not already verified via OTP
        if (!emailVerified) {
          try {
            await user.sendEmailVerification();
            debugPrint('📧 Verification email sent to: ${user.email}');
          } catch (e) {
            debugPrint('📧 Failed to send verification email: $e');
          }
        }

        // Create Firestore doc
        await _firestore.collection('users').doc(user.uid).set({
          'email': email.trim().toLowerCase(),
          'ownerName': name.trim(),
          'phone': '',
          'photoUrl': '',
          'isShopSetupComplete': false,
          'emailVerified': emailVerified,
          'phoneVerified': false,
          'authProvider': 'email',
          'createdAt': FieldValue.serverTimestamp(),
          'subscription': {
            'plan': 'free',
            'startDate': FieldValue.serverTimestamp(),
          },
        });

        debugPrint('✅ User registered: ${user.email}');
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'An account already exists with this email. Please login.';
          break;
        case 'weak-password':
          message = 'Password is too weak. Use at least 6 characters.';
          break;
        case 'invalid-email':
          message = 'Invalid email format.';
          break;
        default:
          message = 'Registration failed. Please try again later.';
      }
      state = state.copyWith(isLoading: false, error: message);
      return false;
    } catch (e) {
      debugPrint('🔐 Registration error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Registration failed. Please try again.',
      );
      return false;
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      state = state.copyWith(isLoading: true);
      await _auth.sendPasswordResetEmail(email: email.trim());
      state = state.copyWith(isLoading: false);
      debugPrint('✅ Password reset email sent to: $email');
      return true;
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email.';
          break;
        case 'invalid-email':
          message = 'Invalid email format.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;
        default:
          message = 'Failed to send reset email. Please try again later.';
      }
      state = state.copyWith(isLoading: false, error: message);
      return false;
    } catch (e) {
      debugPrint('🔐 Password reset error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to send reset email. Please try again.',
      );
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // Remove FCM token before clearing everything
      final userId = state.firebaseUser?.uid;
      if (userId != null) {
        await FCMTokenService.removeToken(userId);
      }
      // Stop Windows notification listener
      WindowsNotificationService.stopListening();
      // Clear local user-specific settings so they don't leak to next user
      await OfflineStorageService.clearUserLocalSettings();
      // Reset theme to default light immediately
      _ref.read(themeSettingsProvider.notifier).resetToDefault();
      await _auth.signOut();
      // Clear Firestore offline cache so next user can't see previous user's data
      // This is critical for shared devices (all platforms: Android, Web, Windows)
      await FirebaseFirestore.instance.clearPersistence();
      state = const AuthState(isLoading: false);
    } catch (e) {
      debugPrint('🔐 Error signing out: $e');
    }
  }

  /// Complete shop setup
  Future<bool> completeShopSetup({
    required String shopName,
    required String ownerName,
    String? phone,
    bool phoneVerified = false,
    String? address,
    String? gstNumber,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final data = <String, dynamic>{
        'shopName': shopName,
        'ownerName': ownerName,
        'address': address,
        'gstNumber': gstNumber,
        'isShopSetupComplete': true,
      };
      if (phone != null && phone.isNotEmpty) {
        data['phone'] = phone;
        data['phoneVerified'] = phoneVerified;
        if (phoneVerified) {
          data['phoneVerifiedAt'] = FieldValue.serverTimestamp();
        }
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(data, SetOptions(merge: true));

      state = state.copyWith(
        isShopSetupComplete: true,
        user: state.user?.copyWith(
          shopName: shopName,
          ownerName: ownerName,
          phone: phone ?? state.user?.phone,
          phoneVerified: phoneVerified,
          address: address,
          gstNumber: gstNumber,
        ),
      );

      return true;
    } catch (e) {
      debugPrint('🔐 Shop setup error: $e');
      state = state.copyWith(
        error:
            'Failed to save shop details. Please check your internet and try again.',
      );
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

  /// Update shop info with optional fields (for partial updates)
  Future<bool> updateShopInfo({
    String? shopName,
    String? ownerName,
    String? phone,
    String? address,
    String? gstNumber,
    String? email,
    String? upiId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final updates = <String, dynamic>{};
      if (shopName != null) updates['shopName'] = shopName;
      if (ownerName != null) updates['ownerName'] = ownerName;
      if (phone != null) updates['phone'] = phone;
      if (address != null) updates['address'] = address;
      if (gstNumber != null) updates['gstNumber'] = gstNumber;
      if (email != null) updates['email'] = email;
      if (upiId != null) updates['upiId'] = upiId;

      if (updates.isEmpty) return true;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(updates, SetOptions(merge: true));

      // Update local state
      if (state.user != null) {
        state = state.copyWith(
          user: state.user!.copyWith(
            shopName: shopName ?? state.user!.shopName,
            ownerName: ownerName ?? state.user!.ownerName,
            phone: phone ?? state.user!.phone,
            address: address ?? state.user!.address,
            gstNumber: gstNumber ?? state.user!.gstNumber,
            email: email ?? state.user!.email,
            upiId: upiId ?? state.user!.upiId,
          ),
        );
      }

      return true;
    } catch (e) {
      debugPrint('🔐 Error updating shop info: $e');
      return false;
    }
  }

  /// Update local user settings state (for notification preferences toggle)
  void updateLocalUserSettings(UserSettings newSettings) {
    if (state.user != null) {
      state = state.copyWith(user: state.user!.copyWith(settings: newSettings));
    }
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

  /// Update user profile image (separate from shop logo)
  Future<bool> updateProfileImage(String imagePath) async {
    try {
      final user = state.firebaseUser;
      if (user == null) return false;

      // Update Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'profileImagePath': imagePath,
      });

      // Update local state
      if (state.user != null) {
        state = state.copyWith(
          user: state.user!.copyWith(profileImagePath: imagePath),
        );
      }

      return true;
    } catch (e) {
      debugPrint('🔐 Error updating profile image: $e');
      return false;
    }
  }

  /// Link a phone credential to the current email/password account
  /// This allows future phone-based login to reach the same account
  Future<bool> linkPhoneToAccount(PhoneAuthCredential credential) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await user.linkWithCredential(credential);
      debugPrint('📱 Phone credential linked to account: ${user.email}');
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        debugPrint('📱 Phone already linked to another account');
      } else if (e.code == 'provider-already-linked') {
        debugPrint('📱 Phone provider already linked to this account');
      } else {
        debugPrint('📱 Failed to link phone: ${e.code} - ${e.message}');
      }
      // Non-fatal: phone is still saved in Firestore even if linking fails
      return false;
    } catch (e) {
      debugPrint('📱 Failed to link phone credential: $e');
      return false;
    }
  }

  /// Send registration OTP via Cloud Function (no auth required)
  Future<bool> sendRegistrationOTP(String email) async {
    try {
      final callable = FirebaseFunctions.instanceFor(
        region: 'asia-south1',
      ).httpsCallable('sendRegistrationOTP');
      final result = await callable.call({'email': email.trim().toLowerCase()});
      final data = result.data as Map<String, dynamic>;

      if (data['success'] == true) {
        debugPrint('📧 Registration OTP sent to $email');
        return true;
      } else {
        final error = data['error'] as String? ?? 'Failed to send code';
        debugPrint('📧 OTP send failed: $error');
        state = state.copyWith(error: error);
        return false;
      }
    } catch (e) {
      debugPrint('📧 Failed to send registration OTP: $e');
      state = state.copyWith(
        error: 'Failed to send verification code. Please try again.',
      );
      return false;
    }
  }

  /// Verify registration OTP via Cloud Function (no auth required)
  Future<bool> verifyRegistrationOTP(String email, String otp) async {
    try {
      final callable = FirebaseFunctions.instanceFor(
        region: 'asia-south1',
      ).httpsCallable('verifyRegistrationOTP');
      final result = await callable.call({
        'email': email.trim().toLowerCase(),
        'otp': otp,
      });
      final data = result.data as Map<String, dynamic>;

      if (data['success'] == true) {
        debugPrint('✅ Registration OTP verified for $email');
        return true;
      } else {
        final error = data['error'] as String? ?? 'Invalid code';
        state = state.copyWith(error: error);
        return false;
      }
    } catch (e) {
      debugPrint('📧 OTP verification error: $e');
      state = state.copyWith(error: 'Verification failed. Please try again.');
      return false;
    }
  }

  /// Mark the user's email as verified in Firestore and local state
  Future<void> markEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'emailVerified': true,
      });

      state = state.copyWith(
        isEmailVerified: true,
        user: state.user?.copyWith(emailVerified: true),
      );
      debugPrint('✅ Email marked as verified for ${user.email}');
    } catch (e) {
      debugPrint('🔐 Error marking email verified: $e');
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith();
  }

  /// Set a custom error message
  void setError(String message) {
    state = state.copyWith(error: message);
  }

  /// Get sign-in methods for an email (for smart login detection - Option C)
  /// Returns list like ['password'], ['google.com'], or ['google.com', 'password']
  ///
  /// NOTE: fetchSignInMethodsForEmail is deprecated when Email Enumeration
  /// Protection is enabled in Firebase. This method first tries a reliable
  /// Firestore lookup (authProvider field), then falls back to the deprecated
  /// Firebase method as a secondary check.
  Future<List<String>?> getSignInMethodsForEmail(String email) async {
    try {
      // Primary: Firestore-based lookup (reliable, not affected by deprecation)
      final provider = await getAuthProviderForEmail(email);
      if (provider != null) {
        switch (provider) {
          case 'google':
            return ['google.com'];
          case 'email':
            return ['password'];
          default:
            return [provider];
        }
      }
      // No user found in Firestore
      return [];
    } catch (e) {
      debugPrint('🔐 Error fetching sign-in methods: $e');
      return null;
    }
  }

  /// Check auth provider for an email via Firestore
  /// Returns: 'google', 'email', or null (not found)
  /// This is NOT affected by Firebase's Email Enumeration Protection
  Future<String?> getAuthProviderForEmail(String email) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.data()['authProvider'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('🔐 Error checking auth provider: $e');
      return null;
    }
  }

  /// Look up a user's verified phone number from Firestore by email
  /// Used for phone-based password reset
  Future<String?> getPhoneForEmail(String email) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .where('phoneVerified', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.data()['phone'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('🔐 Error looking up phone for email: $e');
      return null;
    }
  }

  /// Update phone verified status in Firestore
  Future<void> updatePhoneVerified({required String phone}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'phoneVerified': true,
        'phone': phone,
        'phoneVerifiedAt': FieldValue.serverTimestamp(),
      });

      if (state.user != null) {
        state = state.copyWith(
          user: state.user!.copyWith(
            phoneVerified: true,
            phone: phone,
            phoneVerifiedAt: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      debugPrint('🔐 Error updating phone verified status: $e');
    }
  }

  /// Check if a phone number is already used by another store/account
  /// Returns true if phone is taken by a different user
  Future<bool> isPhoneAlreadyUsed(String phone) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return false;

    try {
      // Normalize phone to E.164 format (+91XXXXXXXXXX)
      final normalizedPhone = phone.startsWith('+91') ? phone : '+91$phone';

      final query = await _firestore
          .collection('users')
          .where('phone', isEqualTo: normalizedPhone)
          .where('phoneVerified', isEqualTo: true)
          .get();

      // Check if any result belongs to a different user
      for (final doc in query.docs) {
        if (doc.id != currentUid) {
          debugPrint(
            '📱 Phone $normalizedPhone already used by user: ${doc.id}',
          );
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('🔐 Error checking phone uniqueness: $e');
      return false; // Don't block on error — fail open
    }
  }

  /// Change password (requires re-authentication)
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('User not logged in');
    }

    // Re-authenticate with current password
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    try {
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('Current password is incorrect');
      }
      debugPrint('🔐 Change password error: ${e.code} - ${e.message}');
      throw Exception('Failed to change password. Please try again.');
    }
  }

  /// Start demo mode (keeps local data for demo)
  Future<void> startDemoMode() async {
    // Load demo data BEFORE setting state
    DemoDataService.loadDemoData();

    state = AuthState(
      status: AuthStatus.authenticated,
      isLoggedIn: true,
      isShopSetupComplete: true,
      isEmailVerified: true,
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
    // Clear demo data
    DemoDataService.clearDemoData();
    state = const AuthState(isLoading: false);
  }
}

/// Auth provider (Firebase mode)
final authNotifierProvider =
    StateNotifierProvider<FirebaseAuthNotifier, AuthState>(
      (ref) => FirebaseAuthNotifier(ref),
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
