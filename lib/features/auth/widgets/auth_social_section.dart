/// Shared social/email auth section used by Login & Register screens
/// Contains: Google Sign-In button + OR divider + Email toggle button
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:retaillite/core/design/design_system.dart';

/// Reusable widget for the Google + OR + Email toggle section
class AuthSocialSection extends StatelessWidget {
  /// Whether the Google sign-in is in progress
  final bool isGoogleLoading;

  /// Whether any other action is loading (disables Google button)
  final bool isOtherLoading;

  /// Whether the email form is currently expanded
  final bool showEmailForm;

  /// Label for the email toggle button (e.g. "Sign in with Email" or "Register with Email")
  final String emailButtonLabel;

  /// Called when Google button is pressed
  final VoidCallback onGooglePressed;

  /// Called when email toggle button is pressed
  final VoidCallback onEmailToggle;

  const AuthSocialSection({
    super.key,
    required this.isGoogleLoading,
    required this.isOtherLoading,
    required this.showEmailForm,
    required this.emailButtonLabel,
    required this.onGooglePressed,
    required this.onEmailToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Google Sign-In (Primary) ──
        SizedBox(
          height: AppSizes.buttonHeight(context),
          child: OutlinedButton.icon(
            onPressed: (isGoogleLoading || isOtherLoading)
                ? null
                : onGooglePressed,
            icon: isGoogleLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : SvgPicture.asset(
                    'assets/icons/google_logo.svg',
                    height: 22,
                    width: 22,
                  ),
            label: Text(
              isGoogleLoading ? 'Signing in...' : 'Continue with Google',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.lg),

        // ── OR Divider ──
        const Row(
          children: [
            Expanded(child: Divider(color: AppColors.border)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(child: Divider(color: AppColors.border)),
          ],
        ),
        const SizedBox(height: AppSizes.lg),

        // ── Email Toggle Button ──
        if (!showEmailForm)
          SizedBox(
            height: AppSizes.buttonHeight(context),
            child: OutlinedButton.icon(
              onPressed: onEmailToggle,
              icon: const Icon(Icons.email_outlined, size: 22),
              label: Text(
                emailButtonLabel,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
