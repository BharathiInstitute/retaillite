/// Windows Notification Service — polls Firestore for new notifications
/// and shows native Windows toast notifications.
/// This is needed because FCM (Firebase Cloud Messaging) does not support Windows.
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class WindowsNotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static final _firestore = FirebaseFirestore.instance;
  static StreamSubscription<QuerySnapshot>? _subscription;
  static bool _initialized = false;

  /// Initialize the local notifications plugin for Windows.
  static Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb || !Platform.isWindows) return;

    const windowsSettings = WindowsInitializationSettings(
      appName: 'Tulasi Stores',
      appUserModelId: 'TulasiERP.TulasiStores',
      guid: 'e031b94d-44bc-474e-a0e4-80cf69d69c2d',
    );

    const initSettings = InitializationSettings(windows: windowsSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('🔔 Windows notification tapped: ${details.payload}');
      },
    );

    _initialized = true;
    debugPrint('✅ Windows local notifications initialized');
  }

  /// Start listening for new notifications for this user.
  /// Uses a Firestore real-time listener (not polling) for instant delivery.
  static void startListening(String userId) {
    if (kIsWeb || !Platform.isWindows) return;
    if (!_initialized) {
      debugPrint('⚠️ WindowsNotificationService not initialized');
      return;
    }

    // Cancel any existing subscription
    _subscription?.cancel();

    // Listen for new unread notifications
    _subscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen(
          (snapshot) {
            for (final change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                final data = change.doc.data();
                if (data != null) {
                  _showNotification(
                    id: change.doc.id.hashCode,
                    title: (data['title'] as String?) ?? 'Notification',
                    body: (data['body'] as String?) ?? '',
                  );
                }
              }
            }
          },
          onError: (e) =>
              debugPrint('❌ Windows notification listener error: $e'),
        );

    debugPrint('🔔 Windows notification listener started for $userId');
  }

  /// Stop listening for notifications (call on logout).
  static void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    debugPrint('🔕 Windows notification listener stopped');
  }

  /// Show a native Windows toast notification.
  static Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      const windowsDetails = WindowsNotificationDetails();
      const details = NotificationDetails(windows: windowsDetails);

      await _plugin.show(id, title, body, details);
      debugPrint('🔔 Windows toast shown: $title');
    } catch (e) {
      debugPrint('❌ Failed to show Windows notification: $e');
    }
  }
}
