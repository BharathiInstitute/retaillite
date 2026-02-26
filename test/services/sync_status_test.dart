import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/services/sync_status_service.dart';

void main() {
  // ── SyncState enum ──

  group('SyncState', () {
    test('has synced value', () {
      expect(SyncState.synced, isNotNull);
    });

    test('has notSynced value', () {
      expect(SyncState.notSynced, isNotNull);
    });

    test('values are distinct', () {
      expect(SyncState.synced, isNot(SyncState.notSynced));
    });
  });

  // ── SyncedItem ──

  group('SyncedItem', () {
    test('hasPendingWrites=true gives notSynced state', () {
      const item = SyncedItem<String>(data: 'test', hasPendingWrites: true);
      expect(item.syncState, SyncState.notSynced);
      expect(item.isSynced, isFalse);
    });

    test('hasPendingWrites=false gives synced state', () {
      const item = SyncedItem<String>(data: 'test', hasPendingWrites: false);
      expect(item.syncState, SyncState.synced);
      expect(item.isSynced, isTrue);
    });

    test('preserves data', () {
      const item = SyncedItem<int>(data: 42, hasPendingWrites: false);
      expect(item.data, 42);
    });
  });

  // ── SyncedList ──

  group('SyncedList', () {
    test('data extracts values from items', () {
      const list = SyncedList<String>(
        items: [
          const SyncedItem(data: 'a', hasPendingWrites: false),
          const SyncedItem(data: 'b', hasPendingWrites: true),
        ],
        snapshotHasPendingWrites: true,
      );
      expect(list.data, ['a', 'b']);
    });

    test('unsyncedCount counts pending items', () {
      const list = SyncedList<String>(
        items: [
          const SyncedItem(data: 'a', hasPendingWrites: false),
          const SyncedItem(data: 'b', hasPendingWrites: true),
          const SyncedItem(data: 'c', hasPendingWrites: true),
        ],
        snapshotHasPendingWrites: true,
      );
      expect(list.unsyncedCount, 2);
    });

    test('allSynced when no pending writes', () {
      const list = SyncedList<String>(
        items: [const SyncedItem(data: 'a', hasPendingWrites: false)],
        snapshotHasPendingWrites: false,
      );
      expect(list.allSynced, isTrue);
    });

    test('not allSynced when snapshot has pending writes', () {
      const list = SyncedList<String>(
        items: [const SyncedItem(data: 'a', hasPendingWrites: false)],
        snapshotHasPendingWrites: true,
      );
      expect(list.allSynced, isFalse);
    });

    test('empty creates empty synced list', () {
      final list = SyncedList.empty<String>();
      expect(list.items, isEmpty);
      expect(list.data, isEmpty);
      expect(list.unsyncedCount, 0);
      expect(list.allSynced, isTrue);
    });
  });

  // ── CollectionSyncStatus ──

  group('CollectionSyncStatus', () {
    test('isSynced when no pending writes', () {
      const status = CollectionSyncStatus(name: 'products', totalDocs: 10);
      expect(status.isSynced, isTrue);
      expect(status.state, SyncState.synced);
    });

    test('not synced when has pending writes', () {
      const status = CollectionSyncStatus(
        name: 'bills',
        totalDocs: 10,
        unsyncedDocs: 3,
        hasPendingWrites: true,
      );
      expect(status.isSynced, isFalse);
      expect(status.state, SyncState.notSynced);
    });

    test('defaults to zero counts and no pending', () {
      const status = CollectionSyncStatus(name: 'test');
      expect(status.totalDocs, 0);
      expect(status.unsyncedDocs, 0);
      expect(status.hasPendingWrites, isFalse);
      expect(status.isSynced, isTrue);
    });
  });

  // ── GlobalSyncStatus ──

  group('GlobalSyncStatus', () {
    test('totalUnsynced aggregates across collections', () {
      const status = GlobalSyncStatus(
        collections: {
          'products': CollectionSyncStatus(
            name: 'products',
            totalDocs: 10,
            unsyncedDocs: 2,
          ),
          'bills': CollectionSyncStatus(
            name: 'bills',
            totalDocs: 5,
            unsyncedDocs: 1,
          ),
        },
        isOnline: true,
      );
      expect(status.totalUnsynced, 3);
    });

    test('allSynced when online and all collections synced', () {
      const status = GlobalSyncStatus(
        collections: {
          'products': CollectionSyncStatus(name: 'products'),
          'bills': CollectionSyncStatus(name: 'bills'),
        },
        isOnline: true,
      );
      expect(status.allSynced, isTrue);
      expect(status.overallState, SyncState.synced);
    });

    test('not allSynced when offline', () {
      const status = GlobalSyncStatus(
        collections: {'products': CollectionSyncStatus(name: 'products')},
        isOnline: false,
      );
      expect(status.allSynced, isFalse);
      expect(status.overallState, SyncState.notSynced);
    });

    test('not allSynced when any collection has pending writes', () {
      const status = GlobalSyncStatus(
        collections: {
          'products': CollectionSyncStatus(name: 'products'),
          'bills': CollectionSyncStatus(name: 'bills', hasPendingWrites: true),
        },
        isOnline: true,
      );
      expect(status.allSynced, isFalse);
    });

    test('empty has no collections and is online', () {
      expect(GlobalSyncStatus.empty.collections, isEmpty);
      expect(GlobalSyncStatus.empty.isOnline, isTrue);
      expect(GlobalSyncStatus.empty.allSynced, isTrue);
      expect(GlobalSyncStatus.empty.totalUnsynced, 0);
    });

    test('totalUnsynced is 0 when all synced', () {
      const status = GlobalSyncStatus(
        collections: {
          'products': CollectionSyncStatus(name: 'products', totalDocs: 50),
        },
        isOnline: true,
      );
      expect(status.totalUnsynced, 0);
    });
  });
}
