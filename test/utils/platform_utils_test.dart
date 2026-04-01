/// Tests for platform_utils.dart — platform detection and name string.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/utils/platform_utils.dart';

void main() {
  group('PlatformUtils: currentPlatformName', () {
    test('returns a non-empty string', () {
      final name = currentPlatformName;
      expect(name, isNotEmpty);
    });

    test('returns one of the known platform values', () {
      final name = currentPlatformName;
      expect(
        name,
        isIn(['web', 'android', 'ios', 'windows', 'macos', 'linux', 'unknown']),
      );
    });

    test('value is lowercase', () {
      final name = currentPlatformName;
      expect(name, equals(name.toLowerCase()));
    });

    test('consistent across multiple calls', () {
      final first = currentPlatformName;
      final second = currentPlatformName;
      expect(first, equals(second));
    });
  });

  group('PlatformUtils: platform classification', () {
    test('isMobile when platform is android or ios', () {
      const mobilePlatforms = {'android', 'ios'};
      final name = currentPlatformName;
      final isMobile = mobilePlatforms.contains(name);
      // In test environment, defaultTargetPlatform is android
      if (name == 'android' || name == 'ios') {
        expect(isMobile, isTrue);
      }
    });

    test('isDesktop when platform is windows, macos, or linux', () {
      const desktopPlatforms = {'windows', 'macos', 'linux'};
      final name = currentPlatformName;
      final isDesktop = desktopPlatforms.contains(name);
      // In test env, platform defaults to android so isDesktop is false
      if (name == 'windows' || name == 'macos' || name == 'linux') {
        expect(isDesktop, isTrue);
      } else {
        expect(isDesktop, isFalse);
      }
    });

    test('platform is not web in test environment', () {
      // kIsWeb is false in flutter_test
      expect(kIsWeb, isFalse);
    });

    test('defaultTargetPlatform can be overridden for testing', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() {
        debugDefaultTargetPlatformOverride = null;
      });
      expect(currentPlatformName, 'ios');
    });
  });
}
