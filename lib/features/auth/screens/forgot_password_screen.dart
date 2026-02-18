/// Forgot Password screen — reset via phone OTP
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retaillite/core/design/design_system.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/features/auth/providers/phone_auth_provider.dart';
import 'package:retaillite/features/auth/widgets/auth_layout.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  final bool _obscurePassword = true;
  final bool _obscureConfirmPassword = true;

  // Flow steps: 0 = enter email, 1 = enter OTP, 2 = set new password, 3 = success, 4 = email-only fallback
  int _step = 0;
  String? _phoneNumber; // User's registered phone from Firestore
  String? _userEmail;
  bool _otpVerified = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Step 0: Look up user's phone number from Firestore by email
  Future<void> _handleLookupPhone() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    ref.read(authNotifierProvider.notifier).clearError();

    try {
      final email = _emailController.text.trim();

      // Check sign-in methods first
      final methods = await ref
          .read(authNotifierProvider.notifier)
          .getSignInMethodsForEmail(email);

      if (methods != null &&
          methods.isNotEmpty &&
          !methods.contains('password')) {
        // Google-only account — no password to reset
        if (mounted) {
          setState(() => _isLoading = false);
          ref
              .read(authNotifierProvider.notifier)
              .setError(
                'This account uses Google Sign-In. No password to reset — just use the Google button on the login screen.',
              );
        }
        return;
      }

      // Look up phone number from Firestore
      final phone = await ref
          .read(authNotifierProvider.notifier)
          .getPhoneForEmail(email);

      if (phone == null || phone.isEmpty) {
        // No verified phone — offer direct email reset as fallback
        if (mounted) {
          setState(() {
            _userEmail = email;
            _step = 4; // New step: email-only fallback
            _isLoading = false;
          });
        }
        return;
      }

      // Send OTP to the registered phone
      _phoneNumber = phone;
      _userEmail = email;
      await ref
          .read(phoneAuthProvider.notifier)
          .sendOtp(phone.replaceFirst('+91', ''));

      if (mounted) {
        setState(() {
          _step = 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ref
            .read(authNotifierProvider.notifier)
            .setError('Failed to look up account. Please try again.');
      }
    }
  }

  /// Step 1: Verify OTP
  Future<void> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter 6-digit OTP')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await ref.read(phoneAuthProvider.notifier).verifyOtp(otp);
      if (success && mounted) {
        // Sign out the phone-auth session immediately
        await fb.FirebaseAuth.instance.signOut();
        setState(() {
          _otpVerified = true;
          _step = 2;
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Step 2: Set new password via admin reset
  Future<void> _handleSetNewPassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    if (!_otpVerified || _userEmail == null) return;

    setState(() => _isLoading = true);

    try {
      // Sign in with email using a temporary password reset flow
      // Since phone is verified, we use Firebase Admin SDK approach
      // For client-side, we'll send the password reset email as fallback
      // but from a verified context
      final success = await ref
          .read(authNotifierProvider.notifier)
          .sendPasswordResetEmail(_userEmail!);

      if (success && mounted) {
        setState(() {
          _step = 3;
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ref
            .read(authNotifierProvider.notifier)
            .setError('Failed to reset password. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = ref.watch(authErrorProvider);
    final phoneState = ref.watch(phoneAuthProvider);

    return AuthLayout(
      title: _step == 3 ? 'Password Reset' : 'Reset Password',
      subtitle: _stepSubtitle,
      icon: Icons.lock_reset,
      onBack: () {
        if (_step > 0 && _step < 3) {
          setState(() => _step = 0);
          ref.read(authNotifierProvider.notifier).clearError();
          ref.read(phoneAuthProvider.notifier).reset();
        } else {
          context.pop();
        }
      },
      child: _buildStepContent(error, phoneState),
    );
  }

  String get _stepSubtitle {
    switch (_step) {
      case 0:
        return 'Enter your email to get started';
      case 1:
        return 'Verify your phone number';
      case 2:
        return 'Almost done! Check your email';
      case 3:
        return 'Reset link sent successfully';
      case 4:
        return 'Reset via email';
      default:
        return '';
    }
  }

  Widget _buildStepContent(String? error, PhoneAuthState phoneState) {
    switch (_step) {
      case 0:
        return _buildEmailStep(error);
      case 1:
        return _buildOtpStep(error, phoneState);
      case 2:
        return _buildNewPasswordStep(error);
      case 3:
        return _buildSuccessView();
      case 4:
        return _buildEmailFallbackStep(error);
      default:
        return const SizedBox.shrink();
    }
  }

  /// Step 0: Enter email
  Widget _buildEmailStep(String? error) {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(AppSizes.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Enter your registered email. We\'ll send an OTP to your verified phone number to confirm your identity.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.xl),

          if (error != null) ...[
            _buildErrorBox(error),
            const SizedBox(height: AppSizes.md),
          ],

          // Email field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofocus: true,
            onFieldSubmitted: (_) => _handleLookupPhone(),
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your registered email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSizes.xl),

          // Continue button
          SizedBox(
            height: AppSizes.buttonHeight(context),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleLookupPhone,
              icon: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.phone_android, size: 22),
              label: Text(
                _isLoading ? 'Looking up...' : 'Send OTP to Phone',
                style: AppTypography.button,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.lg),

          // Back to login
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Remember your password? ',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              TextButton(
                onPressed: _isLoading ? null : () => context.pop(),
                child: const Text(
                  'Sign In',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Step 1: Enter OTP sent to phone
  Widget _buildOtpStep(String? error, PhoneAuthState phoneState) {
    // Mask phone number for display
    final maskedPhone = _phoneNumber != null && _phoneNumber!.length >= 4
        ? '${_phoneNumber!.substring(0, 3)}****${_phoneNumber!.substring(_phoneNumber!.length - 4)}'
        : _phoneNumber ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Info
        Container(
          padding: const EdgeInsets.all(AppSizes.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.sms_outlined, color: Colors.green, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'OTP sent to $maskedPhone',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.xl),

        if (error != null) ...[
          _buildErrorBox(error),
          const SizedBox(height: AppSizes.md),
        ],
        if (phoneState.error != null) ...[
          _buildErrorBox(phoneState.error!),
          const SizedBox(height: AppSizes.md),
        ],

        // OTP field
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'OTP Code',
            hintText: 'Enter 6-digit OTP',
            prefixIcon: Icon(Icons.pin_outlined),
            counterText: '',
          ),
        ),
        const SizedBox(height: AppSizes.xl),

        // Verify button
        SizedBox(
          height: AppSizes.buttonHeight(context),
          child: ElevatedButton.icon(
            onPressed:
                (_isLoading || phoneState.status == PhoneAuthStatus.verifying)
                ? null
                : _handleVerifyOtp,
            icon: (_isLoading || phoneState.status == PhoneAuthStatus.verifying)
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.verified_outlined, size: 22),
            label: Text(
              (_isLoading || phoneState.status == PhoneAuthStatus.verifying)
                  ? 'Verifying...'
                  : 'Verify OTP',
              style: AppTypography.button,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.md),

        // Resend OTP
        Center(
          child: TextButton(
            onPressed: phoneState.canResend
                ? () => ref.read(phoneAuthProvider.notifier).resendOtp()
                : null,
            child: Text(
              phoneState.canResend
                  ? 'Resend OTP'
                  : 'Resend in ${phoneState.resendCountdown}s',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  /// Step 2: After phone verified — send reset email (from verified context)
  Widget _buildNewPasswordStep(String? error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Verified badge
        Container(
          padding: const EdgeInsets.all(AppSizes.cardPadding),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified, color: Colors.green, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Phone verified! Now we\'ll send a password reset link to your email.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.xl),

        if (error != null) ...[
          _buildErrorBox(error),
          const SizedBox(height: AppSizes.md),
        ],

        // Send reset email button
        SizedBox(
          height: AppSizes.buttonHeight(context),
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleSetNewPassword,
            icon: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send, size: 22),
            label: Text(
              _isLoading ? 'Sending...' : 'Send Reset Link to Email',
              style: AppTypography.button,
            ),
          ),
        ),
      ],
    );
  }

  /// Step 3: Success
  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success icon
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.mark_email_read_outlined,
                color: Colors.green,
                size: 64,
              ),
              const SizedBox(height: AppSizes.md),
              const Text(
                'Reset Link Sent!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                'Identity verified via phone. A password reset link has been sent to\n${_userEmail ?? ''}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.xl),

        // Instructions
        Container(
          padding: const EdgeInsets.all(AppSizes.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What to do next:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '1. Check your email inbox\n'
                '2. Click the reset link in the email\n'
                '3. Set your new password\n'
                '4. Come back and sign in',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.xl),

        // Back to login button
        SizedBox(
          height: AppSizes.buttonHeight(context),
          child: ElevatedButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.login, size: 22),
            label: Text('Back to Sign In', style: AppTypography.button),
          ),
        ),
      ],
    );
  }

  /// Step 4: Email-only fallback (no verified phone found)
  Widget _buildEmailFallbackStep(String? error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Info card
        Container(
          padding: const EdgeInsets.all(AppSizes.cardPadding),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Colors.orange, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No verified phone number found for this account. '
                  'We\'ll send a password reset link directly to your email instead.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.xl),

        if (error != null) ...[
          _buildErrorBox(error),
          const SizedBox(height: AppSizes.md),
        ],

        // Email display
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.email_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _userEmail ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.xl),

        // Send reset email button
        SizedBox(
          height: AppSizes.buttonHeight(context),
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleEmailFallbackReset,
            icon: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send, size: 22),
            label: Text(
              _isLoading ? 'Sending...' : 'Send Reset Link to Email',
              style: AppTypography.button,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.md),

        // Back button
        Center(
          child: TextButton(
            onPressed: () {
              setState(() => _step = 0);
              ref.read(authNotifierProvider.notifier).clearError();
            },
            child: const Text(
              'Use a different email',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  /// Handle email-only password reset (no phone verification)
  Future<void> _handleEmailFallbackReset() async {
    if (_userEmail == null) return;

    setState(() => _isLoading = true);

    try {
      final success = await ref
          .read(authNotifierProvider.notifier)
          .sendPasswordResetEmail(_userEmail!);

      if (success && mounted) {
        setState(() {
          _step = 3;
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ref
            .read(authNotifierProvider.notifier)
            .setError('Failed to send reset email. Please try again.');
      }
    }
  }

  Widget _buildErrorBox(String error) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: AppSizes.iconMd,
          ),
          const SizedBox(width: AppSizes.cardPadding),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
