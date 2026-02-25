/// Sync status service — tracks which data is synced to cloud vs local-only
///
/// Uses Firestore snapshot metadata (hasPendingWrites) for 2-state sync:
///   ✅ Synced — confirmed on server
///   ⚠️ Not Synced — local write not yet confirmed
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/services/connectivity_service.dart';

// ── Sync State ──

/// Simple 2-state sync
enum SyncState { synced, notSynced }

/// Wraps a single data item with its sync status
class SyncedItem<T> {
  final T data;
  final bool hasPendingWrites;

  const SyncedItem({required this.data, required this.hasPendingWrites});

  SyncState get syncState =>
      hasPendingWrites ? SyncState.notSynced : SyncState.synced;

  bool get isSynced => !hasPendingWrites;
}

/// Wraps a list of items with collection-level sync status
class SyncedList<T> {
  final List<SyncedItem<T>> items;
  final bool snapshotHasPendingWrites;

  const SyncedList({
    required this.items,
    required this.snapshotHasPendingWrites,
  });

  /// Convenience: get just the data without sync info
  List<T> get data => items.map((i) => i.data).toList();

  /// Number of unsynced items
  int get unsyncedCount => items.where((i) => i.hasPendingWrites).length;

  /// Whether everything is synced
  bool get allSynced => !snapshotHasPendingWrites;

  /// Empty synced list
  static SyncedList<T> empty<T>() =>
      SyncedList<T>(items: [], snapshotHasPendingWrites: false);
}

// ── Per-Collection Status ──

class CollectionSyncStatus {
  final String name;
  final int totalDocs;
  final int unsyncedDocs;
  final bool hasPendingWrites;

  const CollectionSyncStatus({
    required this.name,
    this.totalDocs = 0,
    this.unsyncedDocs = 0,
    this.hasPendingWrites = false,
  });

  SyncState get state =>
      hasPendingWrites ? SyncState.notSynced : SyncState.synced;

  bool get isSynced => !hasPendingWrites;
}

// ── Global Status ──

class GlobalSyncStatus {
  final Map<String, CollectionSyncStatus> collections;
  final bool isOnline;

  const GlobalSyncStatus({required this.collections, required this.isOnline});

  int get totalUnsynced =>
      collections.values.fold(0, (sum, c) => sum + c.unsyncedDocs);

  bool get allSynced => isOnline && collections.values.every((c) => c.isSynced);

  SyncState get overallState =>
      allSynced ? SyncState.synced : SyncState.notSynced;

  static const empty = GlobalSyncStatus(collections: {}, isOnline: true);
}

// ── Service ──

class SyncStatusService {
  SyncStatusService._();

  static final _controller = StreamController<GlobalSyncStatus>.broadcast();
  static final Map<String, CollectionSyncStatus> _statuses = {};

  static Stream<GlobalSyncStatus> get statusStream => _controller.stream;

  /// Update status for a specific collection
  static void updateCollection(
    String collection, {
    required int totalDocs,
    required int unsyncedDocs,
    required bool hasPendingWrites,
  }) {
    _statuses[collection] = CollectionSyncStatus(
      name: collection,
      totalDocs: totalDocs,
      unsyncedDocs: unsyncedDocs,
      hasPendingWrites: hasPendingWrites,
    );
    _emit();
  }

  static void _emit() {
    _controller.add(
      GlobalSyncStatus(
        collections: Map.unmodifiable(_statuses),
        isOnline: ConnectivityService.isOnline,
      ),
    );
  }

  /// Get current status synchronously
  static GlobalSyncStatus get current => GlobalSyncStatus(
    collections: Map.unmodifiable(_statuses),
    isOnline: ConnectivityService.isOnline,
  );

  static void dispose() {
    _controller.close();
  }
}

// ── Riverpod Providers ──

/// Global sync status provider
final globalSyncStatusProvider = StreamProvider<GlobalSyncStatus>((ref) {
  // Also react to connectivity changes
  ref.watch(connectivityProvider);
  return SyncStatusService.statusStream;
});

/// Simple: is everything synced?
final isAllSyncedProvider = Provider<bool>((ref) {
  final syncStatus = ref.watch(globalSyncStatusProvider);
  return syncStatus.when(
    data: (status) => status.allSynced,
    loading: () => true,
    error: (_, _) => true,
  );
});

/// Total unsynced count
final unsyncedCountProvider = Provider<int>((ref) {
  final syncStatus = ref.watch(globalSyncStatusProvider);
  return syncStatus.when(
    data: (status) => status.totalUnsynced,
    loading: () => 0,
    error: (_, _) => 0,
  );
});
