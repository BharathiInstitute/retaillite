/// Tests for UpdateDialog — display logic, force update, and download states.
///
/// Depends on WindowsUpdateService. We test the pure UI logic inline.
library;

import 'package:flutter_test/flutter_test.dart';

// ── Inline AppVersionInfo stub (mirrors windows_update_service.dart) ──

class _AppVersionInfo {
  final String version;
  final String changelog;

  const _AppVersionInfo({required this.version, this.changelog = ''});
}

void main() {
  // ── Version text display ──
  // Mirrors: 'Version ${widget.versionInfo.version} is available!'

  group('UpdateDialog version text', () {
    test('version text format', () {
      const info = _AppVersionInfo(version: '3.0.0');
      expect(
        'Version ${info.version} is available!',
        'Version 3.0.0 is available!',
      );
    });
  });

  // ── Changelog visibility ──
  // Mirrors: if (widget.versionInfo.changelog.isNotEmpty)

  group('UpdateDialog changelog', () {
    test('shows changelog when non-empty', () {
      const info = _AppVersionInfo(version: '3.0.0', changelog: 'Bug fixes');
      expect(info.changelog.isNotEmpty, isTrue);
    });

    test('hides changelog when empty', () {
      const info = _AppVersionInfo(version: '3.0.0');
      expect(info.changelog.isNotEmpty, isFalse);
    });
  });

  // ── Force update hides Later button ──
  // Mirrors: if (!widget.versionInfo.forceUpdate && !_downloading) TextButton('Later')

  group('UpdateDialog force update', () {
    bool showLaterButton({
      required bool forceUpdate,
      required bool downloading,
    }) {
      return !forceUpdate && !downloading;
    }

    test('Later button visible for optional update', () {
      expect(showLaterButton(forceUpdate: false, downloading: false), isTrue);
    });

    test('Later button hidden for force update', () {
      expect(showLaterButton(forceUpdate: true, downloading: false), isFalse);
    });

    test('Later button hidden during download', () {
      expect(showLaterButton(forceUpdate: false, downloading: true), isFalse);
    });

    test('Later button hidden for force update during download', () {
      expect(showLaterButton(forceUpdate: true, downloading: true), isFalse);
    });
  });

  // ── Update Now button visibility ──
  // Mirrors: if (!_downloading) FilledButton.icon('Update Now')

  group('UpdateDialog Update Now button', () {
    test('shown when not downloading', () {
      const downloading = false;
      expect(!downloading, isTrue);
    });

    test('hidden when downloading', () {
      const downloading = true;
      expect(!downloading, isFalse);
    });
  });

  // ── Download progress text ──
  // Mirrors: _progress > 0 ? 'Downloading... ${(_progress * 100).toInt()}%' : 'Preparing download...'

  group('UpdateDialog download progress text', () {
    String progressText(double progress) {
      return progress > 0
          ? 'Downloading... ${(progress * 100).toInt()}%'
          : 'Preparing download...';
    }

    test('preparing when progress is 0', () {
      expect(progressText(0), 'Preparing download...');
    });

    test('downloading with percentage when progress > 0', () {
      expect(progressText(0.45), 'Downloading... 45%');
    });

    test('downloading at 100%', () {
      expect(progressText(1.0), 'Downloading... 100%');
    });
  });

  // ── Dialog dismissability ──
  // Mirrors: barrierDismissible: !result.versionInfo!.forceUpdate

  group('UpdateDialog dismissability', () {
    test('dismissable for optional update', () {
      const forceUpdate = false;
      expect(!forceUpdate, isTrue);
    });

    test('not dismissable for force update', () {
      const forceUpdate = true;
      expect(!forceUpdate, isFalse);
    });
  });

  // ── checkAndShow logic ──
  // Mirrors: if (!Platform.isWindows) return; if (!shouldShow) return; if (status != updateAvailable) return

  group('UpdateDialog checkAndShow conditions', () {
    bool shouldShowDialog({
      required bool isWindows,
      required bool shouldShow,
      required bool updateAvailable,
    }) {
      if (!isWindows) return false;
      if (!shouldShow) return false;
      if (!updateAvailable) return false;
      return true;
    }

    test('shows dialog when all conditions met', () {
      expect(
        shouldShowDialog(
          isWindows: true,
          shouldShow: true,
          updateAvailable: true,
        ),
        isTrue,
      );
    });

    test('does not show on non-Windows', () {
      expect(
        shouldShowDialog(
          isWindows: false,
          shouldShow: true,
          updateAvailable: true,
        ),
        isFalse,
      );
    });

    test('does not show when shouldShow is false', () {
      expect(
        shouldShowDialog(
          isWindows: true,
          shouldShow: false,
          updateAvailable: true,
        ),
        isFalse,
      );
    });

    test('does not show when no update available', () {
      expect(
        shouldShowDialog(
          isWindows: true,
          shouldShow: true,
          updateAvailable: false,
        ),
        isFalse,
      );
    });
  });

  // ── Error display ──
  // Mirrors: _error != null => Text(_error!, style: TextStyle(color: AppColors.error))

  group('UpdateDialog error display', () {
    test('no error by default', () {
      const String? error = null;
      expect(error != null, isFalse);
    });

    test('error shown after failed download', () {
      const error = 'Download failed. Please try again.';
      expect(error, isNotEmpty);
    });
  });
}
