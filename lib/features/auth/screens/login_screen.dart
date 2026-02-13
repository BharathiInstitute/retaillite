/// Login screen for existing users
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retaillite/core/design/design_system.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/features/auth/widgets/auth_layout.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _useEmail = true;

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    ref.read(authNotifierProvider.notifier).clearError();

    try {
      final success = await ref
          .read(authNotifierProvider.notifier)
          .signIn(
            email: _useEmail ? _emailPhoneController.text.trim() : null,
            phone: !_useEmail ? _emailPhoneController.text.trim() : null,
            password: _passwordController.text,
          );

      if (success && mounted) {
        context.go('/billing');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDemoLogin() async {
    setState(() => _isLoading = true);
    ref.read(authNotifierProvider.notifier).clearError();

    try {
      await ref.read(authNotifierProvider.notifier).startDemoMode();

      if (mounted) {
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
      title: 'Sign In',
      subtitle: 'Welcome back! Please enter your details.',
      icon: Icons.storefront,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Toggle Email/Phone
            _buildToggle(),
            const SizedBox(height: AppSizes.xl),

            // Email/Phone field
            TextFormField(
              controller: _emailPhoneController,
              decoration: InputDecoration(
                labelText: _useEmail ? 'Email Address' : 'Phone Number',
                hintText: _useEmail
                    ? 'you@example.com'
                    : 'Enter 10-digit number',
                prefixIcon: Icon(
                  _useEmail ? Icons.email_outlined : Icons.phone_outlined,
                  color: AppColors.textSecondary,
                ),
              ),
              keyboardType: _useEmail
                  ? TextInputType.emailAddress
                  : TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return _useEmail
                      ? 'Please enter your email'
                      : 'Please enter your phone number';
                }
                if (_useEmail && !value.contains('@')) {
                  return 'Please enter a valid email';
                }
                if (!_useEmail && value.length < 10) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.md),

            // Password field
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              obscureText: _obscurePassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.sm),

            // Forgot password link
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/forgot-password'),
                child: const Text('Forgot password?'),
              ),
            ),

            // Error message
            if (error != null) ...[
              const SizedBox(height: AppSizes.sm),
              _buildErrorBox(error),
            ],
            const SizedBox(height: AppSizes.xl),

            // Sign In button
            SizedBox(
              height: AppSizes.buttonHeight(context),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text('Sign In', style: AppTypography.button),
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // Divider
            const Row(
              children: [
                Expanded(child: Divider(color: AppColors.border)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSizes.md),
                  child: Text(
                    'or',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                Expanded(child: Divider(color: AppColors.border)),
              ],
            ),
            const SizedBox(height: AppSizes.md),

            // Try Demo button
            SizedBox(
              height: AppSizes.buttonHeight(context),
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _handleDemoLogin,
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Try Demo Mode'),
              ),
            ),
            const SizedBox(height: AppSizes.xl),

            // Register link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account? ",
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                TextButton(
                  onPressed: () => context.push('/register'),
                  child: const Text(
                    'Create one',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),

            // Super Admin link
            TextButton.icon(
              onPressed: () => context.push('/super-admin/login'),
              icon: const Icon(
                Icons.admin_panel_settings_outlined,
                size: AppSizes.iconSm,
                color: AppColors.textSecondary,
              ),
              label: const Text(
                'Super Admin Login',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      padding: const EdgeInsets.all(AppSizes.xs),
      child: Row(
        children: [
          _buildToggleItem(
            icon: Icons.email_outlined,
            label: 'Email',
            isSelected: _useEmail,
            onTap: () => setState(() {
              _useEmail = true;
              _emailPhoneController.clear();
            }),
          ),
          _buildToggleItem(
            icon: Icons.phone_outlined,
            label: 'Phone',
            isSelected: !_useEmail,
            onTap: () => setState(() {
              _useEmail = false;
              _emailPhoneController.clear();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: AppSizes.iconSm,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSizes.sm),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
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
