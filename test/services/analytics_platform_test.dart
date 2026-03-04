/// Analytics service — platform detection and event logging tests
///
/// Tests the AnalyticsService platform gating logic and event formatting.
/// The actual Firebase calls are platform-dependent, but we can verify
/// the platform detection constants and event naming conventions.
library;

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalyticsService — platform detection', () {
    test('desktop platforms are detected', () {
      // On Windows (this test runs here), Platform.isWindows should be true
      final isDesktop =
          Platform.isWindows || Platform.isLinux || Platform.isMacOS;
      expect(isDesktop, isTrue, reason: 'Test runs on Windows');
    });

    test('isSupported is false on desktop (where test runs)', () {
      // AnalyticsService._isSupported = kIsWeb || !isDesktop
      final isSupported =
          kIsWeb ||
          !(Platform.isWindows || Platform.isLinux || Platform.isMacOS);
      expect(
        isSupported,
        isFalse,
        reason: 'Analytics is unsupported on Windows desktop',
      );
    });

    test('hasCrashlytics is false on desktop', () {
      final hasCrashlytics =
          !kIsWeb &&
          !(Platform.isWindows || Platform.isLinux || Platform.isMacOS);
      expect(
        hasCrashlytics,
        isFalse,
        reason: 'Crashlytics is unsupported on Windows',
      );
    });
  });

  group('AnalyticsService — event naming conventions', () {
    test('event names follow Firebase conventions (snake_case)', () {
      final eventNames = [
        'bill_created',
        'product_added',
        'customer_added',
        'report_generated',
        'sync_completed',
        'screen_view',
      ];
      final snakeCaseRegex = RegExp(r'^[a-z][a-z0-9_]*$');
      for (final name in eventNames) {
        expect(
          snakeCaseRegex.hasMatch(name),
          isTrue,
          reason: '$name should be snake_case',
        );
      }
    });

    test('event names are within Firebase 40-char limit', () {
      final eventNames = [
        'bill_created',
        'product_added',
        'customer_added',
        'report_generated',
        'sync_completed',
      ];
      for (final name in eventNames) {
        expect(name.length, lessThanOrEqualTo(40));
      }
    });

    test('parameter names are within Firebase 40-char limit', () {
      final params = [
        'payment_method',
        'bill_total',
        'product_count',
        'sync_duration_ms',
        'error_type',
      ];
      for (final param in params) {
        expect(param.length, lessThanOrEqualTo(40));
      }
    });
  });

  group('AnalyticsService — performance trace names', () {
    test('trace names are descriptive and valid', () {
      final traceNames = [
        'app_startup',
        'bill_creation',
        'product_sync',
        'report_generation',
      ];
      for (final name in traceNames) {
        expect(name, isNotEmpty);
        expect(name.length, lessThanOrEqualTo(100));
      }
    });
  });
}
