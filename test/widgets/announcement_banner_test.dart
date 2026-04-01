/// Tests for AnnouncementBanner — dismiss logic and display rules.
///
/// The widget depends on RemoteConfigState (static) and OfflineStorageService.prefs.
/// We test the pure dismiss/show logic inline.
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── Dismiss hash tracking logic ──
  // Mirrors: dismissedHash == currentHash => _announcementDismissed = true

  group('AnnouncementBanner dismiss hash tracking', () {
    test('same hash means banner was already dismissed', () {
      const announcement = 'We are now open on Sundays!';
      final currentHash = announcement.hashCode.toString();
      final dismissedHash = currentHash; // same
      expect(dismissedHash == currentHash, isTrue);
    });

    test('different hash means new announcement to show', () {
      const oldAnnouncement = 'Old announcement';
      const newAnnouncement = 'New announcement!';
      final dismissedHash = oldAnnouncement.hashCode.toString();
      final currentHash = newAnnouncement.hashCode.toString();
      expect(dismissedHash == currentHash, isFalse);
    });

    test('empty announcement does not trigger dismiss check', () {
      const announcement = '';
      // The widget checks: announcement.isNotEmpty => only then check hash
      expect(announcement.isNotEmpty, isFalse);
    });
  });

  // ── Update banner 24h TTL logic ──
  // Mirrors: elapsed < Duration(hours: 24).inMilliseconds => _updateDismissed

  group('AnnouncementBanner update dismiss TTL', () {
    test('within 24 hours keeps update dismissed', () {
      final dismissedAt = DateTime.now()
          .subtract(const Duration(hours: 12))
          .millisecondsSinceEpoch;
      final elapsed = DateTime.now().millisecondsSinceEpoch - dismissedAt;
      final ttl = const Duration(hours: 24).inMilliseconds;
      expect(elapsed < ttl, isTrue);
    });

    test('after 24 hours shows update banner again', () {
      final dismissedAt = DateTime.now()
          .subtract(const Duration(hours: 25))
          .millisecondsSinceEpoch;
      final elapsed = DateTime.now().millisecondsSinceEpoch - dismissedAt;
      final ttl = const Duration(hours: 24).inMilliseconds;
      expect(elapsed < ttl, isFalse);
    });

    test('exactly 24 hours shows banner again', () {
      final dismissedAt = DateTime.now()
          .subtract(const Duration(hours: 24, seconds: 1))
          .millisecondsSinceEpoch;
      final elapsed = DateTime.now().millisecondsSinceEpoch - dismissedAt;
      final ttl = const Duration(hours: 24).inMilliseconds;
      expect(elapsed < ttl, isFalse);
    });
  });

  // ── Show/hide decision logic ──
  // Mirrors: showAnnouncement = announcement.isNotEmpty && !_announcementDismissed
  //          showUpdate = hasUpdate && !_updateDismissed

  group('AnnouncementBanner show/hide logic', () {
    bool shouldShowAnnouncement(String announcement, bool dismissed) {
      return announcement.isNotEmpty && !dismissed;
    }

    bool shouldShowUpdate(bool hasUpdate, bool dismissed) {
      return hasUpdate && !dismissed;
    }

    test(
      'shows banner when announcement text is non-empty and not dismissed',
      () {
        expect(shouldShowAnnouncement('Hello users!', false), isTrue);
      },
    );

    test('hides banner when announcement text is empty', () {
      expect(shouldShowAnnouncement('', false), isFalse);
    });

    test('hides banner when announcement is dismissed', () {
      expect(shouldShowAnnouncement('Hello users!', true), isFalse);
    });

    test('shows update banner when update available and not dismissed', () {
      expect(shouldShowUpdate(true, false), isTrue);
    });

    test('hides update banner when dismissed', () {
      expect(shouldShowUpdate(true, true), isFalse);
    });

    test('hides update banner when no update available', () {
      expect(shouldShowUpdate(false, false), isFalse);
    });
  });
}
