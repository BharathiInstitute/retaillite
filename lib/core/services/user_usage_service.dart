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

    return readsCost + writesCost + deletesCost + storageCost + functionsCost;
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

  /// Super admin emails
  static const List<String> _adminEmails = [
    'kehsaram001@gmail.com',
    'admin@retaillite.com',
    'bharathiinstitute1@gmail.com',
  ];

  /// In-memory counters for batching
  static int _pendingReads = 0;
  static int _pendingWrites = 0;
  static int _pendingDeletes = 0;
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

  /// Maybe flush pending counts to Firestore
  static void _maybeFlush() {
    final now = DateTime.now();

    // Flush every 30 seconds or if counts are significant
    if (_lastFlush == null ||
        now.difference(_lastFlush!).inSeconds >= 30 ||
        _pendingReads + _pendingWrites + _pendingDeletes >= 50) {
      _flushUsage();
    }
  }

  /// Flush pending usage to Firestore
  static Future<void> _flushUsage() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    if (_pendingReads == 0 && _pendingWrites == 0 && _pendingDeletes == 0) {
      return;
    }

    final reads = _pendingReads;
    final writes = _pendingWrites;
    final deletes = _pendingDeletes;

    // Reset counters immediately
    _pendingReads = 0;
    _pendingWrites = 0;
    _pendingDeletes = 0;
    _lastFlush = DateTime.now();

    try {
      final email = _auth.currentUser?.email?.toLowerCase() ?? '';
      final isAdmin = _adminEmails.contains(email);

      final docRef = _firestore.collection('user_usage').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        if (doc.exists) {
          // Update existing
          transaction.update(docRef, {
            'firestoreReads': FieldValue.increment(reads),
            'firestoreWrites': FieldValue.increment(writes),
            'firestoreDeletes': FieldValue.increment(deletes),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
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
            'functionCalls': 0,
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
  static Future<List<UserUsage>> getAllUserUsage() async {
    try {
      final snapshot = await _firestore
          .collection('user_usage')
          .orderBy('estimatedCost', descending: true)
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
      int totalStorage = 0;
      int adminCount = 0;

      for (final usage in allUsage) {
        totalCost += usage.estimatedCost;
        totalReads += usage.firestoreReads;
        totalWrites += usage.firestoreWrites;
        totalStorage += usage.storageBytes;

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
        'totalStorage': totalStorage,
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

  /// Reset usage for new billing period (call monthly)
  static Future<void> resetMonthlyUsage() async {
    try {
      final snapshot = await _firestore.collection('user_usage').get();
      final batch = _firestore.batch();
      final periodStart = DateTime(DateTime.now().year, DateTime.now().month);

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
    } catch (e) {
      debugPrint('❌ Failed to reset usage: $e');
    }
  }
}
