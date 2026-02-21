/// Shop setup screen - one-time setup after registration
/// Includes phone OTP verification (for both Google & email users)
/// On Windows desktop, phone OTP is skipped (Firebase Phone Auth unsupported)
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retaillite/core/design/design_system.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/features/auth/providers/phone_auth_provider.dart';
import 'package:retaillite/features/auth/widgets/auth_layout.dart';
import 'package:retaillite/l10n/app_localizations.dart';
import 'package:retaillite/models/user_model.dart';

class ShopSetupScreen extends ConsumerStatefulWidget {
  const ShopSetupScreen({super.key});

  @override
  ConsumerState<ShopSetupScreen> createState() => _ShopSetupScreenState();
}

class _ShopSetupScreenState extends ConsumerState<ShopSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstController = TextEditingController();
  bool _isLoading = false;
  bool _phoneVerified = false;

  /// Desktop platforms don't support Firebase Phone Auth
  bool get _isDesktop => !kIsWeb && Platform.isWindows;

  @override
  void initState() {
    super.initState();
    // Pre-fill from user profile (registration or Google sign-in data)
    final user = ref.read(authNotifierProvider);
    final userModel = user.user;
    if (userModel != null) {
      if (userModel.ownerName.isNotEmpty) {
        _ownerNameController.text = userModel.ownerName;
      }
      if (userModel.phone.isNotEmpty) {
        final phone = userModel.phone.replaceFirst('+91', '');
        _phoneController.text = phone;
      }
      // If phone already verified (e.g. returning user), skip OTP
      if (userModel.phoneVerified) {
        _phoneVerified = true;
      }
    }
    // On Windows desktop, auto-skip phone verification
    // (Firebase Phone Auth is not supported on desktop)
    if (_isDesktop) {
      _phoneVerified = true;
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _addressController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 10-digit phone number')),
      );
      return;
    }

    // Check if phone is already used by another store
    final isTaken = await ref
        .read(authNotifierProvider.notifier)
        .isPhoneAlreadyUsed(phone);

    if (isTaken && mounted) {
      ref
          .read(phoneAuthProvider.notifier)
          .setError(
            'This phone number is already registered with another store. Please use a different number.',
          );
      return;
    }

    ref.read(phoneAuthProvider.notifier).sendOtp(phone);
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter 6-digit OTP')));
      return;
    }

    // Use verifyAndLinkPhone to link the phone credential directly
    // to the current user WITHOUT disrupting the auth session
    final success = await ref
        .read(phoneAuthProvider.notifier)
        .verifyAndLinkPhone(otp);
    if (success && mounted) {
      setState(() => _phoneVerified = true);

      // Update Firestore with verified phone
      final phone = _phoneController.text.trim();
      await ref
          .read(authNotifierProvider.notifier)
          .updatePhoneVerified(phone: '+91$phone');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone verified & linked to your account!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _handleSetup() async {
    if (!_formKey.currentState!.validate()) return;

    // Phone is required — must be verified (except on desktop)
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your phone number'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (!_phoneVerified && !_isDesktop) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify your phone number before continuing'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Phone linking + Firestore update already happened in _verifyOtp()
      // Just complete the shop setup with the collected details
      final success = await ref
          .read(authNotifierProvider.notifier)
          .completeShopSetup(
            shopName: _shopNameController.text.trim(),
            ownerName: _ownerNameController.text.trim(),
            phone: '+91$phone',
            phoneVerified: !_isDesktop,
            address: _addressController.text.trim().isNotEmpty
                ? _addressController.text.trim()
                : null,
            gstNumber: _gstController.text.trim().isNotEmpty
                ? _gstController.text.trim()
                : null,
          );

      if (success && mounted) {
        context.go('/billing');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save shop details. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final authState = ref.watch(authNotifierProvider);
    final userModel = authState.user;
    final phoneState = ref.watch(phoneAuthProvider);

    return AuthLayout(
      title: 'Set Up Your Shop',
      subtitle: 'Enter your shop details to get started',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile card
            if (userModel != null) _buildProfileCard(userModel),
            if (userModel != null) const SizedBox(height: 20),

            // Phone auth error
            if (phoneState.error != null) ...[
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
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        phoneState.error!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Shop Name
            TextFormField(
              controller: _shopNameController,
              decoration: InputDecoration(
                labelText: l10n.shopName,
                hintText: 'Enter your shop name',
                prefixIcon: const Icon(
                  Icons.store_outlined,
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
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your shop name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Owner Name
            TextFormField(
              controller: _ownerNameController,
              decoration: InputDecoration(
                labelText: l10n.ownerName,
                hintText: 'Enter your name',
                prefixIcon: const Icon(
                  Icons.person_outlined,
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
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone Number + Send OTP
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    enabled: !_phoneVerified,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '10-digit number',
                      prefixIcon: const Icon(
                        Icons.phone_outlined,
                        color: AppColors.textSecondary,
                      ),
                      prefixText: '+91 ',
                      suffixIcon: _phoneVerified
                          ? const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            )
                          : null,
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
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    maxLength: 10,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Phone number is required';
                      }
                      final digits = value.trim().replaceAll(
                        RegExp(r'[^0-9]'),
                        '',
                      );
                      if (digits.length != 10) {
                        return 'Enter 10-digit number';
                      }
                      return null;
                    },
                  ),
                ),
                if (!_phoneVerified && !_isDesktop) ...[
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed:
                            (phoneState.status == PhoneAuthStatus.sending ||
                                _isLoading)
                            ? null
                            : (phoneState.status == PhoneAuthStatus.codeSent ||
                                      phoneState.status ==
                                          PhoneAuthStatus.verifying ||
                                      phoneState.status ==
                                          PhoneAuthStatus.verified) &&
                                  !phoneState.canResend
                            ? null
                            : _sendOtp,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: phoneState.status == PhoneAuthStatus.sending
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                (phoneState.status ==
                                            PhoneAuthStatus.codeSent ||
                                        phoneState.status ==
                                            PhoneAuthStatus.verifying ||
                                        phoneState.status ==
                                            PhoneAuthStatus.verified)
                                    ? phoneState.canResend
                                          ? 'Resend'
                                          : '${phoneState.resendCountdown}s'
                                    : 'Send OTP',
                                style: const TextStyle(fontSize: 13),
                              ),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            // OTP input
            if ((phoneState.status == PhoneAuthStatus.codeSent ||
                    phoneState.status == PhoneAuthStatus.verifying ||
                    phoneState.status == PhoneAuthStatus.verified) &&
                !_phoneVerified) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        labelText: 'OTP Code',
                        hintText: 'Enter 6-digit OTP',
                        prefixIcon: const Icon(
                          Icons.pin_outlined,
                          color: AppColors.textSecondary,
                        ),
                        counterText: '',
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
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed:
                            phoneState.status == PhoneAuthStatus.verifying
                            ? null
                            : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: phoneState.status == PhoneAuthStatus.verifying
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Verify',
                                style: TextStyle(fontSize: 13),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Phone verified badge
            if (_phoneVerified) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: (_isDesktop ? Colors.blue : Colors.green).withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (_isDesktop ? Colors.blue : Colors.green).withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isDesktop ? Icons.info_outline : Icons.verified,
                      color: _isDesktop ? Colors.blue : Colors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isDesktop
                          ? 'Phone OTP not available on desktop — number will be saved'
                          : 'Phone number verified & linked to your account',
                      style: TextStyle(
                        color: _isDesktop ? Colors.blue : Colors.green,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Address (Optional)
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: '${l10n.address} (Optional)',
                hintText: 'Enter your shop address',
                prefixIcon: const Icon(
                  Icons.location_on_outlined,
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
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // GST Number (Optional)
            TextFormField(
              controller: _gstController,
              decoration: InputDecoration(
                labelText: 'GST Number (Optional)',
                hintText: 'Enter 15-digit GST number',
                prefixIcon: const Icon(
                  Icons.receipt_long_outlined,
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
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 32),

            // Continue Button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSetup,
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
                        'GET STARTED',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Footer
            const Text(
              'You can update these details later in Settings',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(UserModel userModel) {
    final photoUrl = userModel.photoUrl;
    final name = userModel.ownerName.isNotEmpty
        ? userModel.ownerName
        : 'New User';
    final email = userModel.email ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          // Profile photo
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                ? NetworkImage(photoUrl)
                : null,
            child: (photoUrl == null || photoUrl.isEmpty)
                ? Icon(Icons.person, size: 28, color: AppColors.primary)
                : null,
          ),
          const SizedBox(width: 14),
          // Name & email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Verified badge (only when email is actually verified)
          if (userModel.emailVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, size: 14, color: AppColors.success),
                  SizedBox(width: 4),
                  Text(
                    'Verified',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
