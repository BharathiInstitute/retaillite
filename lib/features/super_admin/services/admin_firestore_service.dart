/// Firestore service for Super Admin operations
/// Fetches data across all users for admin dashboard
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:retaillite/features/super_admin/models/admin_user_model.dart';

class AdminFirestoreService {
  AdminFirestoreService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static Future<void>? _seedFuture;

  /// Ensure the /admins collection is populated.
  /// The primary owner (kehsaram001@gmail.com) is hardcoded in Firestore
  /// security rules as a fallback, so they can always bootstrap.
  /// Uses a shared Future so parallel callers don't race.
  static Future<void> ensureAdminSeeded() {
    _seedFuture ??= _doSeed();
    return _seedFuture!;
  }

  static Future<void> _doSeed() async {
    try {
      // Check if admins collection already has the primary owner doc
      final doc = await _firestore
          .collection('admins')
          .doc(primaryOwnerEmail)
          .get();
      if (doc.exists) return;
    } catch (_) {
      // May fail if not primary owner and collection doesn't exist yet
    }

    // Seed the admins collection directly (primary owner has rule-level access)
    try {
      debugPrint('🔑 AdminFirestore: Seeding admins collection...');
      final batch = _firestore.batch();
      const emails = [
        primaryOwnerEmail,
        'admin@retaillite.com',
        'bharathiinstitute1@gmail.com',
        'bharahiinstitute1@gmail.com',
        'shivamsingh8556@gmail.com',
        'admin@lite.app',
        'kehsihba@gmail.com',
      ];
      for (final email in emails) {
        batch.set(_firestore.collection('admins').doc(email), {
          'email': email,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      debugPrint('✅ AdminFirestore: Seeded ${emails.length} admins');
    } catch (e) {
      debugPrint('⚠️ AdminFirestore: Seed failed: $e');
    }
  }

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
  /// Falls back to live count queries if the stats doc is missing/stale.
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

      int totalUsers = (sd['totalUsers'] as int?) ?? 0;
      int freeUsers = (sd['freeUsers'] as int?) ?? 0;
      int proUsers = (sd['proUsers'] as int?) ?? 0;
      int businessUsers = (sd['businessUsers'] as int?) ?? 0;
      double mrr = ((sd['mrr'] as num?) ?? 0).toDouble();

      // If stats doc is missing or empty, do a live recount
      if (totalUsers == 0) {
        final recalculated = await recalculateStats();
        totalUsers = recalculated.totalUsers;
        freeUsers = recalculated.freeUsers;
        proUsers = recalculated.proUsers;
        businessUsers = recalculated.businessUsers;
        mrr = recalculated.mrr;
      }

      return AdminStats(
        totalUsers: totalUsers,
        freeUsers: freeUsers,
        proUsers: proUsers,
        businessUsers: businessUsers,
        mrr: mrr,
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

  /// Recalculate stats by scanning the users collection and writing
  /// the result to `app_config/stats`. Use when stats doc is missing or stale.
  static Future<AdminStats> recalculateStats() async {
    try {
      final snapshot = await _firestore.collection('users').get();

      int total = 0;
      int free = 0;
      int pro = 0;
      int business = 0;
      double mrr = 0;
      final Map<String, int> platformCounts = {};
      int billingUsers = 0;
      int productUsers = 0;
      int khataUsers = 0;

      for (final doc in snapshot.docs) {
        total++;
        final data = doc.data();
        final sub = data['subscription'] as Map<String, dynamic>? ?? {};
        final plan = (sub['plan'] as String?) ?? 'free';
        final status = (sub['status'] as String?) ?? '';

        switch (plan) {
          case 'pro':
            pro++;
            if (status == 'active') mrr += 299;
          case 'business':
            business++;
            if (status == 'active') mrr += 999;
          default:
            free++;
        }

        // Platform
        final activity = data['activity'] as Map<String, dynamic>? ?? {};
        final platform = ((activity['platform'] as String?) ?? 'unknown')
            .toLowerCase();
        platformCounts[platform] = (platformCounts[platform] ?? 0) + 1;

        // Feature usage
        final limits = data['limits'] as Map<String, dynamic>? ?? {};
        if (((limits['billsThisMonth'] as num?) ?? 0) > 0) billingUsers++;
        if (((limits['productsCount'] as num?) ?? 0) > 0) productUsers++;
        if (((limits['customersCount'] as num?) ?? 0) > 0) khataUsers++;
      }

      // Write the recalculated stats to Firestore
      await _firestore.collection('app_config').doc('stats').set({
        'totalUsers': total,
        'freeUsers': free,
        'proUsers': pro,
        'businessUsers': business,
        'mrr': mrr,
        'platformCounts': platformCounts,
        'featureUsageCounts': {
          'billing': billingUsers,
          'products': productUsers,
          'khata': khataUsers,
        },
        'updatedAt': FieldValue.serverTimestamp(),
        'recalculatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ AdminFirestore: Recalculated stats — $total users');

      return AdminStats(
        totalUsers: total,
        freeUsers: free,
        proUsers: pro,
        businessUsers: business,
        mrr: mrr,
      );
    } catch (e) {
      debugPrint('❌ AdminFirestore: Failed to recalculate stats: $e');
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

      // Write audit log (non-fatal — don't fail the update if audit fails)
      try {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('subscription_audit')
            .add({
              'oldPlan': oldSub?['plan'] ?? 'unknown',
              'newPlan': subscription.plan.name,
              'oldBillsLimit': oldSub?['billsLimit'],
              'newBillsLimit': subscription.billsLimit,
              'changedAt': FieldValue.serverTimestamp(),
              'changedBy': 'admin',
            });
      } catch (e) {
        debugPrint('⚠️ AdminFirestore: Audit log failed (non-fatal): $e');
      }

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
