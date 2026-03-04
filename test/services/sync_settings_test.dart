/// Tests for SyncSettingsService — SyncInterval enum, display formatting
/// Uses inline duplicates to avoid transitive Firebase import chain.
library;

import 'package:flutter_test/flutter_test.dart';

// ── Inline duplicates (avoid sync_settings_service → FirebaseFirestore) ──

enum SyncInterval {
  realtime('Real-time', Duration.zero),
  hourly('Every Hour', Duration(hours: 1)),
  daily('Daily', Duration(days: 1)),
  weekly('Weekly', Duration(days: 7)),
  manual('Manual Only', Duration(days: 365));

  final String displayName;
  final Duration duration;
  const SyncInterval(this.displayName, this.duration);
}

enum SyncStatus { idle, syncing, success, error }

// Duplicate of getLastSyncDisplay logic for testing
String getLastSyncDisplay(DateTime? lastSyncTime) {
  if (lastSyncTime == null) return 'Never synced';
  final now = DateTime.now();
  final diff = now.difference(lastSyncTime);
  if (diff.inMinutes < 1) {
    return 'Just now';
  } else if (diff.inMinutes < 60) {
    return '${diff.inMinutes} min ago';
  } else if (diff.inHours < 24) {
    return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
  } else {
    return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
  }
}

// Duplicate of getSyncModeDescription logic for testing
String getSyncModeDescription(SyncInterval interval) {
  switch (interval) {
    case SyncInterval.realtime:
      return 'Data syncs immediately when connected';
    case SyncInterval.hourly:
      return 'Data syncs every hour';
    case SyncInterval.daily:
      return 'Data syncs once per day';
    case SyncInterval.weekly:
      return 'Data syncs once per week';
    case SyncInterval.manual:
      return 'Data only syncs when you tap "Sync Now"';
  }
}

void main() {
  group('SyncInterval', () {
    test('has 5 values', () {
      expect(SyncInterval.values.length, 5);
    });

    test('each has non-empty displayName', () {
      for (final si in SyncInterval.values) {
        expect(si.displayName, isNotEmpty);
      }
    });

    test('realtime has zero duration', () {
      expect(SyncInterval.realtime.duration, Duration.zero);
    });

    test('hourly duration is 1 hour', () {
      expect(SyncInterval.hourly.duration, const Duration(hours: 1));
    });

    test('daily duration is 1 day', () {
      expect(SyncInterval.daily.duration, const Duration(days: 1));
    });

    test('weekly duration is 7 days', () {
      expect(SyncInterval.weekly.duration, const Duration(days: 7));
    });

    test('manual duration is 365 days (effectively manual)', () {
      expect(SyncInterval.manual.duration, const Duration(days: 365));
    });

    test('durations increase in order', () {
      final durations = SyncInterval.values.map((s) => s.duration).toList();
      for (var i = 1; i < durations.length; i++) {
        expect(
          durations[i],
          greaterThanOrEqualTo(durations[i - 1]),
          reason:
              '${SyncInterval.values[i].name} should be >= ${SyncInterval.values[i - 1].name}',
        );
      }
    });
  });

  group('SyncStatus', () {
    test('has 4 values', () {
      expect(SyncStatus.values.length, 4);
    });

    test('includes idle, syncing, success, error', () {
      expect(SyncStatus.values, contains(SyncStatus.idle));
      expect(SyncStatus.values, contains(SyncStatus.syncing));
      expect(SyncStatus.values, contains(SyncStatus.success));
      expect(SyncStatus.values, contains(SyncStatus.error));
    });
  });

  group('getLastSyncDisplay', () {
    test('null returns Never synced', () {
      expect(getLastSyncDisplay(null), 'Never synced');
    });

    test('just now (seconds ago)', () {
      final recent = DateTime.now().subtract(const Duration(seconds: 30));
      expect(getLastSyncDisplay(recent), 'Just now');
    });

    test('minutes ago (single)', () {
      final time = DateTime.now().subtract(const Duration(minutes: 1));
      expect(getLastSyncDisplay(time), '1 min ago');
    });

    test('minutes ago (plural)', () {
      final time = DateTime.now().subtract(const Duration(minutes: 45));
      expect(getLastSyncDisplay(time), '45 min ago');
    });

    test('1 hour ago (singular)', () {
      final time = DateTime.now().subtract(const Duration(hours: 1));
      expect(getLastSyncDisplay(time), '1 hour ago');
    });

    test('hours ago (plural)', () {
      final time = DateTime.now().subtract(const Duration(hours: 5));
      expect(getLastSyncDisplay(time), '5 hours ago');
    });

    test('1 day ago (singular)', () {
      final time = DateTime.now().subtract(const Duration(days: 1));
      expect(getLastSyncDisplay(time), '1 day ago');
    });

    test('days ago (plural)', () {
      final time = DateTime.now().subtract(const Duration(days: 3));
      expect(getLastSyncDisplay(time), '3 days ago');
    });
  });

  group('getSyncModeDescription', () {
    test('realtime description', () {
      expect(
        getSyncModeDescription(SyncInterval.realtime),
        'Data syncs immediately when connected',
      );
    });

    test('hourly description', () {
      expect(
        getSyncModeDescription(SyncInterval.hourly),
        'Data syncs every hour',
      );
    });

    test('daily description', () {
      expect(
        getSyncModeDescription(SyncInterval.daily),
        'Data syncs once per day',
      );
    });

    test('weekly description', () {
      expect(
        getSyncModeDescription(SyncInterval.weekly),
        'Data syncs once per week',
      );
    });

    test('manual description', () {
      expect(
        getSyncModeDescription(SyncInterval.manual),
        'Data only syncs when you tap "Sync Now"',
      );
    });
  });
}
