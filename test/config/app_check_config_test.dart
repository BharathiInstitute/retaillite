/// Tests for AppCheckConfig — environment-based configuration.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/config/app_check_config.dart';

void main() {
  group('AppCheckConfig', () {
    test('recaptchaSiteKey is a string (empty in test environment)', () {
      // --dart-define is not set in tests, so the key is empty
      expect(AppCheckConfig.recaptchaSiteKey, isA<String>());
    });

    test('isWebConfigured is false when no env var set', () {
      // In test environment, RECAPTCHA_SITE_KEY is not provided
      expect(AppCheckConfig.isWebConfigured, false);
    });

    test('recaptchaSiteKey is empty string without dart-define', () {
      expect(AppCheckConfig.recaptchaSiteKey, '');
    });
  });
}
