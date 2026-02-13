/// Firebase App Check configuration
///
/// reCAPTCHA Enterprise site key is injected via --dart-define at build time:
///   flutter run --dart-define=RECAPTCHA_SITE_KEY=6Lexxxxx
///   flutter build web --dart-define=RECAPTCHA_SITE_KEY=6Lexxxxx
library;

class AppCheckConfig {
  AppCheckConfig._();

  /// reCAPTCHA Enterprise site key for web App Check
  /// Obtain from: Google Cloud Console → reCAPTCHA Enterprise → Create Key
  static const String recaptchaSiteKey = String.fromEnvironment(
    'RECAPTCHA_SITE_KEY',
  );

  /// Whether App Check is properly configured for web
  static bool get isWebConfigured => recaptchaSiteKey.isNotEmpty;
}
