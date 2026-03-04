/// Firestore service for Super Admin operations
/// Fetches data across all users for admin dashboard
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:retaillite/features/super_admin/models/admin_user_model.dart';

class AdminFirestoreService {
  AdminFirestoreService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all users for admin dashboard
  static Future<List<AdminUser>> getAllUsers({
    int limit = 100,
    DocumentSnapshot? startAfter,
    String? searchQuery,
    SubscriptionPlan? planFilter,
  }) async {
    try {
      Query query = _firestore
          .collection('users')
          .orderBy('createdAt', descending: true);

      if (planFilter != null) {
        query = query.where('subscription.plan', isEqualTo: planFilter.name);
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      final snapshot = await query.get();

      List<AdminUser> users = snapshot.docs
          .map((doc) => AdminUser.fromFirestore(doc))
          .toList();

      // Client-side search filter (Firestore doesn't support partial text search)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        users = users
            .where(
              (user) =>
                  user.shopName.toLowerCase().contains(lowerQuery) ||
                  user.email.toLowerCase().contains(lowerQuery) ||
                  user.ownerName.toLowerCase().contains(lowerQuery) ||
                  (user.phone?.contains(lowerQuery) ?? false),
            )
            .toList();
      }

      return users;
    } catch (e) {
      debugPrint('❌ AdminFirestore: Failed to get users: $e');
      return [];
    }
  }

