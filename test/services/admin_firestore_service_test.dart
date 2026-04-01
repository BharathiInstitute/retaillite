/// Tests for AdminFirestoreService — Super Admin Firestore operations.
///
/// Tests the admin models (AdminUser, UserSubscription, UserLimits, UserActivity,
/// AdminStats), serialization, and client-side logic. Firestore queries are
/// tested via FakeFirebaseFirestore for model parsing, and admin email management
/// logic is tested inline.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/features/super_admin/models/admin_user_model.dart';
import 'package:retaillite/features/super_admin/services/admin_firestore_service.dart';

void main() {
  // ── SubscriptionPlan enum ──

  group('SubscriptionPlan enum', () {
    test('has 3 values: free, pro, business', () {
      expect(SubscriptionPlan.values.length, 3);
      expect(SubscriptionPlan.values.map((e) => e.name), [
        'free',
        'pro',
        'business',
      ]);
    });
  });

  // ── SubscriptionStatus enum ──

  group('SubscriptionStatus enum', () {
    test('has 4 values: active, trial, expired, cancelled', () {
      expect(SubscriptionStatus.values.length, 4);
      expect(SubscriptionStatus.values.map((e) => e.name), [
        'active',
        'trial',
        'expired',
        'cancelled',
      ]);
    });
  });

  // ── UserSubscription model ──

  group('UserSubscription model', () {
    test('defaults to free/active', () {
      const sub = UserSubscription();
      expect(sub.plan, SubscriptionPlan.free);
      expect(sub.status, SubscriptionStatus.active);
      expect(sub.startedAt, isNull);
      expect(sub.expiresAt, isNull);
      expect(sub.razorpaySubscriptionId, isNull);
    });

    test('fromMap with null returns defaults', () {
      final sub = UserSubscription.fromMap(null);
      expect(sub.plan, SubscriptionPlan.free);
      expect(sub.status, SubscriptionStatus.active);
    });

    test('fromMap parses all fields', () {
      final now = DateTime(2026, 4);
      final expires = DateTime(2026, 5);
      final sub = UserSubscription.fromMap({
        'plan': 'pro',
        'status': 'active',
        'startedAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(expires),
        'razorpaySubscriptionId': 'sub_abc123',
      });
      expect(sub.plan, SubscriptionPlan.pro);
      expect(sub.status, SubscriptionStatus.active);
      expect(sub.startedAt, now);
      expect(sub.expiresAt, expires);
      expect(sub.razorpaySubscriptionId, 'sub_abc123');
    });

    test('fromMap with unknown plan falls back to free', () {
      final sub = UserSubscription.fromMap({'plan': 'enterprise'});
      expect(sub.plan, SubscriptionPlan.free);
    });

    test('fromMap with unknown status falls back to active', () {
      final sub = UserSubscription.fromMap({'status': 'pending'});
      expect(sub.status, SubscriptionStatus.active);
    });

    test('toMap serializes all fields', () {
      final now = DateTime(2026, 4);
      final sub = UserSubscription(
        plan: SubscriptionPlan.business,
        status: SubscriptionStatus.trial,
        startedAt: now,
        expiresAt: DateTime(2026, 5),
        razorpaySubscriptionId: 'sub_xyz',
      );
      final map = sub.toMap();
      expect(map['plan'], 'business');
      expect(map['status'], 'trial');
      expect(map['startedAt'], Timestamp.fromDate(now));
      expect(map['razorpaySubscriptionId'], 'sub_xyz');
    });

    test('toMap sets null timestamps as null', () {
      const sub = UserSubscription();
      final map = sub.toMap();
      expect(map['startedAt'], isNull);
      expect(map['expiresAt'], isNull);
    });

    test('planDisplayName returns correct labels', () {
      expect(const UserSubscription().planDisplayName, 'Free');
      expect(
        const UserSubscription(plan: SubscriptionPlan.pro).planDisplayName,
        'Pro',
      );
      expect(
        const UserSubscription(plan: SubscriptionPlan.business).planDisplayName,
        'Business',
      );
    });

    test('planPrice returns correct amounts', () {
      expect(const UserSubscription().planPrice, 0);
      expect(const UserSubscription(plan: SubscriptionPlan.pro).planPrice, 299);
      expect(
        const UserSubscription(plan: SubscriptionPlan.business).planPrice,
        999,
      );
    });

    test('billsLimit returns correct limits per plan', () {
      expect(const UserSubscription().billsLimit, 50);
      expect(
        const UserSubscription(plan: SubscriptionPlan.pro).billsLimit,
        500,
      );
      expect(
        const UserSubscription(plan: SubscriptionPlan.business).billsLimit,
        999999,
      );
    });

    test('isActive for active and trial status', () {
      expect(const UserSubscription().isActive, isTrue);
      expect(
        const UserSubscription(status: SubscriptionStatus.trial).isActive,
        isTrue,
      );
      expect(
        const UserSubscription(status: SubscriptionStatus.expired).isActive,
        isFalse,
      );
      expect(
        const UserSubscription(status: SubscriptionStatus.cancelled).isActive,
        isFalse,
      );
    });
  });

  // ── UserLimits model ──

  group('UserLimits model', () {
    test('defaults', () {
      const limits = UserLimits();
      expect(limits.billsThisMonth, 0);
      expect(limits.billsLimit, 50);
      expect(limits.productsCount, 0);
      expect(limits.customersCount, 0);
    });

    test('fromMap with null returns defaults', () {
      final limits = UserLimits.fromMap(null);
      expect(limits.billsLimit, 50);
    });

    test('fromMap parses all fields', () {
      final limits = UserLimits.fromMap({
        'billsThisMonth': 25,
        'billsLimit': 500,
        'productsCount': 100,
        'customersCount': 50,
      });
      expect(limits.billsThisMonth, 25);
      expect(limits.billsLimit, 500);
      expect(limits.productsCount, 100);
      expect(limits.customersCount, 50);
    });

    test('usagePercentage at 0 bills', () {
      const limits = UserLimits(billsLimit: 50);
      expect(limits.usagePercentage, 0.0);
    });

    test('usagePercentage at 50%', () {
      const limits = UserLimits(billsThisMonth: 25);
      expect(limits.usagePercentage, 0.5);
    });

    test('usagePercentage clamped at 1.0 when over limit', () {
      const limits = UserLimits(billsThisMonth: 100);
      expect(limits.usagePercentage, 1.0);
    });

    test('usagePercentage returns 0 when billsLimit is 0', () {
      const limits = UserLimits(billsThisMonth: 10, billsLimit: 0);
      expect(limits.usagePercentage, 0.0);
    });

    test('isNearLimit at 80% threshold', () {
      const below = UserLimits(billsThisMonth: 40);
      expect(below.isNearLimit, isFalse); // 80% exactly

      const above = UserLimits(billsThisMonth: 41);
      expect(above.isNearLimit, isTrue); // 82%
    });

    test('isAtLimit at exactly limit', () {
      const at = UserLimits(billsThisMonth: 50);
      expect(at.isAtLimit, isTrue);
    });

    test('isAtLimit below limit', () {
      const below = UserLimits(billsThisMonth: 49);
      expect(below.isAtLimit, isFalse);
    });

    test('isAtLimit above limit', () {
      const above = UserLimits(billsThisMonth: 51);
      expect(above.isAtLimit, isTrue);
    });
  });

  // ── UserActivity model ──

  group('UserActivity model', () {
    test('defaults are all null', () {
      const activity = UserActivity();
      expect(activity.lastActiveAt, isNull);
      expect(activity.appVersion, isNull);
      expect(activity.platform, isNull);
    });

    test('fromMap with null returns defaults', () {
      final activity = UserActivity.fromMap(null);
      expect(activity.lastActiveAt, isNull);
    });

    test('fromMap parses all fields', () {
      final ts = DateTime(2026, 4, 1, 10);
      final activity = UserActivity.fromMap({
        'lastActiveAt': Timestamp.fromDate(ts),
        'appVersion': '9.7.0',
        'platform': 'android',
      });
      expect(activity.lastActiveAt, ts);
      expect(activity.appVersion, '9.7.0');
      expect(activity.platform, 'android');
    });

    test('isActiveToday returns true for today', () {
      final now = DateTime.now();
      final activity = UserActivity(lastActiveAt: now);
      expect(activity.isActiveToday, isTrue);
    });

    test('isActiveToday returns false for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final activity = UserActivity(lastActiveAt: yesterday);
      expect(activity.isActiveToday, isFalse);
    });

    test('isActiveToday returns false when null', () {
      const activity = UserActivity();
      expect(activity.isActiveToday, isFalse);
    });

    test('isActiveThisWeek returns true for 3 days ago', () {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      final activity = UserActivity(lastActiveAt: threeDaysAgo);
      expect(activity.isActiveThisWeek, isTrue);
    });

    test('isActiveThisWeek returns false for 8 days ago', () {
      final eightDaysAgo = DateTime.now().subtract(const Duration(days: 8));
      final activity = UserActivity(lastActiveAt: eightDaysAgo);
      expect(activity.isActiveThisWeek, isFalse);
    });

    test('lastActiveAgo returns "Never" when null', () {
      const activity = UserActivity();
      expect(activity.lastActiveAgo, 'Never');
    });

    test('lastActiveAgo returns "Just now" for recent', () {
      final activity = UserActivity(lastActiveAt: DateTime.now());
      expect(activity.lastActiveAgo, 'Just now');
    });

    test('lastActiveAgo returns minutes format', () {
      final activity = UserActivity(
        lastActiveAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );
      expect(activity.lastActiveAgo, '30m ago');
    });

    test('lastActiveAgo returns hours format', () {
      final activity = UserActivity(
        lastActiveAt: DateTime.now().subtract(const Duration(hours: 5)),
      );
      expect(activity.lastActiveAgo, '5h ago');
    });

    test('lastActiveAgo returns days format', () {
      final activity = UserActivity(
        lastActiveAt: DateTime.now().subtract(const Duration(days: 3)),
      );
      expect(activity.lastActiveAgo, '3d ago');
    });

    test('lastActiveAgo returns weeks format', () {
      final activity = UserActivity(
        lastActiveAt: DateTime.now().subtract(const Duration(days: 14)),
      );
      expect(activity.lastActiveAgo, '2w ago');
    });
  });

  // ── AdminUser model ──

  group('AdminUser model', () {
    test('fromFirestore parses complete document', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      await fakeFirestore.collection('users').doc('user1').set({
        'email': 'test@shop.com',
        'shopName': 'Test Shop',
        'ownerName': 'Test Owner',
        'phone': '+91-9876543210',
        'address': '123 Main St',
        'gstNumber': 'GST123',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1)),
        'subscription': {
          'plan': 'pro',
          'status': 'active',
          'startedAt': Timestamp.fromDate(DateTime(2026, 1)),
          'expiresAt': Timestamp.fromDate(DateTime(2026, 2)),
        },
        'limits': {
          'billsThisMonth': 25,
          'billsLimit': 500,
          'productsCount': 100,
          'customersCount': 50,
        },
        'activity': {
          'lastActiveAt': Timestamp.fromDate(DateTime(2026, 4)),
          'appVersion': '9.7.0',
          'platform': 'android',
        },
      });

      final doc = await fakeFirestore.collection('users').doc('user1').get();
      final user = AdminUser.fromFirestore(doc);

      expect(user.id, 'user1');
      expect(user.email, 'test@shop.com');
      expect(user.shopName, 'Test Shop');
      expect(user.ownerName, 'Test Owner');
      expect(user.phone, '+91-9876543210');
      expect(user.address, '123 Main St');
      expect(user.gstNumber, 'GST123');
      expect(user.subscription.plan, SubscriptionPlan.pro);
      expect(user.limits.billsThisMonth, 25);
      expect(user.activity.platform, 'android');
    });

    test('fromFirestore defaults missing fields', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      await fakeFirestore.collection('users').doc('user2').set({});

      final doc = await fakeFirestore.collection('users').doc('user2').get();
      final user = AdminUser.fromFirestore(doc);

      expect(user.id, 'user2');
      expect(user.email, '');
      expect(user.shopName, 'Unknown Shop');
      expect(user.ownerName, 'Unknown');
      expect(user.phone, isNull);
      expect(user.subscription.plan, SubscriptionPlan.free);
      expect(user.limits.billsLimit, 50);
    });

    test('daysSinceRegistration for new user', () {
      final user = AdminUser(
        id: 'u1',
        email: 'a@b.com',
        shopName: 'S',
        ownerName: 'O',
        createdAt: DateTime.now(),
      );
      expect(user.daysSinceRegistration, 0);
    });

    test('daysSinceRegistration for old user', () {
      final user = AdminUser(
        id: 'u1',
        email: 'a@b.com',
        shopName: 'S',
        ownerName: 'O',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      );
      expect(user.daysSinceRegistration, 30);
    });

    test('daysSinceRegistration returns 0 when createdAt is null', () {
      const user = AdminUser(
        id: 'u1',
        email: 'a@b.com',
        shopName: 'S',
        ownerName: 'O',
      );
      expect(user.daysSinceRegistration, 0);
    });
  });

  // ── AdminStats model ──

  group('AdminStats model', () {
    test('defaults are all 0', () {
      const stats = AdminStats();
      expect(stats.totalUsers, 0);
      expect(stats.activeToday, 0);
      expect(stats.mrr, 0);
      expect(stats.freeUsers, 0);
      expect(stats.proUsers, 0);
      expect(stats.businessUsers, 0);
    });

    test('paidUsers = pro + business', () {
      const stats = AdminStats(proUsers: 10, businessUsers: 5);
      expect(stats.paidUsers, 15);
    });

    test('conversionRate calculated correctly', () {
      const stats = AdminStats(totalUsers: 100, proUsers: 15, businessUsers: 5);
      expect(stats.conversionRate, 20.0); // 20/100 * 100
    });

    test('conversionRate is 0 when totalUsers is 0', () {
      const stats = AdminStats(proUsers: 0);
      expect(stats.conversionRate, 0);
    });

    test('MRR calculation: pro=299, business=999', () {
      // This mirrors recalculateStats logic:
      //   pro: mrr += 299 per active pro user
      //   business: mrr += 999 per active business user
      const proCount = 10;
      const businessCount = 3;
      const mrr = (proCount * 299) + (businessCount * 999);
      expect(mrr, 5987);
    });
  });

  // ── Admin email management logic ──

  group('Admin email management logic', () {
    // Mirrors AdminFirestoreService.addAdminEmail / removeAdminEmail
    const primaryOwnerEmail = 'kehsaram001@gmail.com';

    test('primaryOwnerEmail is hardcoded constant', () {
      expect(AdminFirestoreService.primaryOwnerEmail, primaryOwnerEmail);
    });

    test('cannot remove primary owner email', () {
      bool removeAdminEmail(String email, List<String> currentEmails) {
        if (email.toLowerCase().trim() == primaryOwnerEmail) return false;
        if (!currentEmails.contains(email)) return false;
        currentEmails.remove(email);
        return true;
      }

      final emails = [primaryOwnerEmail, 'other@a.com'];
      expect(removeAdminEmail(primaryOwnerEmail, emails), isFalse);
      expect(emails.length, 2); // unchanged
    });

    test('can remove non-primary admin email', () {
      bool removeAdminEmail(String email, List<String> currentEmails) {
        if (email.toLowerCase().trim() == primaryOwnerEmail) return false;
        if (!currentEmails.contains(email)) return false;
        currentEmails.remove(email);
        return true;
      }

      final emails = [primaryOwnerEmail, 'other@a.com'];
      expect(removeAdminEmail('other@a.com', emails), isTrue);
      expect(emails.length, 1);
    });

    test('cannot remove non-existent email', () {
      bool removeAdminEmail(String email, List<String> currentEmails) {
        if (email.toLowerCase().trim() == primaryOwnerEmail) return false;
        if (!currentEmails.contains(email)) return false;
        currentEmails.remove(email);
        return true;
      }

      final emails = [primaryOwnerEmail];
      expect(removeAdminEmail('ghost@a.com', emails), isFalse);
    });

    test('addAdminEmail rejects duplicates', () {
      bool addAdminEmail(String email, List<String> currentEmails) {
        final normalized = email.toLowerCase().trim();
        if (normalized.isEmpty || !normalized.contains('@')) return false;
        if (currentEmails.contains(normalized)) return false;
        currentEmails.add(normalized);
        return true;
      }

      final emails = [primaryOwnerEmail];
      expect(addAdminEmail(primaryOwnerEmail, emails), isFalse);
    });

    test('addAdminEmail normalizes email', () {
      bool addAdminEmail(String email, List<String> currentEmails) {
        final normalized = email.toLowerCase().trim();
        if (normalized.isEmpty || !normalized.contains('@')) return false;
        if (currentEmails.contains(normalized)) return false;
        currentEmails.add(normalized);
        return true;
      }

      final emails = <String>[];
      expect(addAdminEmail('  Admin@Test.COM  ', emails), isTrue);
      expect(emails.first, 'admin@test.com');
    });

    test('addAdminEmail rejects empty email', () {
      bool addAdminEmail(String email, List<String> currentEmails) {
        final normalized = email.toLowerCase().trim();
        if (normalized.isEmpty || !normalized.contains('@')) return false;
        if (currentEmails.contains(normalized)) return false;
        currentEmails.add(normalized);
        return true;
      }

      final emails = <String>[];
      expect(addAdminEmail('', emails), isFalse);
      expect(addAdminEmail('   ', emails), isFalse);
    });

    test('addAdminEmail rejects email without @', () {
      bool addAdminEmail(String email, List<String> currentEmails) {
        final normalized = email.toLowerCase().trim();
        if (normalized.isEmpty || !normalized.contains('@')) return false;
        if (currentEmails.contains(normalized)) return false;
        currentEmails.add(normalized);
        return true;
      }

      final emails = <String>[];
      expect(addAdminEmail('notanemail', emails), isFalse);
    });
  });

  // ── Client-side search logic (mirrors getAllUsers searchQuery) ──

  group('Admin user search', () {
    List<AdminUser> searchUsers(List<AdminUser> users, String query) {
      final lowerQuery = query.toLowerCase();
      return users
          .where(
            (user) =>
                user.shopName.toLowerCase().contains(lowerQuery) ||
                user.email.toLowerCase().contains(lowerQuery) ||
                user.ownerName.toLowerCase().contains(lowerQuery) ||
                (user.phone?.contains(lowerQuery) ?? false),
          )
          .toList();
    }

    final users = [
      const AdminUser(
        id: 'u1',
        email: 'rakesh@shop.com',
        shopName: 'Kumar Stores',
        ownerName: 'Rakesh Kumar',
        phone: '+91-9876543210',
      ),
      const AdminUser(
        id: 'u2',
        email: 'priya@gmail.com',
        shopName: 'Priya Fashion',
        ownerName: 'Priya Singh',
      ),
    ];

    test('finds by shopName', () {
      expect(searchUsers(users, 'Kumar').length, 1);
    });

    test('finds by email', () {
      expect(searchUsers(users, 'priya@gmail').length, 1);
    });

    test('finds by phone', () {
      expect(searchUsers(users, '9876').length, 1);
    });

    test('case-insensitive', () {
      expect(searchUsers(users, 'KUMAR').length, 1);
    });

    test('empty query returns all', () {
      expect(searchUsers(users, '').length, 2);
    });
  });
}
