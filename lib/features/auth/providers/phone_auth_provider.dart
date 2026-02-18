/// Phone Authentication Provider (Firebase Phone Auth OTP)
/// Handles phone number verification via SMS OTP
library;

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Phone auth state
enum PhoneAuthStatus { initial, sending, codeSent, verifying, verified, error }

/// Phone auth state class
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

/// Phone Auth Notifier - manages OTP verification flow
class PhoneAuthNotifier extends StateNotifier<PhoneAuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _resendTimer;

  PhoneAuthNotifier() : super(const PhoneAuthState());

  /// Format phone number to E.164 format for India
  String _formatPhoneNumber(String phone) {
    phone = phone.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (phone.startsWith('+')) return phone;
    if (phone.startsWith('0')) phone = phone.substring(1);
    if (phone.length == 10) return '+91$phone';
    return '+91$phone';
  }

  /// Send OTP to phone number
  Future<void> sendOtp(String phoneNumber) async {
    final formattedPhone = _formatPhoneNumber(phoneNumber);
    state = PhoneAuthState(
      status: PhoneAuthStatus.sending,
      phoneNumber: formattedPhone,
    );

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: state.resendToken,
        verificationCompleted: _onVerificationCompleted,
        verificationFailed: _onVerificationFailed,
        codeSent: _onCodeSent,
        codeAutoRetrievalTimeout: _onAutoRetrievalTimeout,
      );
    } catch (e) {
      debugPrint('📱 Phone auth error: $e');
      state = state.copyWith(
        status: PhoneAuthStatus.error,
        error: 'Failed to send OTP. Please try again.',
      );
    }
  }

  /// Resend OTP
  Future<void> resendOtp() async {
    if (!state.canResend || state.phoneNumber == null) return;

    state = state.copyWith(status: PhoneAuthStatus.sending);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: state.phoneNumber!,
        timeout: const Duration(seconds: 60),
        forceResendingToken: state.resendToken,
        verificationCompleted: _onVerificationCompleted,
        verificationFailed: _onVerificationFailed,
        codeSent: _onCodeSent,
        codeAutoRetrievalTimeout: _onAutoRetrievalTimeout,
      );
    } catch (e) {
      debugPrint('📱 Phone auth resend error: $e');
      state = state.copyWith(
        status: PhoneAuthStatus.codeSent,
        error: 'Failed to resend OTP. Please try again.',
      );
    }
  }

  /// The last verified phone credential (saved for linking to email account)
  PhoneAuthCredential? _lastVerifiedCredential;

  /// Get the last verified credential for linking
  PhoneAuthCredential? get lastVerifiedCredential => _lastVerifiedCredential;

  /// Verify OTP code entered by user
  Future<bool> verifyOtp(String smsCode) async {
    if (state.verificationId == null) {
      state = state.copyWith(
        status: PhoneAuthStatus.error,
        error: 'Verification session expired. Please resend OTP.',
      );
      return false;
    }

    state = state.copyWith(status: PhoneAuthStatus.verifying);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: state.verificationId!,
        smsCode: smsCode.trim(),
      );

      // Sign in with phone credential
      await _auth.signInWithCredential(credential);

      _lastVerifiedCredential = credential;
      state = state.copyWith(status: PhoneAuthStatus.verified);
      _cancelResendTimer();
      debugPrint('✅ Phone verification successful');
      return true;
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'invalid-verification-code':
          message = 'Invalid OTP. Please check and try again.';
          break;
        case 'session-expired':
          message = 'OTP expired. Please resend.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please wait and try again.';
          break;
        default:
          message = 'Verification failed. Please try again or resend OTP.';
      }
      state = state.copyWith(status: PhoneAuthStatus.codeSent, error: message);
      return false;
    } catch (e) {
      state = state.copyWith(
        status: PhoneAuthStatus.codeSent,
        error: 'Verification failed. Please try again.',
      );
      return false;
    }
  }

  /// Link phone credential to existing email account (for re-verification)
  Future<bool> verifyAndLinkPhone(String smsCode) async {
    if (state.verificationId == null) {
      state = state.copyWith(
        status: PhoneAuthStatus.error,
        error: 'Verification session expired. Please resend OTP.',
      );
      return false;
    }

    state = state.copyWith(status: PhoneAuthStatus.verifying);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: state.verificationId!,
        smsCode: smsCode.trim(),
      );

      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Link phone to existing account
        await currentUser.linkWithCredential(credential);
      } else {
        // Direct sign in with phone
        await _auth.signInWithCredential(credential);
      }

      state = state.copyWith(status: PhoneAuthStatus.verified);
      _cancelResendTimer();
      debugPrint('✅ Phone linked/verified successfully');
      return true;
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'invalid-verification-code':
          message = 'Invalid OTP. Please check and try again.';
          break;
        case 'credential-already-in-use':
          message = 'This phone number is already linked to another account.';
          break;
        case 'provider-already-linked':
          message = 'Phone is already verified for this account.';
          break;
        default:
          message = 'Verification failed. Please try again or resend OTP.';
      }
      state = state.copyWith(status: PhoneAuthStatus.codeSent, error: message);
      return false;
    } catch (e) {
      state = state.copyWith(
        status: PhoneAuthStatus.codeSent,
        error: 'Verification failed. Please try again.',
      );
      return false;
    }
  }

  // ── Firebase callbacks ──

  void _onVerificationCompleted(PhoneAuthCredential credential) async {
    // Auto-verification (Android only - auto-reads SMS)
    debugPrint('📱 Auto-verification completed');
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        // User is logged in — link phone rather than sign in
        // This prevents disrupting the existing auth session
        await currentUser.linkWithCredential(credential);
        debugPrint('📱 Auto-linked phone to existing account');
      } else {
        await _auth.signInWithCredential(credential);
      }
      _lastVerifiedCredential = credential;
      state = state.copyWith(status: PhoneAuthStatus.verified);
      _cancelResendTimer();
    } catch (e) {
      debugPrint('📱 Auto-verification failed: $e');
    }
  }

  void _onVerificationFailed(FirebaseAuthException e) {
    debugPrint('📱 Verification failed: ${e.code} - ${e.message}');
    String message;
    switch (e.code) {
      case 'invalid-phone-number':
        message =
            'Invalid phone number format. Please enter a valid 10-digit number.';
        break;
      case 'too-many-requests':
        message = 'Too many attempts. Please wait 10-15 minutes and try again.';
        break;
      case 'quota-exceeded':
        message = 'SMS limit reached. Please try again after some time.';
        break;
      default:
        message =
            'Could not send OTP. This may be due to too many attempts — please wait a few minutes and try again.';
    }
    state = state.copyWith(status: PhoneAuthStatus.error, error: message);
  }

  void _onCodeSent(String verificationId, int? resendToken) {
    debugPrint('📱 OTP code sent. Verification ID: $verificationId');
    state = state.copyWith(
      status: PhoneAuthStatus.codeSent,
      verificationId: verificationId,
      resendToken: resendToken,
      canResend: false,
      resendCountdown: 30,
    );
    _startResendTimer();
  }

  void _onAutoRetrievalTimeout(String verificationId) {
    debugPrint('📱 Auto-retrieval timeout');
    if (state.status != PhoneAuthStatus.verified) {
      state = state.copyWith(verificationId: verificationId);
    }
  }

  // ── Resend timer ──

  void _startResendTimer() {
    _cancelResendTimer();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.resendCountdown - 1;
      if (remaining <= 0) {
        state = state.copyWith(resendCountdown: 0, canResend: true);
        timer.cancel();
      } else {
        state = state.copyWith(resendCountdown: remaining);
      }
    });
  }

  void _cancelResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = null;
  }

  /// Reset state
  void reset() {
    _cancelResendTimer();
    _lastVerifiedCredential = null;
    state = const PhoneAuthState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith();
  }

  /// Set a custom error message
  void setError(String message) {
    state = state.copyWith(status: PhoneAuthStatus.error, error: message);
  }

  @override
  void dispose() {
    _cancelResendTimer();
    super.dispose();
  }
}

/// Phone auth provider
final phoneAuthProvider =
    StateNotifierProvider<PhoneAuthNotifier, PhoneAuthState>(
      (ref) => PhoneAuthNotifier(),
    );