  /// Get single user details
  static Future<AdminUser?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return AdminUser.fromFirestore(doc);
    } catch (e) {
      debugPrint('❌ AdminFirestore: Failed to get user: $e');
      return null;
    }
  }

  /// Get admin dashboard statistics — reads from aggregation counter doc
  /// (`app_config/stats`) kept up to date by the `onSubscriptionWrite` CF.
  /// Falls back to count() aggregation queries for activity metrics.
  static Future<AdminStats> getAdminStats() async {
    try {
      final now = DateTime.now();
      final todayStart = Timestamp.fromDate(
        DateTime(now.year, now.month, now.day),
      );
      final weekAgo = Timestamp.fromDate(now.subtract(const Duration(days: 7)));
      final monthAgo = Timestamp.fromDate(
        now.subtract(const Duration(days: 30)),
      );

      // ONE document read for plan/user counts (maintained by CF onSubscriptionWrite)
      final statsDocFuture = _firestore
          .collection('app_config')
          .doc('stats')
          .get();

      // 5 count() aggregation queries — each costs 1 read, no doc data returned
      final countFutures = Future.wait([
        _firestore
            .collection('users')
            .where('activity.lastActiveAt', isGreaterThanOrEqualTo: todayStart)
            .count()
            .get(),
        _firestore
            .collection('users')
            .where('activity.lastActiveAt', isGreaterThanOrEqualTo: weekAgo)
            .count()
            .get(),
        _firestore
            .collection('users')
            .where('activity.lastActiveAt', isGreaterThanOrEqualTo: monthAgo)
            .count()
            .get(),
        _firestore
            .collection('users')
            .where('createdAt', isGreaterThanOrEqualTo: todayStart)
            .count()
            .get(),
        _firestore
            .collection('users')
            .where('createdAt', isGreaterThanOrEqualTo: weekAgo)
            .count()
            .get(),
      ]);

      final results = await Future.wait([statsDocFuture, countFutures]);
      final statsDoc = results[0] as DocumentSnapshot;
      final counts = results[1] as List<AggregateQuerySnapshot>;

      final sd = statsDoc.data() as Map<String, dynamic>? ?? {};

      return AdminStats(
        totalUsers: (sd['totalUsers'] as int?) ?? 0,
        freeUsers: (sd['freeUsers'] as int?) ?? 0,
        proUsers: (sd['proUsers'] as int?) ?? 0,
        businessUsers: (sd['businessUsers'] as int?) ?? 0,
        mrr: ((sd['mrr'] as num?) ?? 0).toDouble(),
        activeToday: counts[0].count ?? 0,
        activeThisWeek: counts[1].count ?? 0,
        activeThisMonth: counts[2].count ?? 0,
        newUsersToday: counts[3].count ?? 0,
        newUsersThisWeek: counts[4].count ?? 0,
      );
    } catch (e) {
      debugPrint('❌ AdminFirestore: Failed to get stats: $e');
      return const AdminStats();
    }
  }

  /// Get user's bills count
  static Future<int> getUserBillsCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('bills')
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get user's products count
  static Future<int> getUserProductsCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('products')
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get user's customers count
  static Future<int> getUserCustomersCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('customers')
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Update user subscription (admin action) with audit trail (SA8)
  static Future<bool> updateUserSubscription(
    String userId,
    UserSubscription subscription,
  ) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final oldSub = userDoc.data()?['subscription'] as Map<String, dynamic>?;

      await _firestore.collection('users').doc(userId).update({
        'subscription': subscription.toMap(),
        'limits.billsLimit': subscription.billsLimit,
      });

      // Write audit log
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('subscription_audit')
          .add({
            'oldPlan': oldSub?['plan'] ?? 'unknown',
            'newPlan': subscription.plan,
            'oldBillsLimit': oldSub?['billsLimit'],
            'newBillsLimit': subscription.billsLimit,
            'changedAt': FieldValue.serverTimestamp(),
            'changedBy': 'admin',
          });

      return true;
    } catch (e) {
      debugPrint('❌ AdminFirestore: Failed to update subscription: $e');
      return false;
    }
  }

  /// Reset user monthly limits (admin action)
  static Future<bool> resetUserLimits(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'limits.billsThisMonth': 0,
        'limits.lastResetAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('❌ AdminFirestore: Failed to reset user limits: $e');
      return false;
    }
  }

  /// Get recent users (for dashboard)
  static Future<List<AdminUser>> getRecentUsers({int limit = 5}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((d) => AdminUser.fromFirestore(d)).toList();
    } catch (e) {
      debugPrint('❌ AdminFirestore: Failed to get recent users: $e');
      return [];
    }
  }

  /// Get users with expiring subscriptions
  static Future<List<AdminUser>> getExpiringSubscriptions({
    int daysAhead = 7,
  }) async {
    try {
      final futureDate = DateTime.now().add(Duration(days: daysAhead));

      final snapshot = await _firestore
          .collection('users')
          .where(
            'subscription.expiresAt',
            isLessThan: Timestamp.fromDate(futureDate),
          )
          .where('subscription.status', isEqualTo: 'active')
          .limit(100)
          .get();

      return snapshot.docs.map((d) => AdminUser.fromFirestore(d)).toList();
    } catch (e) {
      debugPrint('❌ AdminFirestore: Failed to get expiring subscriptions: $e');
      return [];
    }
  }

  /// Get platform distribution stats from pre-aggregated stats doc.
  /// D1-1: Replaces full-collection scan with single doc read.
  static Future<Map<String, int>> getPlatformStats() async {
    try {
      final statsDoc = await _firestore
          .collection('app_config')
          .doc('stats')
          .get();
      final data = statsDoc.data();
      if (data == null) return {'unknown': 0};

      final platformCounts = <String, int>{};
      final raw = data['platformCounts'] as Map<String, dynamic>? ?? {};
      for (final entry in raw.entries) {
        final count = (entry.value as num?)?.toInt() ?? 0;
        if (count > 0) platformCounts[entry.key] = count;
      }

      return platformCounts.isEmpty ? {'unknown': 0} : platformCounts;
    } catch (e) {
      debugPrint('❌ AdminFirestore: Failed to get platform stats: $e');
      return {'unknown': 0};
    }
  }

  /// Get feature usage stats from pre-aggregated stats doc.
  /// D1-1: Replaces full-collection scan with single doc read.
  static Future<Map<String, double>> getFeatureUsageStats() async {
    try {
      final statsDoc = await _firestore
          .collection('app_config')
          .doc('stats')
          .get();
      final data = statsDoc.data();
      if (data == null) {
        return {
          'billing': 0,
          'products': 0,
          'khata': 0,
          'reports': 0,
          'settings': 0,
        };
      }

      final totalUsers = (data['totalUsers'] as num?)?.toDouble() ?? 1;
      final usage = data['featureUsageCounts'] as Map<String, dynamic>? ?? {};

      final billingUsers = (usage['billing'] as num?)?.toDouble() ?? 0;
      final productUsers = (usage['products'] as num?)?.toDouble() ?? 0;
      final khataUsers = (usage['khata'] as num?)?.toDouble() ?? 0;

      return {
        'billing': totalUsers > 0 ? billingUsers / totalUsers : 0,
        'products': totalUsers > 0 ? productUsers / totalUsers : 0,
        'khata': totalUsers > 0 ? khataUsers / totalUsers : 0,
        'reports': totalUsers > 0 ? (billingUsers * 0.5) / totalUsers : 0,
        'settings': 0.3,
      };
    } catch (e) {
      debugPrint('❌ AdminFirestore: Failed to get feature usage stats: $e');
      return {
        'billing': 0,
        'products': 0,
        'khata': 0,
        'reports': 0,
        'settings': 0,
      };
    }
  }

  /// Get aggregated analytics for admin dashboard
  static Future<Map<String, dynamic>> getAggregatedAnalytics() async {
    try {
      final platformStats = await getPlatformStats();
      final featureStats = await getFeatureUsageStats();
      final adminStats = await getAdminStats();

      return {
        'platformStats': platformStats,
        'featureStats': featureStats,
        'adminStats': adminStats,
      };
    } catch (e) {
      debugPrint('❌ AdminFirestore: Failed to get aggregated analytics: $e');
      return {};
    }
  }

  // =====================
  // ADMIN MANAGEMENT
  // =====================

  /// The primary owner email that can never be removed
  static const String primaryOwnerEmail = 'kehsaram001@gmail.com';

  /// Firestore path for admin config
  static const String _adminConfigPath = 'app_config';
  static const String _superAdminsDoc = 'super_admins';

  /// Get admin emails from Firestore
  static Future<List<String>> getAdminEmails() async {
    try {
      final doc = await _firestore
          .collection(_adminConfigPath)
          .doc(_superAdminsDoc)
          .get();

      if (!doc.exists) {
        // Initialize with primary owner if doc doesn't exist
        await _initAdminDoc();
        return [primaryOwnerEmail];
      }

      final data = doc.data();
      final emails =
          (data?['emails'] as List<dynamic>?)
              ?.map((e) => e.toString().toLowerCase().trim())
              .toList() ??
          [primaryOwnerEmail];

      // Ensure primary owner is always included
      if (!emails.contains(primaryOwnerEmail)) {
        emails.insert(0, primaryOwnerEmail);
      }

      return emails;
    } catch (e) {
      debugPrint('❌ AdminFirestore: Failed to get admin emails: $e');
      return [primaryOwnerEmail];
    }
  }

  /// Initialize admin config document with primary owner
  static Future<void> _initAdminDoc() async {
    try {
      await _firestore.collection(_adminConfigPath).doc(_superAdminsDoc).set({
        'emails': [primaryOwnerEmail],
        'primaryOwner': primaryOwnerEmail,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ AdminFirestore: Failed to init admin doc: $e');
    }
  }

  /// Add an admin email
  static Future<bool> addAdminEmail(String email) async {
    final normalizedEmail = email.toLowerCase().trim();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      return false;
    }

    try {
      final currentEmails = await getAdminEmails();
      if (currentEmails.contains(normalizedEmail)) {
        return false; // Already an admin
      }

      currentEmails.add(normalizedEmail);

      await _firestore.collection(_adminConfigPath).doc(_superAdminsDoc).set({
        'emails': currentEmails,
        'primaryOwner': primaryOwnerEmail,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      debugPrint('❌ AdminFirestore: Failed to add admin: $e');
      return false;
    }
  }

  /// Remove an admin email (cannot remove primary owner)
  static Future<bool> removeAdminEmail(String email) async {
    final normalizedEmail = email.toLowerCase().trim();

    // Never allow removing the primary owner
    if (normalizedEmail == primaryOwnerEmail) {
      return false;
    }

    try {
      final currentEmails = await getAdminEmails();
      if (!currentEmails.contains(normalizedEmail)) {
        return false; // Not an admin
      }

      currentEmails.remove(normalizedEmail);

      await _firestore.collection(_adminConfigPath).doc(_superAdminsDoc).set({
        'emails': currentEmails,
        'primaryOwner': primaryOwnerEmail,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      debugPrint('❌ AdminFirestore: Failed to remove admin: $e');
      return false;
    }
  }
}
