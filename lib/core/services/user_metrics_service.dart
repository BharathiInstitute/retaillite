/// User metrics service for tracking activity and syncing to Firestore
/// This data is used by the Super Admin Panel
library;

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Subscription plans
enum SubscriptionPlan { free, pro, business }

/// Subscription status
enum SubscriptionStatus { active, trial, expired, cancelled }

/// User subscription model
class UserSubscription {
  final SubscriptionPlan plan;
  final SubscriptionStatus status;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final String? razorpayCustomerId;
  final String? razorpaySubscriptionId;

  UserSubscription({
    this.plan = SubscriptionPlan.free,
    this.status = SubscriptionStatus.active,
    this.startedAt,
    this.expiresAt,
    this.razorpayCustomerId,
    this.razorpaySubscriptionId,
  });

  Map<String, dynamic> toMap() => {
    'plan': plan.name,
    'status': status.name,
    'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
    'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    'razorpayCustomerId': razorpayCustomerId,
    'razorpaySubscriptionId': razorpaySubscriptionId,
  };

  factory UserSubscription.fromMap(Map<String, dynamic>? map) {
    if (map == null) return UserSubscription();
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
      razorpayCustomerId: map['razorpayCustomerId'] as String?,
      razorpaySubscriptionId: map['razorpaySubscriptionId'] as String?,
    );
  }

  /// Get plan limits
  int get billsLimit {
    switch (plan) {
      case SubscriptionPlan.free:
        return 50;
      case SubscriptionPlan.pro:
        return 500;
      case SubscriptionPlan.business:
        return 999999; // Unlimited
    }
  }

  int get productsLimit {
    switch (plan) {
      case SubscriptionPlan.free:
        return 100;
      case SubscriptionPlan.pro:
      case SubscriptionPlan.business:
        return 999999; // Unlimited
    }
  }

  bool get isActive =>
      status == SubscriptionStatus.active || status == SubscriptionStatus.trial;
}

/// User activity tracking
class UserActivity {
  final DateTime? lastActiveAt;
  final String? appVersion;
  final String? platform;
  final String? deviceModel;

  UserActivity({
    this.lastActiveAt,
    this.appVersion,
    this.platform,
    this.deviceModel,
  });

  Map<String, dynamic> toMap() => {
    'lastActiveAt': lastActiveAt != null
        ? Timestamp.fromDate(lastActiveAt!)
        : FieldValue.serverTimestamp(),
    'appVersion': appVersion,
    'platform': platform,
    'deviceModel': deviceModel,
  };
}

/// User limits tracking
class UserLimits {
  final int billsThisMonth;
  final int billsLimit;
  final int productsCount;
  final int productsLimit;
  final int customersCount;

  UserLimits({
    this.billsThisMonth = 0,
    this.billsLimit = 50,
    this.productsCount = 0,
    this.productsLimit = 100,
    this.customersCount = 0,
  });

  Map<String, dynamic> toMap() => {
    'billsThisMonth': billsThisMonth,
    'billsLimit': billsLimit,
    'productsCount': productsCount,
    'productsLimit': productsLimit,
    'customersCount': customersCount,
  };

  factory UserLimits.fromMap(Map<String, dynamic>? map) {
    if (map == null) return UserLimits();
    return UserLimits(
      billsThisMonth: (map['billsThisMonth'] as int?) ?? 0,
      billsLimit: (map['billsLimit'] as int?) ?? 50,
      productsCount: (map['productsCount'] as int?) ?? 0,
      productsLimit: (map['productsLimit'] as int?) ?? 100,
      customersCount: (map['customersCount'] as int?) ?? 0,
    );
  }

  bool get canCreateBill => billsThisMonth < billsLimit;
  bool get canAddProduct => productsCount < productsLimit;
  int get billsRemaining => billsLimit - billsThisMonth;
}

/// Service for tracking user metrics and syncing to Firestore
class UserMetricsService {
  UserMetricsService._();

  static String _appVersion = '1.0.0';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static SharedPreferences? _prefs;

  // Local cache keys
  static const String _billsThisMonthKey = 'bills_this_month';
  static const String _lastResetMonthKey = 'last_reset_month';
  static const String _userIdKey = 'user_id';

