/// Tests for RazorpayConfig — shop name fallback and state management
/// Uses inline duplicate to avoid --dart-define dependency issues.
library;

import 'package:flutter_test/flutter_test.dart';

// ── Inline duplicate (RazorpayConfig logic without --dart-define const) ──

class _TestRazorpayConfig {
  static String keyId = '';
  static String _shopName = '';

  static void setShopName(String name) => _shopName = name.trim();

  static String get appName => _shopName.isNotEmpty ? _shopName : 'RetailLite';

  static bool get isTestMode => keyId.startsWith('rzp_test_');
  static bool get isConfigured => keyId.isNotEmpty;

  static void reset() {
    keyId = '';
    _shopName = '';
  }
}

void main() {
  setUp(_TestRazorpayConfig.reset);

  group('RazorpayConfig.appName', () {
    test('defaults to platform name when no shop name set', () {
      expect(_TestRazorpayConfig.appName, 'RetailLite');
    });

    test('returns shop name when set', () {
      _TestRazorpayConfig.setShopName('Tulasi Stores');
      expect(_TestRazorpayConfig.appName, 'Tulasi Stores');
    });

    test('falls back to platform name when empty shop name set', () {
      _TestRazorpayConfig.setShopName('');
      expect(_TestRazorpayConfig.appName, 'RetailLite');
    });

    test('trims whitespace from shop name', () {
      _TestRazorpayConfig.setShopName('  My Shop  ');
      expect(_TestRazorpayConfig.appName, 'My Shop');
    });

    test('whitespace-only falls back to platform name', () {
      _TestRazorpayConfig.setShopName('   ');
      expect(_TestRazorpayConfig.appName, 'RetailLite');
    });
  });

  group('RazorpayConfig.isTestMode', () {
    test('true for rzp_test_ prefix', () {
      _TestRazorpayConfig.keyId = 'rzp_test_abc123';
      expect(_TestRazorpayConfig.isTestMode, isTrue);
    });

    test('false for rzp_live_ prefix', () {
      _TestRazorpayConfig.keyId = 'rzp_live_abc123';
      expect(_TestRazorpayConfig.isTestMode, isFalse);
    });

    test('false for empty string', () {
      _TestRazorpayConfig.keyId = '';
      expect(_TestRazorpayConfig.isTestMode, isFalse);
    });
  });

  group('RazorpayConfig.isConfigured', () {
    test('false when key is empty', () {
      _TestRazorpayConfig.keyId = '';
      expect(_TestRazorpayConfig.isConfigured, isFalse);
    });

    test('true when key is present', () {
      _TestRazorpayConfig.keyId = 'rzp_test_xyz';
      expect(_TestRazorpayConfig.isConfigured, isTrue);
    });
  });
}
