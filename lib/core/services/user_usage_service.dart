/// User Usage Service - Track backend usage per user
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase pricing constants (USD)
class FirebasePricing {
  static const double firestoreReadsPer100k = 0.06;
  static const double firestoreWritesPer100k = 0.18;
  static const double firestoreDeletesPer100k = 0.02;
  static const double storagePerGB = 0.026;
  static const double functionCallsPerMillion = 0.40;
  static const double networkEgressPerGB = 0.12;
  static const double firebaseStoragePerGB = 0.026;
  static const double storageDownloadPerGB = 0.12;
}

/// Usage data for a single user
class UserUsage {
  final String odUserId;
  final String? email;
  final bool isAdmin;
  final int firestoreReads;
  final int firestoreWrites;
  final int firestoreDeletes;
  final int storageBytes;
  final int functionCalls;
  final int networkEgressBytes;
  final int storageUploadBytes;
  final int storageDownloadBytes;
  final DateTime lastUpdated;
  final DateTime periodStart;

  UserUsage({
    required this.odUserId,
    this.email,
    this.isAdmin = false,
    this.firestoreReads = 0,
    this.firestoreWrites = 0,
    this.firestoreDeletes = 0,
    this.storageBytes = 0,
    this.functionCalls = 0,
    this.networkEgressBytes = 0,
    this.storageUploadBytes = 0,
    this.storageDownloadBytes = 0,
    required this.lastUpdated,
    required this.periodStart,
  });

  /// Calculate estimated cost in USD
  double get estimatedCost {
    final readsCost =
        (firestoreReads / 100000) * FirebasePricing.firestoreReadsPer100k;
    final writesCost =
        (firestoreWrites / 100000) * FirebasePricing.firestoreWritesPer100k;
    final deletesCost =
        (firestoreDeletes / 100000) * FirebasePricing.firestoreDeletesPer100k;
    final storageCost =
        (storageBytes / (1024 * 1024 * 1024)) * FirebasePricing.storagePerGB;
    final functionsCost =
        (functionCalls / 1000000) * FirebasePricing.functionCallsPerMillion;
    final networkCost =
        (networkEgressBytes / (1024 * 1024 * 1024)) *
        FirebasePricing.networkEgressPerGB;
    final storageUploadCost =
        (storageUploadBytes / (1024 * 1024 * 1024)) *
        FirebasePricing.firebaseStoragePerGB;
    final storageDownloadCost =
        (storageDownloadBytes / (1024 * 1024 * 1024)) *
        FirebasePricing.storageDownloadPerGB;

    return readsCost +
        writesCost +
        deletesCost +
        storageCost +
        functionsCost +
        networkCost +
        storageUploadCost +
        storageDownloadCost;
  }

  /// Cost breakdown by category
  Map<String, double> get costBreakdown {
    return {
      'reads':
          (firestoreReads / 100000) * FirebasePricing.firestoreReadsPer100k,
      'writes':
          (firestoreWrites / 100000) * FirebasePricing.firestoreWritesPer100k,
      'deletes':
          (firestoreDeletes / 100000) * FirebasePricing.firestoreDeletesPer100k,
      'storage':
          (storageBytes / (1024 * 1024 * 1024)) * FirebasePricing.storagePerGB,
      'functions':
          (functionCalls / 1000000) * FirebasePricing.functionCallsPerMillion,
      'bandwidth':
          (networkEgressBytes / (1024 * 1024 * 1024)) *
          FirebasePricing.networkEgressPerGB,
      'fileStorage':
          (storageUploadBytes / (1024 * 1024 * 1024)) *
          FirebasePricing.firebaseStoragePerGB,
      'downloads':
          (storageDownloadBytes / (1024 * 1024 * 1024)) *
          FirebasePricing.storageDownloadPerGB,
    };
  }

  /// Get storage in MB
  double get storageMB => storageBytes / (1024 * 1024);

