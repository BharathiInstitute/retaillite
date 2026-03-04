/// Razorpay configuration
///
/// API key is injected via --dart-define at build time:
///   flutter run --dart-define=RAZORPAY_KEY_ID=rzp_test_xxx
///   flutter build apk --dart-define=RAZORPAY_KEY_ID=rzp_live_xxx
library;

import 'package:retaillite/core/constants/app_constants.dart';

class RazorpayConfig {
  // Razorpay Key ID — injected via --dart-define, never hardcoded
  static const String keyId = String.fromEnvironment('RAZORPAY_KEY_ID');

  // Dynamically set from the logged-in user's shop name.
  // Call RazorpayConfig.setShopName(user.shopName) after user data loads.
  static String _shopName = '';

  /// Override with the logged-in user's shop name so the Razorpay checkout
  /// shows the user's own shop instead of the platform name.
  static void setShopName(String name) {
    _shopName = name.trim();
  }

  /// The name shown on the Razorpay checkout screen.
  /// Returns the user's shop name when set, falls back to the platform name.
  static String get appName =>
      _shopName.isNotEmpty ? _shopName : AppConstants.appName;

  static const String description = 'Payment for purchase';

  // Theme colors
  static const int themeColor = 0xFF4361EE; // Primary blue

  // Prefill info
  static const String companyName = AppConstants.appName;

  /// Check if using test mode
  static bool get isTestMode => keyId.startsWith('rzp_test_');

  /// Check if Razorpay is configured
  static bool get isConfigured => keyId.isNotEmpty;
}
