/// Razorpay configuration
///
/// Get your API keys from: https://dashboard.razorpay.com/app/keys
library;

class RazorpayConfig {
  // Razorpay Key ID (Test Mode)
  // Switch to rzp_live_xxx for production
  static const String keyId = 'rzp_test_SBggB4lYrbT8Sr';

  // App info shown on Razorpay checkout
  static const String appName = 'LITE Retail';
  static const String description = 'Payment for purchase';

  // Theme colors
  static const int themeColor = 0xFF4361EE; // Primary blue

  // Prefill info
  static const String companyName = 'LITE App';

  /// Check if using test mode
  static bool get isTestMode => keyId.startsWith('rzp_test_');
}
