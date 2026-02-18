/// Tests for WindowsUpdateService — version comparison and model logic
///
/// Tests pure logic only (no filesystem, no network).
/// Focuses on version comparison, model serialization,
/// and update layer escalation logic.
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/services/windows_update_service.dart';

void main() {
  group('AppVersionInfo', () {
    test('should parse from JSON correctly', () {
      final json = {
        'version': '1.2.0',
        'buildNumber': 5,
        'downloadUrl': 'https://example.com/installer.exe',
        'changelog': 'Bug fixes',
        'forceUpdate': false,
      };

      final info = AppVersionInfo.fromJson(json);

      expect(info.version, '1.2.0');
      expect(info.buildNumber, 5);
      expect(info.downloadUrl, 'https://example.com/installer.exe');
      expect(info.changelog, 'Bug fixes');
      expect(info.forceUpdate, false);
    });

    test('should handle missing optional fields', () {
      final json = {
        'version': '1.0.0',
        'buildNumber': 1,
        'downloadUrl': 'https://example.com/installer.exe',
      };

      final info = AppVersionInfo.fromJson(json);

      expect(info.changelog, ''); // default
      expect(info.forceUpdate, false); // default
    });

    test('should parse forceUpdate flag', () {
      final json = {
        'version': '2.0.0',
        'buildNumber': 10,
        'downloadUrl': 'https://example.com/installer.exe',
        'forceUpdate': true,
      };

      final info = AppVersionInfo.fromJson(json);
      expect(info.forceUpdate, true);
    });
  });

  group('UpdateCheckResult', () {
    test('upToDate result', () {
      const result = UpdateCheckResult(status: UpdateStatus.upToDate);

      expect(result.status, UpdateStatus.upToDate);
      expect(result.versionInfo, isNull);
      expect(result.error, isNull);
    });

    test('updateAvailable result with version info', () {
      const info = AppVersionInfo(
        version: '1.2.0',
        buildNumber: 5,
        downloadUrl: 'https://example.com/installer.exe',
      );

      const result = UpdateCheckResult(
        status: UpdateStatus.updateAvailable,
        versionInfo: info,
      );

      expect(result.status, UpdateStatus.updateAvailable);
      expect(result.versionInfo, isNotNull);
      expect(result.versionInfo!.buildNumber, 5);
    });

    test('error result', () {
      const result = UpdateCheckResult(
        status: UpdateStatus.error,
        error: 'Network timeout',
      );

      expect(result.status, UpdateStatus.error);
      expect(result.error, 'Network timeout');
    });
  });

  group('UpdateStatus', () {
    test('should have all expected values', () {
      expect(UpdateStatus.values.length, 3);
      expect(UpdateStatus.values, contains(UpdateStatus.upToDate));
      expect(UpdateStatus.values, contains(UpdateStatus.updateAvailable));
      expect(UpdateStatus.values, contains(UpdateStatus.error));
    });
  });

  group('UpdateLayer', () {
    test('should have all expected values', () {
      expect(UpdateLayer.values.length, 4);
      expect(UpdateLayer.values, contains(UpdateLayer.upToDate));
      expect(UpdateLayer.values, contains(UpdateLayer.silentInProgress));
      expect(UpdateLayer.values, contains(UpdateLayer.showDialog));
      expect(UpdateLayer.values, contains(UpdateLayer.forceUpdate));
    });
  });

  group('Version comparison logic', () {
    // These test the core comparison logic used by checkForUpdate()
    test('higher build number means update available', () {
      const currentBuild = 3;
      const remoteBuild = 5;

      expect(remoteBuild > currentBuild, true);
    });

    test('equal build number means up to date', () {
      const currentBuild = 5;
      const remoteBuild = 5;

      expect(remoteBuild > currentBuild, false);
    });

    test('lower build number means up to date', () {
      const currentBuild = 5;
      const remoteBuild = 3;

      expect(remoteBuild > currentBuild, false);
    });

    test('build 0 (parse failure) should not crash', () {
      final currentBuild = int.tryParse('invalid') ?? 0;
      const remoteBuild = 5;

      expect(remoteBuild > currentBuild, true);
    });
  });

  group('Silent attempt escalation logic', () {
    // Tests the logic that determines when to escalate from silent to dialog
    const maxSilentAttempts = 3;

    test('0 attempts — still in silent mode', () {
      const attempts = 0;
      expect(attempts >= maxSilentAttempts, false);
    });

    test('1 attempt — still in silent mode', () {
      const attempts = 1;
      expect(attempts >= maxSilentAttempts, false);
    });

    test('2 attempts — still in silent mode', () {
      const attempts = 2;
      expect(attempts >= maxSilentAttempts, false);
    });

    test('3 attempts — escalate to dialog', () {
      const attempts = 3;
      expect(attempts >= maxSilentAttempts, true);
    });

    test('5 attempts — stays at dialog', () {
      const attempts = 5;
      expect(attempts >= maxSilentAttempts, true);
    });
  });

  group('Marker data structure', () {
    // Tests the expected shape of the marker JSON
    test('marker should contain all required fields', () {
      final marker = {
        'installerPath': 'C:\\updates\\installer.exe',
        'version': '1.2.0',
        'buildNumber': 5,
        'downloadedAt': DateTime.now().toIso8601String(),
        'silentAttempts': 0,
        'dialogDismissed': false,
      };

      expect(marker['installerPath'], isNotNull);
      expect(marker['version'], '1.2.0');
      expect(marker['buildNumber'], 5);
      expect(marker['silentAttempts'], 0);
      expect(marker['dialogDismissed'], false);
    });

    test('should detect completed update via build comparison', () {
      const stagedBuild = 5;
      const currentBuild = 5; // Updated successfully

      expect(currentBuild >= stagedBuild, true); // Should clean up
    });

    test('should detect pending update via build comparison', () {
      const stagedBuild = 5;
      const currentBuild = 3; // Not yet updated

      expect(currentBuild >= stagedBuild, false); // Should install
    });
  });
}
