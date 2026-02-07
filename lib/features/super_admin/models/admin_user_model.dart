/// Admin user model for Super Admin panel
/// Represents a user as seen by administrators
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Subscription plan types
enum SubscriptionPlan { free, pro, business }

/// Subscription status
enum SubscriptionStatus { active, trial, expired, cancelled }

/// User subscription details
class UserSubscription {
  final SubscriptionPlan plan;
  final SubscriptionStatus status;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final String? razorpaySubscriptionId;

  const UserSubscription({
    this.plan = SubscriptionPlan.free,
    this.status = SubscriptionStatus.active,
    this.startedAt,
    this.expiresAt,
    this.razorpaySubscriptionId,
  });

  factory UserSubscription.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const UserSubscription();
    return UserSubscription(
      plan: SubscriptionPlan.values.firstWhere(
        (e) => e.name == map['plan'],
        orElse: () => SubscriptionPlan.free,
      ),
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SubscriptionStatus.active,
      ),
      startedAt: (map['startedAt'] as Timestamp?)?.toDate(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate(),
      razorpaySubscriptionId: map['razorpaySubscriptionId'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'plan': plan.name,
    'status': status.name,
    'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
    'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    'razorpaySubscriptionId': razorpaySubscriptionId,
  };

  /// Get plan display name
  String get planDisplayName {
    switch (plan) {
      case SubscriptionPlan.free:
        return 'Free';
      case SubscriptionPlan.pro:
        return 'Pro';
      case SubscriptionPlan.business:
        return 'Business';
    }
  }

  /// Get plan price
  int get planPrice {
    switch (plan) {
      case SubscriptionPlan.free:
        return 0;
      case SubscriptionPlan.pro:
        return 299;
      case SubscriptionPlan.business:
        return 999;
    }
  }

  /// Get bills limit for plan
  int get billsLimit {
    switch (plan) {
      case SubscriptionPlan.free:
        return 50;
      case SubscriptionPlan.pro:
        return 500;
      case SubscriptionPlan.business:
        return 999999;
    }
  }

  bool get isActive =>
      status == SubscriptionStatus.active || status == SubscriptionStatus.trial;
}

/// User limits tracking
class UserLimits {
  final int billsThisMonth;
  final int billsLimit;
  final int productsCount;
  final int customersCount;

  const UserLimits({
    this.billsThisMonth = 0,
    this.billsLimit = 50,
    this.productsCount = 0,
    this.customersCount = 0,
  });

  factory UserLimits.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const UserLimits();
    return UserLimits(
      billsThisMonth: map['billsThisMonth'] as int? ?? 0,
      billsLimit: map['billsLimit'] as int? ?? 50,
      productsCount: map['productsCount'] as int? ?? 0,
      customersCount: map['customersCount'] as int? ?? 0,
    );
  }

  double get usagePercentage =>
      billsLimit > 0 ? (billsThisMonth / billsLimit).clamp(0.0, 1.0) : 0.0;
  bool get isNearLimit => usagePercentage > 0.8;
  bool get isAtLimit => billsThisMonth >= billsLimit;
}

/// User activity tracking
class UserActivity {
  final DateTime? lastActiveAt;
  final String? appVersion;
  final String? platform;

  const UserActivity({this.lastActiveAt, this.appVersion, this.platform});

  factory UserActivity.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const UserActivity();
    return UserActivity(
      lastActiveAt: (map['lastActiveAt'] as Timestamp?)?.toDate(),
      appVersion: map['appVersion'] as String?,
      platform: map['platform'] as String?,
    );
  }

  /// Check if user was active today
  bool get isActiveToday {
    if (lastActiveAt == null) return false;
    final now = DateTime.now();
    return lastActiveAt!.year == now.year &&
        lastActiveAt!.month == now.month &&
        lastActiveAt!.day == now.day;
  }

  /// Check if user was active this week
  bool get isActiveThisWeek {
    if (lastActiveAt == null) return false;
    return DateTime.now().difference(lastActiveAt!).inDays < 7;
  }

  /// Get time ago string
  String get lastActiveAgo {
    if (lastActiveAt == null) return 'Never';
    final diff = DateTime.now().difference(lastActiveAt!);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

/// Complete admin user model
class AdminUser {
  final String id;
  final String email;
  final String shopName;
  final String ownerName;
  final String? phone;
  final String? address;
  final String? gstNumber;
  final DateTime? createdAt;
  final UserSubscription subscription;
  final UserLimits limits;
  final UserActivity activity;

  const AdminUser({
    required this.id,
    required this.email,
    required this.shopName,
    required this.ownerName,
    this.phone,
    this.address,
    this.gstNumber,
    this.createdAt,
    this.subscription = const UserSubscription(),
    this.limits = const UserLimits(),
    this.activity = const UserActivity(),
  });

  factory AdminUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AdminUser(
      id: doc.id,
      email: data['email'] as String? ?? '',
      shopName: data['shopName'] as String? ?? 'Unknown Shop',
      ownerName: data['ownerName'] as String? ?? 'Unknown',
      phone: data['phone'] as String?,
      address: data['address'] as String?,
      gstNumber: data['gstNumber'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      subscription: UserSubscription.fromMap(
        data['subscription'] as Map<String, dynamic>?,
      ),
      limits: UserLimits.fromMap(data['limits'] as Map<String, dynamic>?),
      activity: UserActivity.fromMap(data['activity'] as Map<String, dynamic>?),
    );
  }

  /// Get days since registration
  int get daysSinceRegistration {
    if (createdAt == null) return 0;
    return DateTime.now().difference(createdAt!).inDays;
  }
}

/// Dashboard statistics model
class AdminStats {
  final int totalUsers;
  final int activeToday;
  final int activeThisWeek;
  final int activeThisMonth;
  final int newUsersToday;
  final int newUsersThisWeek;
  final double mrr; // Monthly Recurring Revenue
  final int freeUsers;
  final int proUsers;
  final int businessUsers;

  const AdminStats({
    this.totalUsers = 0,
    this.activeToday = 0,
    this.activeThisWeek = 0,
    this.activeThisMonth = 0,
    this.newUsersToday = 0,
    this.newUsersThisWeek = 0,
    this.mrr = 0,
    this.freeUsers = 0,
    this.proUsers = 0,
    this.businessUsers = 0,
  });

  int get paidUsers => proUsers + businessUsers;
  double get conversionRate =>
      totalUsers > 0 ? (paidUsers / totalUsers) * 100 : 0;
}
