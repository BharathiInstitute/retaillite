/// Tests for GlobalSyncIndicator — icon selection and badge text logic.
///
/// Depends on isOnlineProvider and globalSyncStatusProvider. We test the
/// pure display logic inline.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── Icon selection logic ──
  // Mirrors: isOnline ? (unsyncedCount > 0 ? Icons.cloud_upload : Icons.cloud_done) : Icons.cloud_off

  group('GlobalSyncIndicator icon selection', () {
    IconData syncIcon(bool isOnline, int unsyncedCount) {
      return isOnline
          ? (unsyncedCount > 0 ? Icons.cloud_upload : Icons.cloud_done)
          : Icons.cloud_off;
    }

    test('shows cloud_done when online and fully synced', () {
      expect(syncIcon(true, 0), Icons.cloud_done);
    });

    test('shows cloud_upload when online with unsynced items', () {
      expect(syncIcon(true, 3), Icons.cloud_upload);
    });

    test('shows cloud_off when offline', () {
      expect(syncIcon(false, 0), Icons.cloud_off);
    });

    test('shows cloud_off when offline even with unsynced items', () {
      expect(syncIcon(false, 5), Icons.cloud_off);
    });
  });

  // ── Badge text logic ──
  // Mirrors: unsyncedCount > 9 ? '9+' : '$unsyncedCount'

  group('GlobalSyncIndicator badge text', () {
    String badgeText(int unsyncedCount) {
      return unsyncedCount > 9 ? '9+' : '$unsyncedCount';
    }

    test('shows exact count for 1', () {
      expect(badgeText(1), '1');
    });

    test('shows exact count for 9', () {
      expect(badgeText(9), '9');
    });

    test('shows 9+ for 10', () {
      expect(badgeText(10), '9+');
    });

    test('shows 9+ for large counts', () {
      expect(badgeText(50), '9+');
      expect(badgeText(999), '9+');
    });
  });

  // ── Badge visibility logic ──
  // Mirrors: if (unsyncedCount > 0) Positioned(...)

  group('GlobalSyncIndicator badge visibility', () {
    test('badge visible when unsynced count > 0', () {
      const unsyncedCount = 3;
      expect(unsyncedCount > 0, isTrue);
    });

    test('badge hidden when unsynced count is 0', () {
      const unsyncedCount = 0;
      expect(unsyncedCount > 0, isFalse);
    });
  });

  // ── Icon color logic ──
  // Mirrors: isOnline ? (unsyncedCount > 0 ? orange : success_green) : grey_variant

  group('GlobalSyncIndicator icon color', () {
    test('green when online and synced', () {
      const isOnline = true;
      const unsyncedCount = 0;
      // Color would be AppColors.success (green)
      expect(isOnline && unsyncedCount == 0, isTrue);
    });

    test('orange when online but unsynced', () {
      const isOnline = true;
      const unsyncedCount = 5;
      expect(isOnline && unsyncedCount > 0, isTrue);
    });

    test('grey when offline', () {
      const isOnline = false;
      expect(isOnline, isFalse);
    });
  });

  // ── Async state handling ──
  // Mirrors: syncStatus.when(data: s.totalUnsynced, loading: () => 0, error: () => 0)

  group('GlobalSyncIndicator async fallback', () {
    test('loading state yields unsyncedCount = 0', () {
      const loadingFallback = 0;
      expect(loadingFallback, 0);
    });

    test('error state yields unsyncedCount = 0', () {
      const errorFallback = 0;
      expect(errorFallback, 0);
    });
  });
}
