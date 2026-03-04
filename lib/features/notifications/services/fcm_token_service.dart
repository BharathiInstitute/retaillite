/// FCM Token Service — saves device FCM token to Firestore for push notifications
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FCMTokenService {
  static FirebaseMessaging? _messagingInstance;
  static FirebaseMessaging get _messaging =>
      _messagingInstance ??= FirebaseMessaging.instance;
  static final _firestore = FirebaseFirestore.instance;
  static StreamSubscription<String>? _tokenRefreshSub;

  /// Request notification permission and save the FCM token for this user.
  /// Call this after login / on app start.
  static Future<void> initAndSaveToken(String userId) async {
    try {
      // Skip on Windows — FCM not supported
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) return;

      // Request permission (Android 13+, iOS, Web)
      final settings = await _messaging.requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('🔕 FCM permission denied');
        return;
      }

      // Get the token
      String? token;
      if (kIsWeb) {
        token = await _messaging.getToken(
          vapidKey: const String.fromEnvironment(
            'VAPID_KEY',
            defaultValue:
                'BJWGlSt5rrtGMA46BnzYfeNBAGNRRIchhSlu2pqVs-V0lH6TH715-qVarkTtZy_GU7HxA7aOFDbatD2WXwuYldc',
          ),
        );
      } else {
        token = await _messaging.getToken();
      }

      if (token == null) {
        debugPrint('⚠️ FCM token is null');
        return;
      }

      debugPrint('📱 FCM token: ${token.substring(0, 20)}...');

      // Save token to Firestore under the user's document
      await _firestore.collection('users').doc(userId).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ FCM token saved for user $userId');

      // Listen for token refresh (cancel previous listener first)
      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('🔄 FCM token refreshed');
        await _firestore.collection('users').doc(userId).set({
          'fcmTokens': FieldValue.arrayUnion([newToken]),
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint('❌ FCM token error: $e');
    }
  }

  /// Remove current device token on logout
  static Future<void> removeToken(String userId) async {
    try {
      // Cancel token refresh listener
      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = null;

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) return;

      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmTokens': FieldValue.arrayRemove([token]),
        });
        debugPrint('🗑️ FCM token removed for user $userId');
      }
    } catch (e) {
      debugPrint('❌ FCM token removal error: $e');
    }
  }
}