  Map<String, dynamic> toFirestore() => {
    'userId': odUserId,
    'email': email,
    'isAdmin': isAdmin,
    'firestoreReads': firestoreReads,
    'firestoreWrites': firestoreWrites,
    'firestoreDeletes': firestoreDeletes,
    'storageBytes': storageBytes,
    'functionCalls': functionCalls,
    'networkEgressBytes': networkEgressBytes,
    'storageUploadBytes': storageUploadBytes,
    'storageDownloadBytes': storageDownloadBytes,
    'lastUpdated': Timestamp.fromDate(lastUpdated),
    'periodStart': Timestamp.fromDate(periodStart),
    'estimatedCost': estimatedCost,
  };

  factory UserUsage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserUsage(
      odUserId: (data['userId'] as String?) ?? doc.id,
      email: data['email'] as String?,
      isAdmin: (data['isAdmin'] as bool?) ?? false,
      firestoreReads: (data['firestoreReads'] as int?) ?? 0,
      firestoreWrites: (data['firestoreWrites'] as int?) ?? 0,
      firestoreDeletes: (data['firestoreDeletes'] as int?) ?? 0,
      storageBytes: (data['storageBytes'] as int?) ?? 0,
      functionCalls: (data['functionCalls'] as int?) ?? 0,
      networkEgressBytes: (data['networkEgressBytes'] as int?) ?? 0,
      storageUploadBytes: (data['storageUploadBytes'] as int?) ?? 0,
      storageDownloadBytes: (data['storageDownloadBytes'] as int?) ?? 0,
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      periodStart:
          (data['periodStart'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  UserUsage copyWith({
    int? firestoreReads,
    int? firestoreWrites,
    int? firestoreDeletes,
    int? storageBytes,
    int? functionCalls,
    int? networkEgressBytes,
    int? storageUploadBytes,
    int? storageDownloadBytes,
  }) {
    return UserUsage(
      odUserId: odUserId,
      email: email,
      isAdmin: isAdmin,
      firestoreReads: firestoreReads ?? this.firestoreReads,
      firestoreWrites: firestoreWrites ?? this.firestoreWrites,
      firestoreDeletes: firestoreDeletes ?? this.firestoreDeletes,
      storageBytes: storageBytes ?? this.storageBytes,
      functionCalls: functionCalls ?? this.functionCalls,
      networkEgressBytes: networkEgressBytes ?? this.networkEgressBytes,
      storageUploadBytes: storageUploadBytes ?? this.storageUploadBytes,
      storageDownloadBytes: storageDownloadBytes ?? this.storageDownloadBytes,
      lastUpdated: DateTime.now(),
      periodStart: periodStart,
    );
  }
}

/// Service for tracking user backend usage
class UserUsageService {
  UserUsageService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Super admin emails (synced with firestore.rules and super_admin_provider)
  static const List<String> _adminEmails = [
    'kehsaram001@gmail.com',
    'admin@retaillite.com',
    'bharathiinstitute1@gmail.com',
    'bharahiinstitute1@gmail.com',
    'shivamsingh8556@gmail.com',
    'admin@lite.app',
    'kehsihba@gmail.com',
  ];

  /// In-memory counters for batching
  static int _pendingReads = 0;
  static int _pendingWrites = 0;
  static int _pendingDeletes = 0;
  static int _pendingFunctionCalls = 0;
  static int _pendingNetworkBytes = 0;
  static int _pendingStorageUploadBytes = 0;
  static int _pendingStorageDownloadBytes = 0;
  static DateTime? _lastFlush;

  /// Track a Firestore read operation
  static void trackRead({int count = 1}) {
    _pendingReads += count;
    _maybeFlush();
  }

  /// Track a Firestore write operation
  static void trackWrite({int count = 1}) {
    _pendingWrites += count;
    _maybeFlush();
  }

  /// Track a Firestore delete operation
  static void trackDelete({int count = 1}) {
    _pendingDeletes += count;
    _maybeFlush();
  }

  /// Track a Cloud Function call
  static void trackFunctionCall({int count = 1}) {
    _pendingFunctionCalls += count;
    _maybeFlush();
  }

  /// Track network egress bytes (bandwidth)
  static void trackNetworkEgress({required int bytes}) {
    _pendingNetworkBytes += bytes;
    _maybeFlush();
  }

  /// Track Firebase Storage upload
  static void trackStorageUpload({required int bytes}) {
    _pendingStorageUploadBytes += bytes;
    _maybeFlush();
  }

  /// Track Firebase Storage download
  static void trackStorageDownload({required int bytes}) {
    _pendingStorageDownloadBytes += bytes;
    _maybeFlush();
  }

  /// Maybe flush pending counts to Firestore
  static void _maybeFlush() {
    final now = DateTime.now();

    final totalPending =
        _pendingReads +
        _pendingWrites +
        _pendingDeletes +
        _pendingFunctionCalls;
    // Flush every 30 seconds or if counts are significant
    if (_lastFlush == null ||
        now.difference(_lastFlush!).inSeconds >= 30 ||
        totalPending >= 50) {
      _flushUsage();
    }
  }

  /// Flush pending usage to Firestore
  static Future<void> _flushUsage() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    if (_pendingReads == 0 &&
        _pendingWrites == 0 &&
        _pendingDeletes == 0 &&
        _pendingFunctionCalls == 0 &&
        _pendingNetworkBytes == 0 &&
        _pendingStorageUploadBytes == 0 &&
        _pendingStorageDownloadBytes == 0) {
      return;
    }

    final reads = _pendingReads;
    final writes = _pendingWrites;
    final deletes = _pendingDeletes;
    final fnCalls = _pendingFunctionCalls;
    final netBytes = _pendingNetworkBytes;
    final uploadBytes = _pendingStorageUploadBytes;
    final downloadBytes = _pendingStorageDownloadBytes;

    // Reset counters immediately
    _pendingReads = 0;
    _pendingWrites = 0;
    _pendingDeletes = 0;
    _pendingFunctionCalls = 0;
    _pendingNetworkBytes = 0;
    _pendingStorageUploadBytes = 0;
    _pendingStorageDownloadBytes = 0;
    _lastFlush = DateTime.now();

    try {
      final email = _auth.currentUser?.email?.toLowerCase() ?? '';
      final isAdmin = _adminEmails.contains(email);

      final docRef = _firestore.collection('user_usage').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        if (doc.exists) {
          // Update existing
          final updates = <String, dynamic>{
            'lastUpdated': FieldValue.serverTimestamp(),
          };
          if (reads > 0)
            updates['firestoreReads'] = FieldValue.increment(reads);
          if (writes > 0)
            updates['firestoreWrites'] = FieldValue.increment(writes);
          if (deletes > 0)
            updates['firestoreDeletes'] = FieldValue.increment(deletes);
          if (fnCalls > 0)
            updates['functionCalls'] = FieldValue.increment(fnCalls);
          if (netBytes > 0)
            updates['networkEgressBytes'] = FieldValue.increment(netBytes);
          if (uploadBytes > 0)
            updates['storageUploadBytes'] = FieldValue.increment(uploadBytes);
          if (downloadBytes > 0)
            updates['storageDownloadBytes'] = FieldValue.increment(
              downloadBytes,
            );
          transaction.update(docRef, updates);
        } else {
          // Create new
          final now = DateTime.now();
          final periodStart = DateTime(now.year, now.month);

          transaction.set(docRef, {
            'userId': userId,
            'email': email,
            'isAdmin': isAdmin,
            'firestoreReads': reads,
            'firestoreWrites': writes,
            'firestoreDeletes': deletes,
            'storageBytes': 0,
            'functionCalls': fnCalls,
            'networkEgressBytes': netBytes,
            'storageUploadBytes': uploadBytes,
            'storageDownloadBytes': downloadBytes,
            'lastUpdated': FieldValue.serverTimestamp(),
            'periodStart': Timestamp.fromDate(periodStart),
          });
        }
      });
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Failed to flush usage: $e');
    }
  }

