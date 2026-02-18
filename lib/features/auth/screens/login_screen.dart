/// Login screen — Google Sign-In (primary) + Email/Password (secondary)
/// with smart sign-in method detection (Option C)
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:retaillite/core/utils/website_url.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retaillite/core/design/design_system.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/features/auth/widgets/auth_layout.dart';
import 'package:retaillite/features/auth/widgets/auth_social_section.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _showEmailForm = false;
  bool _isCheckingEmail = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isGoogleLoading = true);
    ref.read(authNotifierProvider.notifier).clearError();

    try {
      final success = await ref
          .read(authNotifierProvider.notifier)
          .signInWithGoogle();

      if (success && mounted) {
        context.go('/billing');
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _isCheckingEmail = true;
    });
    ref.read(authNotifierProvider.notifier).clearError();

    try {
      final email = _emailController.text.trim();

      // Smart detection: check sign-in methods for this email
      final methods = await ref
          .read(authNotifierProvider.notifier)
          .getSignInMethodsForEmail(email);

      if (mounted) setState(() => _isCheckingEmail = false);

      if (methods != null &&
          methods.isNotEmpty &&
          !methods.contains('password')) {
        // User signed up with Google but trying email/password login
        if (mounted) {
          setState(() => _isLoading = false);
          ref
              .read(authNotifierProvider.notifier)
              .setError(
                'This account uses Google Sign-In. Please use the "Continue with Google" button above.',
              );
        }
        return;
      }

      final success = await ref
          .read(authNotifierProvider.notifier)
          .signIn(email: email, password: _passwordController.text);

      if (success && mounted) {
        context.go('/billing');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = ref.watch(authErrorProvider);

    return AuthLayout(
      title: 'Welcome',
      subtitle: 'Sign in to manage your shop',
      icon: Icons.storefront,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Error message
          if (error != null) ...[
            _buildErrorBox(error),
            const SizedBox(height: AppSizes.md),
          ],

          // ── Google + OR + Email Toggle (shared widget) ──
          AuthSocialSection(
            isGoogleLoading: _isGoogleLoading,
            isOtherLoading: _isLoading,
            showEmailForm: _showEmailForm,
            emailButtonLabel: 'Sign in with Email',
            onGooglePressed: _handleGoogleLogin,
            onEmailToggle: () => setState(() => _showEmailForm = true),
          ),

          // ── Email/Password Form ──
          if (_showEmailForm)
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(
                        r'^[^@]+@[^@]+\.[^@]+',
                      ).hasMatch(value.trim())) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.md),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleEmailLogin(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.sm),

                  // Forgot Password link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => context.push('/forgot-password'),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),

                  // Login button
                  SizedBox(
                    height: AppSizes.buttonHeight(context),
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleEmailLogin,
                      icon: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.login, size: 22),
                      label: Text(
                        _isCheckingEmail
                            ? 'Checking...'
                            : _isLoading
                            ? 'Signing in...'
                            : 'Sign In',
                        style: AppTypography.button,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSizes.lg),

          // Register link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Don't have an account? ",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              TextButton(
                onPressed: _isLoading ? null : () => context.push('/register'),
                child: const Text(
                  'Register',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),

          // Visit Website link (web only)
          if (kIsWeb) ...[
            const SizedBox(height: AppSizes.lg),
            const Divider(color: AppColors.border),
            const SizedBox(height: AppSizes.sm),
            TextButton.icon(
              onPressed: () {
                launchUrl(Uri.parse(websiteUrl), webOnlyWindowName: '_self');
              },
              icon: Icon(
                Icons.language,
                size: AppSizes.iconSm,
                color: AppColors.primary,
              ),
              label: Text(
                'Visit Website',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
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
