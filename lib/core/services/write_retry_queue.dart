/// Write Retry Queue — queues failed Firestore writes for automatic retry.
///
/// When a Firestore write fails (e.g., due to offline/network error), the
/// operation is serialized to SharedPreferences. When connectivity is
/// restored, the queue is flushed with exponential backoff.
///
/// Queue items: {collection, docId, data, operation, attempts, lastAttempt}
/// Max retries: 5 (with exponential backoff: 1s→2s→4s→8s→16s)
/// Dead-letter: after 5 failures, logged to ErrorLoggingService and discarded.
library;

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:retaillite/core/services/connectivity_service.dart';
import 'package:retaillite/core/services/error_logging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported write operations
enum WriteOperation { set, update, delete }

/// A queued write operation
class QueuedWrite {
  QueuedWrite({
    required this.collection,
    required this.docId,
    required this.operation,
    this.data,
    this.attempts = 0,
    DateTime? lastAttempt,
  }) : lastAttempt = lastAttempt ?? DateTime.now();

  final String collection;
  final String docId;
  final WriteOperation operation;
  final Map<String, dynamic>? data;
  int attempts;
  DateTime lastAttempt;

  Map<String, dynamic> toJson() => {
    'collection': collection,
    'docId': docId,
    'operation': operation.name,
    'data': data,
    'attempts': attempts,
    'lastAttempt': lastAttempt.toIso8601String(),
  };

  factory QueuedWrite.fromJson(Map<String, dynamic> json) => QueuedWrite(
    collection: json['collection'] as String,
    docId: json['docId'] as String,
    operation: WriteOperation.values.byName(json['operation'] as String),
    data: json['data'] as Map<String, dynamic>?,
    attempts: json['attempts'] as int? ?? 0,
    lastAttempt:
        DateTime.tryParse(json['lastAttempt'] as String? ?? '') ??
        DateTime.now(),
  );
}

class WriteRetryQueue {
  static const String _storageKey = 'write_retry_queue';
  static const int _maxRetries = 5;

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static SharedPreferences? _prefs;
  static StreamSubscription<dynamic>? _connectivitySub;
  static bool _flushing = false;

  /// Initialize the queue and start listening for connectivity changes.
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // Flush on connectivity restore
    _connectivitySub = ConnectivityService.statusStream.listen((status) {
      if (status == ConnectivityStatus.online) {
        flush();
      }
    });

    // Try flushing any leftover items from previous session
    unawaited(flush());
  }

  /// Number of pending writes in the queue.
  static int get pendingCount => _loadQueue().length;

  /// Enqueue a failed write for later retry.
  static Future<void> enqueue({
    required String collection,
    required String docId,
    required WriteOperation operation,
    Map<String, dynamic>? data,
  }) async {
    final queue = _loadQueue();
    queue.add(
      QueuedWrite(
        collection: collection,
        docId: docId,
        operation: operation,
        data: data,
      ),
    );
    await _saveQueue(queue);
    debugPrint(
      '📝 WriteRetryQueue: Enqueued ${operation.name} for $collection/$docId '
      '(${queue.length} pending)',
    );
  }

  /// Attempt to flush all queued writes with exponential backoff.
  static Future<void> flush() async {
    if (_flushing) return;
    _flushing = true;

    try {
      final queue = _loadQueue();
      if (queue.isEmpty) return;

      debugPrint(
        '📝 WriteRetryQueue: Flushing ${queue.length} pending write(s)...',
      );

      final remaining = <QueuedWrite>[];
      for (final item in queue) {
        // Exponential backoff check
        final backoffMs = (1 << item.attempts) * 1000; // 1s, 2s, 4s, 8s, 16s
        final elapsed = DateTime.now()
            .difference(item.lastAttempt)
            .inMilliseconds;
        if (elapsed < backoffMs) {
          remaining.add(item);
          continue;
        }

        try {
          final docRef = _firestore.collection(item.collection).doc(item.docId);
          switch (item.operation) {
            case WriteOperation.set:
              await docRef.set(item.data ?? {}, SetOptions(merge: true));
            case WriteOperation.update:
              await docRef.update(item.data ?? {});
            case WriteOperation.delete:
              await docRef.delete();
          }
          debugPrint(
            '✅ WriteRetryQueue: ${item.operation.name} ${item.collection}/${item.docId} succeeded',
          );
        } catch (e) {
          item.attempts++;
          item.lastAttempt = DateTime.now();

          if (item.attempts >= _maxRetries) {
            // Dead-letter: log and discard
            debugPrint(
              '💀 WriteRetryQueue: Dead-letter after $_maxRetries retries: '
              '${item.operation.name} ${item.collection}/${item.docId}',
            );
            ErrorLoggingService.logError(
              error:
                  'WriteRetryQueue dead-letter: ${item.operation.name} '
                  '${item.collection}/${item.docId} after $_maxRetries retries. '
                  'Last error: $e',
              metadata: {
                'collection': item.collection,
                'docId': item.docId,
                'operation': item.operation.name,
                'attempts': item.attempts,
              },
            ).ignore();
          } else {
            remaining.add(item);
          }
        }
      }

      await _saveQueue(remaining);
      if (remaining.isNotEmpty) {
        debugPrint(
          '📝 WriteRetryQueue: ${remaining.length} item(s) still pending',
        );
      }
    } finally {
      _flushing = false;
    }
  }

  /// Dispose resources.
  static void dispose() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  // ── Internal ──

  static List<QueuedWrite> _loadQueue() {
    final json = _prefs?.getString(_storageKey);
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List;
      return list
          .map((e) => QueuedWrite.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('⚠️ WriteRetryQueue: Failed to parse queue: $e');
      return [];
    }
  }

  static Future<void> _saveQueue(List<QueuedWrite> queue) async {
    final json = jsonEncode(queue.map((e) => e.toJson()).toList());
    await _prefs?.setString(_storageKey, json);
  }
}
