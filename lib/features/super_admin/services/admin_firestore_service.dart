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

  /// Get admin dashboard statistics
  static Future<AdminStats> getAdminStats() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final users = usersSnapshot.docs
          .map((d) => AdminUser.fromFirestore(d))
          .toList();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekAgo = now.subtract(const Duration(days: 7));
      final monthAgo = now.subtract(const Duration(days: 30));

      int activeToday = 0;
      int activeThisWeek = 0;
      int activeThisMonth = 0;
      int newUsersToday = 0;
      int newUsersThisWeek = 0;
      int freeUsers = 0;
      int proUsers = 0;
      int businessUsers = 0;
      double mrr = 0;

      for (final user in users) {
        // Count active users
        if (user.activity.isActiveToday) activeToday++;
        if (user.activity.isActiveThisWeek) activeThisWeek++;
        if (user.activity.lastActiveAt != null &&
            user.activity.lastActiveAt!.isAfter(monthAgo)) {
          activeThisMonth++;
        }

        // Count new users
        if (user.createdAt != null) {
          if (user.createdAt!.isAfter(today)) newUsersToday++;
          if (user.createdAt!.isAfter(weekAgo)) newUsersThisWeek++;
        }

        // Count by plan
        switch (user.subscription.plan) {
          case SubscriptionPlan.free:
            freeUsers++;
            break;
          case SubscriptionPlan.pro:
            proUsers++;
            mrr += 299;
            break;
          case SubscriptionPlan.business:
            businessUsers++;
            mrr += 999;
            break;
        }
      }

      return AdminStats(
        totalUsers: users.length,
        activeToday: activeToday,
        activeThisWeek: activeThisWeek,
        activeThisMonth: activeThisMonth,
        newUsersToday: newUsersToday,
        newUsersThisWeek: newUsersThisWeek,
        mrr: mrr,
        freeUsers: freeUsers,
        proUsers: proUsers,
        businessUsers: businessUsers,
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

  /// Update user subscription (admin action)
  static Future<bool> updateUserSubscription(
    String userId,
    UserSubscription subscription,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'subscription': subscription.toMap(),
        'limits.billsLimit': subscription.billsLimit,
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
          .get();

      return snapshot.docs.map((d) => AdminUser.fromFirestore(d)).toList();
    } catch (e) {
      debugPrint('❌ AdminFirestore: Failed to get expiring subscriptions: $e');
      return [];
    }
  }

  /// Get platform distribution stats (aggregated from all users)
  static Future<Map<String, int>> getPlatformStats() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      final platformCounts = <String, int>{
        'android': 0,
        'ios': 0,
        'web': 0,
        'windows': 0,
        'macos': 0,
        'linux': 0,
        'unknown': 0,
      };

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final activity = data['activity'] as Map<String, dynamic>?;
        final platform =
            (activity?['platform'] as String?)?.toLowerCase() ?? 'unknown';

        if (platformCounts.containsKey(platform)) {
          platformCounts[platform] = platformCounts[platform]! + 1;
        } else {
          platformCounts['unknown'] = platformCounts['unknown']! + 1;
        }
      }

      // Remove platforms with 0 count
      platformCounts.removeWhere((key, value) => value == 0);

      return platformCounts;
    } catch (e) {
      debugPrint('❌ AdminFirestore: Failed to get platform stats: $e');
      return {'unknown': 0};
    }
  }

  /// Get feature usage stats (based on user activity patterns)
  static Future<Map<String, double>> getFeatureUsageStats() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      final totalUsers = snapshot.docs.length;
      if (totalUsers == 0) {
        return {
          'billing': 0,
          'products': 0,
          'khata': 0,
          'reports': 0,
          'settings': 0,
        };
      }

      int usersWithBills = 0;
      int usersWithProducts = 0;
      int usersWithCustomers = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final limits = data['limits'] as Map<String, dynamic>?;

        if ((limits?['billsThisMonth'] as int? ?? 0) > 0) usersWithBills++;
        if ((limits?['productsCount'] as int? ?? 0) > 0) usersWithProducts++;
        if ((limits?['customersCount'] as int? ?? 0) > 0) usersWithCustomers++;
      }

      // Calculate percentages
      return {
        'billing': usersWithBills / totalUsers,
        'products': usersWithProducts / totalUsers,
        'khata': usersWithCustomers / totalUsers,
        'reports':
            usersWithBills *
            0.5 /
            totalUsers, // Estimate: 50% of billing users check reports
        'settings': 0.3, // Static estimate: ~30% users customize settings
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
}
