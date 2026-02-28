/// Analytics and monitoring service for app health and crash reporting
library;

import 'dart:io' show Platform;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

/// Service for analytics, crash reporting, and performance monitoring
class AnalyticsService {
  AnalyticsService._();

  /// Whether analytics/performance are supported on this platform
  static final bool _isSupported =
      kIsWeb || !(Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  /// Lazy-initialized — only access on supported platforms!
  static FirebaseAnalytics? _analytics;
  static FirebaseAnalytics get _safeAnalytics =>
      _analytics ??= FirebaseAnalytics.instance;

  static FirebasePerformance? _performance;
  static FirebasePerformance get _safePerformance =>
      _performance ??= FirebasePerformance.instance;

  /// Crashlytics is NOT supported on web or Windows desktop
  static final bool _hasCrashlytics =
      !kIsWeb && !(Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  // ==================== Initialization ====================

  /// Initialize all monitoring services
  static Future<void> initialize() async {
    if (!_isSupported) {
      debugPrint('📊 AnalyticsService: Skipped on desktop (not supported)');
      return;
    }

    // Enable crashlytics collection (not supported on web)
    if (_hasCrashlytics) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        !kDebugMode,
      );
    }

    // Set default analytics consent
    await _safeAnalytics.setAnalyticsCollectionEnabled(true);

    debugPrint('📊 AnalyticsService: Initialized');
  }

  // ==================== User Properties ====================

  /// Set user properties for segmentation
  static Future<void> setUserProperties({
    required String? userId,
    String? shopName,
    String? subscriptionTier,
    bool? isDemoMode,
  }) async {
    if (!_isSupported) return;

    if (userId != null) {
      await _safeAnalytics.setUserId(id: userId);
      if (_hasCrashlytics) {
        await FirebaseCrashlytics.instance.setUserIdentifier(userId);
      }
    }

    if (shopName != null) {
      await _safeAnalytics.setUserProperty(name: 'shop_name', value: shopName);
    }

    if (subscriptionTier != null) {
      await _safeAnalytics.setUserProperty(
        name: 'subscription_tier',
        value: subscriptionTier,
      );
    }

    if (isDemoMode != null) {
      await _safeAnalytics.setUserProperty(
        name: 'is_demo_mode',
        value: isDemoMode.toString(),
      );
    }
  }

  // ==================== Screen Tracking ====================

  /// Log screen view
  static Future<void> logScreenView(String screenName) async {
    if (!_isSupported) return;
    await _safeAnalytics.logScreenView(screenName: screenName);
  }

  // ==================== Business Events ====================

  /// Log bill creation
  static Future<void> logBillCreated({
    required double amount,
    required int itemCount,
    required String paymentMode,
  }) async {
    if (!_isSupported) return;
    await _safeAnalytics.logEvent(
      name: 'bill_created',
      parameters: {
        'amount': amount,
        'item_count': itemCount,
        'payment_mode': paymentMode,
      },
    );
  }

  /// Log product added
  static Future<void> logProductAdded({
    required String productName,
    required String category,
    required double price,
  }) async {
    if (!_isSupported) return;
    await _safeAnalytics.logEvent(
      name: 'product_added',
      parameters: {
        'product_name': productName,
        'category': category,
        'price': price,
      },
    );
  }

  /// Log customer added
  static Future<void> logCustomerAdded() async {
    if (!_isSupported) return;
    await _safeAnalytics.logEvent(name: 'customer_added');
  }

  /// Log report generated
  static Future<void> logReportGenerated({required String reportType}) async {
    if (!_isSupported) return;
    await _safeAnalytics.logEvent(
      name: 'report_generated',
      parameters: {'report_type': reportType},
    );
  }

  /// Log sync completed
  static Future<void> logSyncCompleted({required int itemsSynced}) async {
    if (!_isSupported) return;
    await _safeAnalytics.logEvent(
      name: 'sync_completed',
      parameters: {'items_synced': itemsSynced},
    );
  }

  // ==================== Error Tracking ====================

  /// Log non-fatal error
  static Future<void> logError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    if (_hasCrashlytics) {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );
    }
  }

  /// Log a custom message to crashlytics
  static Future<void> log(String message) async {
    if (_hasCrashlytics) {
      await FirebaseCrashlytics.instance.log(message);
    }
  }

  // ==================== Performance Monitoring ====================

  /// Start a custom trace for performance monitoring
  static Future<Trace?> startTrace(String name) async {
    if (!_isSupported) return null;
    final trace = _safePerformance.newTrace(name);
    await trace.start();
    return trace;
  }

  /// Create HTTP metric for API performance
  static HttpMetric? newHttpMetric(String url, HttpMethod method) {
    if (!_isSupported) return null;
    return _safePerformance.newHttpMetric(url, method);
  }
}

/// Extension to easily stop traces
extension TraceExtension on Trace {
  Future<void> stopWithMetrics({Map<String, int>? metrics}) async {
    if (metrics != null) {
      for (final entry in metrics.entries) {
        setMetric(entry.key, entry.value);
      }
    }
    await stop();
  }
}
