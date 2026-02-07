/// Analytics and monitoring service for app health and crash reporting
library;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

/// Service for analytics, crash reporting, and performance monitoring
class AnalyticsService {
  AnalyticsService._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  static final FirebasePerformance _performance = FirebasePerformance.instance;

  // ==================== Initialization ====================

  /// Initialize all monitoring services
  static Future<void> initialize() async {
    // Enable crashlytics collection
    await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

    // Set default analytics consent
    await _analytics.setAnalyticsCollectionEnabled(true);

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
    if (userId != null) {
      await _analytics.setUserId(id: userId);
      await _crashlytics.setUserIdentifier(userId);
    }

    if (shopName != null) {
      await _analytics.setUserProperty(name: 'shop_name', value: shopName);
    }

    if (subscriptionTier != null) {
      await _analytics.setUserProperty(
        name: 'subscription_tier',
        value: subscriptionTier,
      );
    }

    if (isDemoMode != null) {
      await _analytics.setUserProperty(
        name: 'is_demo_mode',
        value: isDemoMode.toString(),
      );
    }
  }

  // ==================== Screen Tracking ====================

  /// Log screen view
  static Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  // ==================== Business Events ====================

  /// Log bill creation
  static Future<void> logBillCreated({
    required double amount,
    required int itemCount,
    required String paymentMode,
  }) async {
    await _analytics.logEvent(
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
    await _analytics.logEvent(
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
    await _analytics.logEvent(name: 'customer_added');
  }

  /// Log report generated
  static Future<void> logReportGenerated({required String reportType}) async {
    await _analytics.logEvent(
      name: 'report_generated',
      parameters: {'report_type': reportType},
    );
  }

  /// Log sync completed
  static Future<void> logSyncCompleted({required int itemsSynced}) async {
    await _analytics.logEvent(
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
    await _crashlytics.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: fatal,
    );
  }

  /// Log a custom message to crashlytics
  static Future<void> log(String message) async {
    _crashlytics.log(message);
  }

  // ==================== Performance Monitoring ====================

  /// Start a custom trace for performance monitoring
  static Future<Trace> startTrace(String name) async {
    final trace = _performance.newTrace(name);
    await trace.start();
    return trace;
  }

  /// Create HTTP metric for API performance
  static HttpMetric newHttpMetric(String url, HttpMethod method) {
    return _performance.newHttpMetric(url, method);
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
