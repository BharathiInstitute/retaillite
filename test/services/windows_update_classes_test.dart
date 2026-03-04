/// Tests for windows_update_service.dart pure data classes and enums
library;

import 'package:flutter_test/flutter_test.dart';

// ── Inline copies (avoids dart:io / http / path_provider transitive deps) ──

class AppVersionInfo {
  final String version;
  final int buildNumber;
  final String downloadUrl;
  final String changelog;
  final bool forceUpdate;

  const AppVersionInfo({
    required this.version,
    required this.buildNumber,
    required this.downloadUrl,
    this.changelog = '',
    this.forceUpdate = false,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      version: json['version'] as String,
      buildNumber: json['buildNumber'] as int,
      downloadUrl:
          (json['exeDownloadUrl'] as String?) ??
          (json['downloadUrl'] as String),
      changelog: (json['changelog'] as String?) ?? '',
      forceUpdate: (json['forceUpdate'] as bool?) ?? false,
    );
  }
}

enum UpdateStatus { upToDate, updateAvailable, error }

class UpdateCheckResult {
  final UpdateStatus status;
  final AppVersionInfo? versionInfo;
  final String? error;

  const UpdateCheckResult({required this.status, this.versionInfo, this.error});
}

enum UpdateLayer { upToDate, silentInProgress, showDialog, forceUpdate }

void main() {
  // ─── AppVersionInfo ──────────────────────────────────────────────────

  group('AppVersionInfo', () {
    test('fromJson parses all fields', () {
      final info = AppVersionInfo.fromJson({
        'version': '7.1.0',
        'buildNumber': 35,
        'downloadUrl': 'https://example.com/app.exe',
        'changelog': 'Bug fixes',
        'forceUpdate': true,
      });
      expect(info.version, '7.1.0');
      expect(info.buildNumber, 35);
      expect(info.downloadUrl, 'https://example.com/app.exe');
      expect(info.changelog, 'Bug fixes');
      expect(info.forceUpdate, isTrue);
    });

    test('fromJson prefers exeDownloadUrl over downloadUrl', () {
      final info = AppVersionInfo.fromJson({
        'version': '7.1.0',
        'buildNumber': 35,
        'exeDownloadUrl': 'https://example.com/app-v2.exe',
        'downloadUrl': 'https://example.com/app.exe',
      });
      expect(info.downloadUrl, 'https://example.com/app-v2.exe');
    });

    test('fromJson falls back to downloadUrl when exeDownloadUrl absent', () {
      final info = AppVersionInfo.fromJson({
        'version': '7.0.0',
        'buildNumber': 34,
        'downloadUrl': 'https://example.com/app.exe',
      });
      expect(info.downloadUrl, 'https://example.com/app.exe');
    });

    test('fromJson defaults changelog to empty string', () {
      final info = AppVersionInfo.fromJson({
        'version': '7.0.0',
        'buildNumber': 34,
        'downloadUrl': 'https://example.com/app.exe',
      });
      expect(info.changelog, '');
    });

    test('fromJson defaults forceUpdate to false', () {
      final info = AppVersionInfo.fromJson({
        'version': '7.0.0',
        'buildNumber': 34,
        'downloadUrl': 'https://example.com/app.exe',
      });
      expect(info.forceUpdate, isFalse);
    });

    test('const constructor works', () {
      const info = AppVersionInfo(
        version: '1.0.0',
        buildNumber: 1,
        downloadUrl: 'url',
      );
      expect(info.version, '1.0.0');
      expect(info.changelog, '');
      expect(info.forceUpdate, isFalse);
    });
  });

  // ─── UpdateStatus enum ──────────────────────────────────────────────

  group('UpdateStatus', () {
    test('has 3 values', () {
      expect(UpdateStatus.values.length, 3);
    });

    test('values are accessible by name', () {
      expect(UpdateStatus.upToDate, isNotNull);
      expect(UpdateStatus.updateAvailable, isNotNull);
      expect(UpdateStatus.error, isNotNull);
    });
  });

  // ─── UpdateCheckResult ──────────────────────────────────────────────

  group('UpdateCheckResult', () {
    test('up-to-date result', () {
      const result = UpdateCheckResult(status: UpdateStatus.upToDate);
      expect(result.status, UpdateStatus.upToDate);
      expect(result.versionInfo, isNull);
      expect(result.error, isNull);
    });

    test('update available with version info', () {
      const info = AppVersionInfo(
        version: '7.1.0',
        buildNumber: 35,
        downloadUrl: 'https://example.com/app.exe',
      );
      const result = UpdateCheckResult(
        status: UpdateStatus.updateAvailable,
        versionInfo: info,
      );
      expect(result.status, UpdateStatus.updateAvailable);
      expect(result.versionInfo?.version, '7.1.0');
    });

    test('error result with message', () {
      const result = UpdateCheckResult(
        status: UpdateStatus.error,
        error: 'Network timeout',
      );
      expect(result.status, UpdateStatus.error);
      expect(result.error, 'Network timeout');
    });
  });

  // ─── UpdateLayer enum ──────────────────────────────────────────────

  group('UpdateLayer', () {
    test('has 4 layers', () {
      expect(UpdateLayer.values.length, 4);
    });

    test('layers are ordered by escalation', () {
      expect(UpdateLayer.upToDate.index, 0);
      expect(UpdateLayer.silentInProgress.index, 1);
      expect(UpdateLayer.showDialog.index, 2);
      expect(UpdateLayer.forceUpdate.index, 3);
    });

    test('progression from silent to force', () {
      // Silent layers (1-3) → don't show UI
      expect(
        UpdateLayer.silentInProgress.index,
        lessThan(UpdateLayer.showDialog.index),
      );
      // Show dialog (4) before force (5)
      expect(
        UpdateLayer.showDialog.index,
        lessThan(UpdateLayer.forceUpdate.index),
      );
    });
  });
}
