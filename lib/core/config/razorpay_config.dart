/// Razorpay configuration
///
/// API key is injected via --dart-define at build time:
///   flutter run --dart-define=RAZORPAY_KEY_ID=rzp_test_xxx
///   flutter build apk --dart-define=RAZORPAY_KEY_ID=rzp_live_xxx
library;

class RazorpayConfig {
  // Razorpay Key ID — injected via --dart-define, never hardcoded
  static const String keyId = String.fromEnvironment('RAZORPAY_KEY_ID');

  // App info shown on Razorpay checkout
  static const String appName = 'Tulasi Shop Lite';
  static const String description = 'Payment for purchase';

  // Theme colors
  static const int themeColor = 0xFF4361EE; // Primary blue

  // Prefill info
  static const String companyName = 'LITE App';

  /// Check if using test mode
  static bool get isTestMode => keyId.startsWith('rzp_test_');

  /// Check if Razorpay is configured
  static bool get isConfigured => keyId.isNotEmpty;
}
