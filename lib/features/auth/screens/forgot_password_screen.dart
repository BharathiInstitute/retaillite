/// Forgot Password screen — reset via email link
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retaillite/core/design/design_system.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/features/auth/widgets/auth_layout.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Send password reset email
  Future<void> _handleSendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    ref.read(authNotifierProvider.notifier).clearError();

    try {
      final email = _emailController.text.trim();

      final success = await ref
          .read(authNotifierProvider.notifier)
          .sendPasswordResetEmail(email);

      if (success && mounted) {
        setState(() {
          _emailSent = true;
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

  @override
  Widget build(BuildContext context) {
    final error = ref.watch(authErrorProvider);

    return AuthLayout(
      title: _emailSent ? 'Check Your Email' : 'Reset Password',
      subtitle: _emailSent
          ? 'Reset link sent successfully'
          : 'Enter your email to reset your password',
      icon: Icons.lock_reset,
      onBack: () {
        if (_emailSent) {
          setState(() => _emailSent = false);
          ref.read(authNotifierProvider.notifier).clearError();
        } else {
          context.pop();
        }
      },
      child: _emailSent ? _buildSuccessView() : _buildEmailStep(error),
    );
  }

  /// Enter email step
  Widget _buildEmailStep(String? error) {
    return Form(
      key: _formKey,
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
                    'Enter your registered email. We\'ll send a password reset link to your email.',
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
            onFieldSubmitted: (_) => _handleSendResetEmail(),
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

          // Send reset link button
          SizedBox(
            height: AppSizes.buttonHeight(context),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleSendResetEmail,
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
                _isLoading ? 'Sending...' : 'Send Reset Link',
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

  /// Success view after email sent
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
                'A password reset link has been sent to\n${_emailController.text.trim()}',
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
