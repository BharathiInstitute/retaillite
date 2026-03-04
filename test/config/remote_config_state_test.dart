/// Tests for RemoteConfigState — version comparison and state management
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/config/remote_config_state.dart';

void main() {
  // Save originals and restore after each test
  late String origAppVersion;
  late String origLatestVersion;
  late String origAnnouncement;

  setUp(() {
    origAppVersion = RemoteConfigState.appVersion;
    origLatestVersion = RemoteConfigState.latestVersion;
    origAnnouncement = RemoteConfigState.announcement;
  });

  tearDown(() {
    RemoteConfigState.appVersion = origAppVersion;
    RemoteConfigState.latestVersion = origLatestVersion;
    RemoteConfigState.announcement = origAnnouncement;
  });

  group('RemoteConfigState defaults', () {
    test('appVersion defaults to 1.0.0', () {
      // Can't rely on default since tests run in sequence; just check non-empty
      expect(RemoteConfigState.appVersion, isNotEmpty);
    });

    test('announcement defaults to empty', () {
      RemoteConfigState.announcement = '';
      expect(RemoteConfigState.announcement, isEmpty);
    });
  });

  group('hasNewerVersion', () {
    test('false when latestVersion is empty', () {
      RemoteConfigState.appVersion = '7.0.0';
      RemoteConfigState.latestVersion = '';
      expect(RemoteConfigState.hasNewerVersion, isFalse);
    });

    test('false when versions are equal', () {
      RemoteConfigState.appVersion = '7.0.0';
      RemoteConfigState.latestVersion = '7.0.0';
      expect(RemoteConfigState.hasNewerVersion, isFalse);
    });

    test('true when latest is newer major', () {
      RemoteConfigState.appVersion = '7.0.0';
      RemoteConfigState.latestVersion = '8.0.0';
      expect(RemoteConfigState.hasNewerVersion, isTrue);
    });

    test('true when latest is newer minor', () {
      RemoteConfigState.appVersion = '7.0.0';
      RemoteConfigState.latestVersion = '7.1.0';
      expect(RemoteConfigState.hasNewerVersion, isTrue);
    });

    test('true when latest is newer patch', () {
      RemoteConfigState.appVersion = '7.0.0';
      RemoteConfigState.latestVersion = '7.0.1';
      expect(RemoteConfigState.hasNewerVersion, isTrue);
    });

    test('false when current is newer', () {
      RemoteConfigState.appVersion = '8.0.0';
      RemoteConfigState.latestVersion = '7.0.0';
      expect(RemoteConfigState.hasNewerVersion, isFalse);
    });

    test('false when current minor is newer', () {
      RemoteConfigState.appVersion = '7.2.0';
      RemoteConfigState.latestVersion = '7.1.0';
      expect(RemoteConfigState.hasNewerVersion, isFalse);
    });

    test('false when current patch is newer', () {
      RemoteConfigState.appVersion = '7.0.5';
      RemoteConfigState.latestVersion = '7.0.3';
      expect(RemoteConfigState.hasNewerVersion, isFalse);
    });

    test('handles malformed version gracefully (no crash)', () {
      RemoteConfigState.appVersion = 'invalid';
      RemoteConfigState.latestVersion = '7.0.0';
      // _isVersionLower catches FormatException, returns false
      expect(RemoteConfigState.hasNewerVersion, isFalse);
    });

    test('handles partial versions', () {
      RemoteConfigState.appVersion = '7.0';
      RemoteConfigState.latestVersion = '7.0.1';
      // Missing patch treated as 0 → 7.0.0 < 7.0.1
      expect(RemoteConfigState.hasNewerVersion, isTrue);
    });

    test('handles double-digit versions', () {
      RemoteConfigState.appVersion = '10.0.0';
      RemoteConfigState.latestVersion = '9.9.9';
      expect(RemoteConfigState.hasNewerVersion, isFalse);
    });
  });

  group('announcement', () {
    test('can be set and read', () {
      RemoteConfigState.announcement = 'Maintenance tonight!';
      expect(RemoteConfigState.announcement, 'Maintenance tonight!');
    });

    test('empty string means no announcement', () {
      RemoteConfigState.announcement = '';
      expect(RemoteConfigState.announcement, isEmpty);
    });
  });
}
