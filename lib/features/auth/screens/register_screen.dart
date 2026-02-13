/// Register screen for new users
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retaillite/core/design/design_system.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/features/auth/widgets/auth_layout.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _useEmail = true;

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    ref.read(authNotifierProvider.notifier).clearError();

    try {
      // Check if registering from demo mode
      final isDemoMode = ref.read(isDemoModeProvider);
      final keepDemoData =
          OfflineStorageService.getSetting<bool>(
            'keep_demo_data',
            defaultValue: false,
          ) ??
          false;

      // Clear demo data if user doesn't want to keep it
      if (isDemoMode && !keepDemoData) {
        await OfflineStorageService.clearDemoData();
      }

      final success = await ref
          .read(authNotifierProvider.notifier)
          .register(
            email: _useEmail ? _emailPhoneController.text.trim() : null,
            phone: !_useEmail ? _emailPhoneController.text.trim() : null,
            password: _passwordController.text,
          );

      if (success && mounted) {
        context.go('/shop-setup');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Password strength calculation
  double _getPasswordStrength(String password) {
    if (password.isEmpty) return 0;
    double strength = 0;
    if (password.length >= 6) strength += 0.2;
    if (password.length >= 8) strength += 0.2;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.2;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.2;
    return strength;
  }

  Color _getStrengthColor(double strength) {
    if (strength <= 0.2) return Colors.red;
    if (strength <= 0.4) return Colors.orange;
    if (strength <= 0.6) return Colors.yellow.shade700;
    if (strength <= 0.8) return Colors.lightGreen;
    return AppColors.success;
  }

  String _getStrengthText(double strength) {
    if (strength <= 0.2) return 'Weak';
    if (strength <= 0.4) return 'Fair';
    if (strength <= 0.6) return 'Good';
    if (strength <= 0.8) return 'Strong';
    return 'Very Strong';
  }

  @override
  Widget build(BuildContext context) {
    final error = ref.watch(authErrorProvider);
    final passwordStrength = _getPasswordStrength(_passwordController.text);

    return AuthLayout(
      title: 'Create Account',
      subtitle: 'Start your journey with LITE billing',
      icon: Icons.person_add,
      onBack: () => context.pop(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Toggle Email/Phone
            Container(
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _useEmail = true;
                        _emailPhoneController.clear();
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _useEmail ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _useEmail
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
                              Icons.email_outlined,
                              size: 18,
                              color: _useEmail
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Email',
                              style: TextStyle(
                                fontWeight: _useEmail
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: _useEmail
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _useEmail = false;
                        _emailPhoneController.clear();
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_useEmail ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: !_useEmail
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
                              Icons.phone_outlined,
                              size: 18,
                              color: !_useEmail
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Phone',
                              style: TextStyle(
                                fontWeight: !_useEmail
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: !_useEmail
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
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
            const SizedBox(height: 16),

            // Password field
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Create a strong password',
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              obscureText: _obscurePassword,
              onChanged: (value) => setState(() {}),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),

            // Password strength indicator
            if (_passwordController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: passwordStrength,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(
                          _getStrengthColor(passwordStrength),
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _getStrengthText(passwordStrength),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getStrengthColor(passwordStrength),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // Confirm password field
            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                hintText: 'Re-enter your password',
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    );
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              obscureText: _obscureConfirmPassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),

            // Error message
            if (error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        error,
                        style: const TextStyle(color: AppColors.error, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Register button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Login link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Already have an account? ',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                TextButton(
                  onPressed: () => context.pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
