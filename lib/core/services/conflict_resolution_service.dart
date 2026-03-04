/// Multi-device conflict resolution service.
///
/// Detects and resolves conflicting writes when the same user
/// edits data from multiple devices simultaneously.
///
/// Strategy: Last-Write-Wins with conflict notification.
/// - Each write includes an `updatedAt` timestamp and `deviceId`
/// - Before saving, compare local `updatedAt` with server version
/// - If server is newer, warn user and offer merge/overwrite/discard
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';

/// Result of a conflict check
enum ConflictResult {
  /// No conflict — safe to write
  noConflict,

  /// Server version is newer — data was modified on another device
  serverNewer,

  /// Local version is newer — safe to write (shouldn't normally happen)
  localNewer,

  /// No server document found — new document, safe to create
  notFound,
}

/// Conflict resolution choice
enum ConflictAction {
  /// Overwrite server data with local changes
  overwrite,

  /// Discard local changes, keep server version
  discard,

  /// Merge (keep server data, apply non-conflicting local changes)
  merge,
}

/// Service for detecting and resolving multi-device conflicts
class ConflictResolutionService {
  /// Device ID for identifying which device made a change
  static String get deviceId {
    var id = OfflineStorageService.getSetting<String>('device_id');
    if (id == null || id.isEmpty) {
      id = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
      OfflineStorageService.saveSetting('device_id', id);
    }
    return id;
  }

  /// Check if a document has been modified since our last read
  static Future<ConflictResult> checkConflict({
    required DocumentReference docRef,
    required DateTime? localUpdatedAt,
  }) async {
    try {
      final serverDoc = await docRef.get();

      if (!serverDoc.exists) return ConflictResult.notFound;

      final serverData = serverDoc.data() as Map<String, dynamic>?;
      if (serverData == null) return ConflictResult.notFound;

      final serverTimestamp = serverData['updatedAt'];
      if (serverTimestamp == null) return ConflictResult.noConflict;

      final serverUpdatedAt = (serverTimestamp is Timestamp)
          ? serverTimestamp.toDate()
          : DateTime.now();

      if (localUpdatedAt == null) return ConflictResult.serverNewer;

      if (serverUpdatedAt.isAfter(localUpdatedAt)) {
        // Check if it's the same device (not a true conflict)
        final serverDeviceId = serverData['_lastDeviceId'] as String?;
        if (serverDeviceId == deviceId) return ConflictResult.noConflict;

        return ConflictResult.serverNewer;
      }

      return ConflictResult.noConflict;
    } catch (e) {
      debugPrint('⚠️ Conflict check failed: $e');
      return ConflictResult.noConflict; // Fail-open: allow write
    }
  }

  /// Write data with conflict metadata
  static Future<void> writeWithMetadata(
    DocumentReference docRef,
    Map<String, dynamic> data, {
    bool merge = true,
  }) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    data['_lastDeviceId'] = deviceId;

    if (merge) {
      await docRef.set(data, SetOptions(merge: true));
    } else {
      await docRef.set(data);
    }
  }

  /// Update data with conflict metadata
  static Future<void> updateWithMetadata(
    DocumentReference docRef,
    Map<String, dynamic> data,
  ) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    data['_lastDeviceId'] = deviceId;
    await docRef.update(data);
  }
}