  /// Force flush (call on app close)
  static Future<void> flush() async {
    await _flushUsage();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADMIN DASHBOARD METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all user usage data (for admin dashboard)
  /// D10: Paginated with limit to avoid full-collection read at scale
  static Future<List<UserUsage>> getAllUserUsage({int limit = 200}) async {
    try {
      final snapshot = await _firestore
          .collection('user_usage')
          .orderBy('estimatedCost', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((d) => UserUsage.fromFirestore(d)).toList();
    } catch (e) {
      debugPrint('❌ Failed to get user usage: $e');
      return [];
    }
  }

  /// Get usage summary for admin dashboard
  static Future<Map<String, dynamic>> getUsageSummary() async {
    try {
      final allUsage = await getAllUserUsage();

      if (allUsage.isEmpty) {
        return {
          'totalCost': 0.0,
          'adminCost': 0.0,
          'userCost': 0.0,
          'totalUsers': 0,
          'adminUsers': 0,
          'regularUsers': 0,
          'totalReads': 0,
          'totalWrites': 0,
          'totalStorage': 0,
        };
      }

      double totalCost = 0;
      double adminCost = 0;
      int totalReads = 0;
      int totalWrites = 0;
      int totalDeletes = 0;
      int totalStorage = 0;
      int totalFunctionCalls = 0;
      int totalNetworkBytes = 0;
      int totalStorageUpload = 0;
      int totalStorageDownload = 0;
      int adminCount = 0;

      for (final usage in allUsage) {
        totalCost += usage.estimatedCost;
        totalReads += usage.firestoreReads;
        totalWrites += usage.firestoreWrites;
        totalDeletes += usage.firestoreDeletes;
        totalStorage += usage.storageBytes;
        totalFunctionCalls += usage.functionCalls;
        totalNetworkBytes += usage.networkEgressBytes;
        totalStorageUpload += usage.storageUploadBytes;
        totalStorageDownload += usage.storageDownloadBytes;

        if (usage.isAdmin) {
          adminCost += usage.estimatedCost;
          adminCount++;
        }
      }

      return {
        'totalCost': totalCost,
        'adminCost': adminCost,
        'userCost': totalCost - adminCost,
        'totalUsers': allUsage.length,
        'adminUsers': adminCount,
        'regularUsers': allUsage.length - adminCount,
        'totalReads': totalReads,
        'totalWrites': totalWrites,
        'totalDeletes': totalDeletes,
        'totalStorage': totalStorage,
        'totalFunctionCalls': totalFunctionCalls,
        'totalNetworkBytes': totalNetworkBytes,
        'totalStorageUpload': totalStorageUpload,
        'totalStorageDownload': totalStorageDownload,
        'users': allUsage,
      };
    } catch (e) {
      debugPrint('❌ Failed to get usage summary: $e');
      return {};
    }
  }

  /// Get top users by cost
  static Future<List<UserUsage>> getTopUsersByCost({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('user_usage')
          .orderBy('estimatedCost', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((d) => UserUsage.fromFirestore(d)).toList();
    } catch (e) {
      debugPrint('❌ Failed to get top users: $e');
      return [];
    }
  }

  /// Reset usage for new billing period (call monthly).
  /// Processes in chunks of 400 to stay under Firestore's 500-op batch limit.
  static Future<void> resetMonthlyUsage() async {
    try {
      final periodStart = DateTime(DateTime.now().year, DateTime.now().month);
      final baseQuery = _firestore.collection('user_usage');
      QuerySnapshot snapshot;
      DocumentSnapshot? lastDoc;

      do {
        Query query = baseQuery.limit(400);
        if (lastDoc != null) {
          query = query.startAfterDocument(lastDoc);
        }
        snapshot = await query.get();
        if (snapshot.docs.isEmpty) break;

        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.update(doc.reference, {
            'firestoreReads': 0,
            'firestoreWrites': 0,
            'firestoreDeletes': 0,
            'functionCalls': 0,
            'periodStart': Timestamp.fromDate(periodStart),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
        lastDoc = snapshot.docs.last;
      } while (snapshot.docs.length == 400);
    } catch (e) {
      debugPrint('❌ Failed to reset usage: $e');
    }
  }
}