  /// Initialize
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    // Get real version from PackageInfo
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = '${info.version}+${info.buildNumber}';
    } catch (_) {
      // Fallback stays at '1.0.0'
    }
  }

  /// Get current user ID (from auth or settings)
  static String? _getUserId() {
    // Try Firebase Auth first
    final user = _auth.currentUser;
    if (user != null) return user.uid;
    // Fallback to stored user ID
    return _prefs?.getString(_userIdKey);
  }

  /// Track user activity (call on app launch and key actions)
  static Future<void> trackActivity() async {
    final userId = _getUserId();
    if (userId == null) return;

    try {
      String platform = 'unknown';

      if (!kIsWeb) {
        if (Platform.isAndroid) {
          platform = 'android';
        } else if (Platform.isIOS) {
          platform = 'ios';
        } else if (Platform.isWindows) {
          platform = 'windows';
        } else if (Platform.isMacOS) {
          platform = 'macos';
        } else if (Platform.isLinux) {
          platform = 'linux';
        }
      } else {
        platform = 'web';
      }

      await _firestore.collection('users').doc(userId).set({
        'activity': {
          'lastActiveAt': FieldValue.serverTimestamp(),
          'appVersion': _appVersion,
          'platform': platform,
        },
      }, SetOptions(merge: true));

      debugPrint('📊 UserMetrics: Activity tracked');
    } catch (e) {
      debugPrint('❌ UserMetrics: Failed to track activity: $e');
    }
  }

  /// Track bill creation (increments monthly counter)
  static Future<bool> trackBillCreated() async {
    final userId = _getUserId();
    if (userId == null) return true; // Allow if not logged in

    // Check and reset monthly counter
    await _checkMonthlyReset();

    // Get current limit
    final limits = await getUserLimits();
    if (!limits.canCreateBill) {
      debugPrint('⚠️ UserMetrics: Bill limit reached');
      return false;
    }

    try {
      // Update Firestore
      await _firestore.collection('users').doc(userId).set({
        'limits': {'billsThisMonth': FieldValue.increment(1)},
        'activity': {'lastActiveAt': FieldValue.serverTimestamp()},
      }, SetOptions(merge: true));

      // Update local cache
      final current = _prefs?.getInt(_billsThisMonthKey) ?? 0;
      await _prefs?.setInt(_billsThisMonthKey, current + 1);

      debugPrint(
        '📊 UserMetrics: Bill tracked (${current + 1}/${limits.billsLimit})',
      );
      return true;
    } catch (e) {
      debugPrint('❌ UserMetrics: Failed to track bill: $e');
      return true; // Don't block on error
    }
  }

  /// Track product added
  static Future<void> trackProductAdded() async {
    final userId = _getUserId();
    if (userId == null) return;

    try {
      await _firestore.collection('users').doc(userId).set({
        'limits': {'productsCount': FieldValue.increment(1)},
      }, SetOptions(merge: true));
      debugPrint('📊 UserMetrics: Product tracked');
    } catch (e) {
      debugPrint('❌ UserMetrics: Failed to track product: $e');
    }
  }

  /// Track product deleted
  static Future<void> trackProductDeleted() async {
    final userId = _getUserId();
    if (userId == null) return;

    try {
      await _firestore.collection('users').doc(userId).set({
        'limits': {'productsCount': FieldValue.increment(-1)},
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('❌ UserMetrics: Failed to track product deletion: $e');
    }
  }

  /// Track customer added
  static Future<void> trackCustomerAdded() async {
    final userId = _getUserId();
    if (userId == null) return;

    try {
      await _firestore.collection('users').doc(userId).set({
        'limits': {'customersCount': FieldValue.increment(1)},
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('❌ UserMetrics: Failed to track customer: $e');
    }
  }

  /// Get user's current limits
  static Future<UserLimits> getUserLimits() async {
    final userId = _getUserId();
    if (userId == null) return UserLimits();

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return UserLimits();

      final data = doc.data();
      return UserLimits.fromMap(data?['limits'] as Map<String, dynamic>?);
    } catch (e) {
      debugPrint('❌ UserMetrics: Failed to get limits: $e');
      return UserLimits();
    }
  }

  /// Get user's subscription
  static Future<UserSubscription> getUserSubscription() async {
    final userId = _getUserId();
    if (userId == null) return UserSubscription();

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return UserSubscription();

      final data = doc.data();
      return UserSubscription.fromMap(
        data?['subscription'] as Map<String, dynamic>?,
      );
    } catch (e) {
      debugPrint('❌ UserMetrics: Failed to get subscription: $e');
      return UserSubscription();
    }
  }

  /// Check and reset monthly counters
  static Future<void> _checkMonthlyReset() async {
    _prefs ??= await SharedPreferences.getInstance();
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final lastResetMonth = _prefs?.getString(_lastResetMonthKey);

    if (lastResetMonth != currentMonth) {
      // New month, reset counters
      await _prefs?.setInt(_billsThisMonthKey, 0);
      await _prefs?.setString(_lastResetMonthKey, currentMonth);

      // Reset in Firestore too
      final userId = _getUserId();
      if (userId != null) {
        await _firestore.collection('users').doc(userId).set({
          'limits': {'billsThisMonth': 0},
        }, SetOptions(merge: true));
      }

      debugPrint('📊 UserMetrics: Monthly counters reset for $currentMonth');
    }
  }

  /// Initialize user document with default values
  static Future<void> initializeUser({
    required String userId,
    required String email,
    required String shopName,
    required String ownerName,
    String? phone,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'email': email,
        'shopName': shopName,
        'ownerName': ownerName,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
        'subscription': UserSubscription().toMap(),
        'limits': UserLimits().toMap(),
        'activity': {
          'lastActiveAt': FieldValue.serverTimestamp(),
          'appVersion': _appVersion,
          'platform': kIsWeb
              ? 'web'
              : (Platform.isAndroid
                    ? 'android'
                    : (Platform.isWindows ? 'windows' : 'ios')),
        },
      }, SetOptions(merge: true));

      // Save user ID locally
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.setString(_userIdKey, userId);

      debugPrint('📊 UserMetrics: User initialized in Firestore');
    } catch (e) {
      debugPrint('❌ UserMetrics: Failed to initialize user: $e');
    }
  }
}
