/// Push Notification Service — handles FCM foreground/background messages
library;

import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Top-level handler for background messages (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 Background message: ${message.notification?.title}');
  // Background messages auto-show a system notification on Android/Web.
  // No special handling needed unless you want to customize behavior.
}

class NotificationService {
  static FirebaseMessaging? _messagingInstance;
  static FirebaseMessaging get _messaging =>
      _messagingInstance ??= FirebaseMessaging.instance;

  /// Initialize FCM message listeners. Call once from main() or app init.
  static void initMessageListeners({
    void Function(RemoteMessage)? onMessage,
    void Function(RemoteMessage)? onMessageOpenedApp,
  }) {
    // Skip on Windows — no FCM support
    if (!kIsWeb && Platform.isWindows) return;

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📬 Foreground message: ${message.notification?.title}');
      onMessage?.call(message);
    });

    // When app is opened from a notification tap (background → foreground)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📬 Message opened app: ${message.notification?.title}');
      onMessageOpenedApp?.call(message);
    });

    // Check if app was opened from a terminated state via notification
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint('📬 Initial message: ${message.notification?.title}');
        onMessageOpenedApp?.call(message);
      }
    });
  }

  /// Set foreground notification presentation options (iOS / Web)
  static Future<void> setForegroundOptions() async {
    if (!kIsWeb && Platform.isWindows) return;

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }
}
