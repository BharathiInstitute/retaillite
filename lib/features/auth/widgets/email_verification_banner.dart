/// Email verification banner widget
/// Shows a banner with OTP verification when user's email is not verified
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:retaillite/features/auth/providers/auth_provider.dart';

/// Banner shown at the top of the app when email is not verified
class EmailVerificationBanner extends ConsumerStatefulWidget {
  const EmailVerificationBanner({super.key});

  @override
  ConsumerState<EmailVerificationBanner> createState() =>
      _EmailVerificationBannerState();
}

class _EmailVerificationBannerState
    extends ConsumerState<EmailVerificationBanner> {
  bool _dismissed = false;
  bool _sendingOtp = false;
  bool _verifying = false;
  bool _otpSent = false;
  final _otpController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() {
      _sendingOtp = true;
      _errorMessage = null;
    });

    final email = ref.read(authNotifierProvider).user?.email ?? '';
    final success = await ref
        .read(authNotifierProvider.notifier)
        .sendRegistrationOTP(email);

    if (mounted) {
      setState(() {
        _sendingOtp = false;
        _otpSent = success;
        if (!success) {
          _errorMessage = ref.read(authNotifierProvider).error;
        }
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code sent to your email!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showOtpDialog() {
    _otpController.clear();
    _errorMessage = null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.mark_email_read, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  const Text('Verify Email'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter the 6-digit code sent to your email',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      hintText: '000000',
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.green.shade600,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: _sendingOtp
                      ? null
                      : () async {
                          setState(() => _sendingOtp = true);
                          setDialogState(() {});
                          await _sendOtp();
                          if (mounted) {
                            setDialogState(() {});
                          }
                        },
                  child: _sendingOtp
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Resend Code'),
                ),
                FilledButton(
                  onPressed: _verifying
                      ? null
                      : () async {
                          final otp = _otpController.text.trim();
                          if (otp.length != 6) {
                            setDialogState(
                              () => _errorMessage = 'Please enter 6-digit code',
                            );
                            return;
                          }
                          setState(() {
                            _verifying = true;
                            _errorMessage = null;
                          });
                          setDialogState(() {});

                          final email =
                              ref.read(authNotifierProvider).user?.email ?? '';
                          final success = await ref
                              .read(authNotifierProvider.notifier)
                              .verifyRegistrationOTP(email, otp);

                          if (mounted) {
                            setState(() => _verifying = false);
                            if (success) {
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                                ScaffoldMessenger.of(
                                  dialogContext,
                                ).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Email verified successfully!',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } else {
                              _errorMessage = ref
                                  .read(authNotifierProvider)
                                  .error;
                              setDialogState(() {});
                            }
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                  ),
                  child: _verifying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Verify'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isDemoMode = ref.watch(isDemoModeProvider);

    // Don't show for: demo mode, Google users (auto-verified), already verified, or dismissed
    if (isDemoMode ||
        _dismissed ||
        user == null ||
        user.emailVerified ||
        user.email == null ||
        user.email!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Check authProvider — Google users are auto-verified
    final authState = ref.watch(authNotifierProvider);
    if (authState.firebaseUser?.providerData.any(
          (p) => p.providerId == 'google.com',
        ) ??
        false) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade600.withValues(alpha: 0.9),
            Colors.orange.shade700,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.mark_email_unread_outlined,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Please verify your email address',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Send OTP / Enter OTP button
          TextButton(
            onPressed: _sendingOtp
                ? null
                : () async {
                    if (_otpSent) {
                      // Show OTP dialog
                      _showOtpDialog();
                    } else {
                      // Send OTP first, then show dialog
                      await _sendOtp();
                      if (mounted && _otpSent) {
                        _showOtpDialog();
                      }
                    }
                  },
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.orange.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _sendingOtp
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _otpSent ? 'Enter Code' : 'Verify Now',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(width: 6),
          // Dismiss
          InkWell(
            onTap: () => setState(() => _dismissed = true),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
