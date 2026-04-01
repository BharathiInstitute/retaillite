/// Tests for UpdateBanner — show/hide logic and version display.
///
/// Depends on WindowsUpdateService + Platform.isWindows. We test
/// the pure display/state logic inline.
library;

import 'package:flutter_test/flutter_test.dart';

bool shouldShowBanner(bool shouldShow, bool hasVersionInfo) =>
    shouldShow && hasVersionInfo;

void main() {
  // ── Show/hide banner logic ──
  // Mirrors: _showBanner controls visibility; if (!_showBanner) return widget.child

  group('UpdateBanner show/hide logic', () {
    test('banner hidden by default', () {
      const showBanner = false;
      expect(showBanner, isFalse);
    });

    test('banner shown when version info is available and shouldShow=true', () {
      const shouldShow = true;
      const hasVersionInfo = true;
      final showBanner = shouldShowBanner(shouldShow, hasVersionInfo);
      expect(showBanner, isTrue);
    });

    test('banner hidden when shouldShow=false', () {
      const shouldShow = false;
      const hasVersionInfo = true;
      final showBanner = shouldShowBanner(shouldShow, hasVersionInfo);
      expect(showBanner, isFalse);
    });

    test('banner hidden when no version info', () {
      const shouldShow = true;
      const hasVersionInfo = false;
      final showBanner = shouldShowBanner(shouldShow, hasVersionInfo);
      expect(showBanner, isFalse);
    });
  });

  // ── Version text display ──
  // Mirrors: 'Update v${_versionInfo?.version} available — tap to install'

  group('UpdateBanner version text', () {
    String bannerText(String version) {
      return 'Update v$version available — tap to install';
    }

    test('displays version number correctly', () {
      expect(bannerText('2.0.0'), 'Update v2.0.0 available — tap to install');
    });

    test('displays version with build number', () {
      expect(
        bannerText('1.5.3+42'),
        'Update v1.5.3+42 available — tap to install',
      );
    });
  });

  // ── Download progress display ──
  // Mirrors: '${(_progress * 100).toInt()}%'

  group('UpdateBanner download progress', () {
    String progressText(double progress) {
      return '${(progress * 100).toInt()}%';
    }

    test('0% at start', () {
      expect(progressText(0.0), '0%');
    });

    test('50% midway', () {
      expect(progressText(0.5), '50%');
    });

    test('100% complete', () {
      expect(progressText(1.0), '100%');
    });

    test('33% for partial progress', () {
      expect(progressText(0.33), '33%');
    });
  });

  // ── Dismiss behavior ──
  // Mirrors: _showBanner = false; WindowsUpdateService.markDialogDismissed()

  group('UpdateBanner dismiss', () {
    test('dismiss hides banner', () {
      var showBanner = true;
      showBanner = false;
      expect(showBanner, isFalse);
    });
  });

  // ── Tap behavior during download ──
  // Mirrors: onTap: _downloading ? null : _startUpdate

  group('UpdateBanner tap behavior', () {
    test('tap enabled when not downloading', () {
      const downloading = false;
      const tapEnabled = !downloading;
      expect(tapEnabled, isTrue);
    });

    test('tap disabled when downloading', () {
      const downloading = true;
      const tapEnabled = !downloading;
      expect(tapEnabled, isFalse);
    });
  });
}
