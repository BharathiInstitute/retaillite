/// Notification Firestore Service — CRUD for notifications
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:retaillite/features/notifications/models/notification_model.dart';

class NotificationFirestoreService {
  static final _firestore = FirebaseFirestore.instance;

  /// Get user's notifications stream (real-time)
  static Stream<List<NotificationModel>> getUserNotificationsStream(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get unread notification count stream
  static Stream<int> getUnreadCountStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.size);
  }

  /// Mark a single notification as read
  static Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true, 'readAt': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint('❌ Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final unread = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .get();

      for (final doc in unread.docs) {
        batch.update(doc.reference, {
          'read': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint('❌ Failed to mark all as read: $e');
    }
  }

  /// Delete a notification
  static Future<void> deleteNotification(
    String userId,
    String notificationId,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      debugPrint('❌ Failed to delete notification: $e');
    }
  }

  /// Send notification to a specific user
  static Future<void> sendToUser({
    required String userId,
    required NotificationModel notification,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add(notification.toUserNotification());
    } catch (e) {
      debugPrint('❌ Failed to send notification to user: $e');
    }
  }

  /// Send notification to ALL users (fan-out)
  static Future<int> sendToAllUsers({
    required NotificationModel notification,
  }) async {
    DocumentReference? globalRef;
    try {
      // Save to global notifications collection for admin history
      globalRef = await _firestore
          .collection('notifications')
          .add(notification.toFirestore());

      // Get all user IDs
      final usersSnap = await _firestore.collection('users').get();
      debugPrint('📋 Found ${usersSnap.docs.length} users in collection');

      if (usersSnap.docs.isEmpty) {
        await globalRef.update({
          'recipientCount': 0,
          'sentAt': FieldValue.serverTimestamp(),
          'error': 'No users found in collection',
        });
        return 0;
      }

      var batch = _firestore.batch();
      int count = 0;

      for (final userDoc in usersSnap.docs) {
        final userNotifRef = _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('notifications')
            .doc();

        batch.set(userNotifRef, {
          ...notification.toUserNotification(),
          'globalNotificationId': globalRef.id,
        });
        count++;

        if (count % 450 == 0) {
          await batch.commit();
          batch = _firestore.batch();
        }
      }

      if (count % 450 != 0) {
        await batch.commit();
      }

      await globalRef.update({
        'recipientCount': count,
        'sentAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Notification sent to $count users');
      return count;
    } catch (e, st) {
      debugPrint('❌ Failed to send to all users: $e\n$st');
      // Mark global doc as failed so it doesn't show "Processing..." forever
      if (globalRef != null) {
        try {
          await globalRef.update({
            'recipientCount': 0,
            'sentAt': FieldValue.serverTimestamp(),
            'error': e.toString(),
          });
        } catch (_) {}
      }
      rethrow;
    }
  }

  /// Send notification to users with a specific plan
  static Future<int> sendToPlanUsers({
    required String plan,
    required NotificationModel notification,
  }) async {
    DocumentReference? globalRef;
    try {
      globalRef = await _firestore
          .collection('notifications')
          .add(notification.toFirestore());

      final usersSnap = await _firestore
          .collection('users')
          .where('subscription.plan', isEqualTo: plan)
          .get();

      debugPrint('📋 Found ${usersSnap.docs.length} users with plan: $plan');

      if (usersSnap.docs.isEmpty) {
        await globalRef.update({
          'recipientCount': 0,
          'sentAt': FieldValue.serverTimestamp(),
          'error': 'No users found with plan: $plan',
        });
        return 0;
      }

      var batch = _firestore.batch();
      int count = 0;

      for (final userDoc in usersSnap.docs) {
        final userNotifRef = _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('notifications')
            .doc();

        batch.set(userNotifRef, {
          ...notification.toUserNotification(),
          'globalNotificationId': globalRef.id,
        });
        count++;

        if (count % 450 == 0) {
          await batch.commit();
          batch = _firestore.batch();
        }
      }

      if (count % 450 != 0) {
        await batch.commit();
      }

      await globalRef.update({
        'recipientCount': count,
        'sentAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Notification sent to $count $plan users');
      return count;
    } catch (e, st) {
      debugPrint('❌ Failed to send to plan users: $e\n$st');
      if (globalRef != null) {
        try {
          await globalRef.update({
            'recipientCount': 0,
            'sentAt': FieldValue.serverTimestamp(),
            'error': e.toString(),
          });
        } catch (_) {}
      }
      rethrow;
    }
  }

  /// Send notification to a list of selected users
  static Future<int> sendToSelectedUsers({
    required List<String> userIds,
    required NotificationModel notification,
  }) async {
    DocumentReference? globalRef;
    try {
      // Save to global history
      globalRef = await _firestore
          .collection('notifications')
          .add(notification.toFirestore());

      var batch = _firestore.batch();
      int count = 0;

      for (final userId in userIds) {
        final userNotifRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc();

        batch.set(userNotifRef, {
          ...notification.toUserNotification(),
          'globalNotificationId': globalRef.id,
        });
        count++;

        if (count % 450 == 0) {
          await batch.commit();
          batch = _firestore.batch();
        }
      }

      if (count % 450 != 0) {
        await batch.commit();
      }

      await globalRef.update({
        'recipientCount': count,
        'sentAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Notification sent to $count selected users');
      return count;
    } catch (e, st) {
      debugPrint('❌ Failed to send to selected users: $e\n$st');
      if (globalRef != null) {
        try {
          await globalRef.update({
            'recipientCount': 0,
            'sentAt': FieldValue.serverTimestamp(),
            'error': e.toString(),
          });
        } catch (_) {}
      }
      rethrow;
    }
  }

  /// Search users by name, email, or shop name (for user picker)
  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final snap = await _firestore.collection('users').get();
      final q = query.toLowerCase();
      return snap.docs
          .where((doc) {
            final data = doc.data();
            final name = (data['ownerName'] as String? ?? '').toLowerCase();
            final email = (data['email'] as String? ?? '').toLowerCase();
            final shop = (data['shopName'] as String? ?? '').toLowerCase();
            return name.contains(q) || email.contains(q) || shop.contains(q);
          })
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to search users: $e');
      return [];
    }
  }

  /// Get all users (for user picker)
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snap = await _firestore.collection('users').get();
      return snap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('❌ Failed to get all users: $e');
      return [];
    }
  }

  /// Get global notification history (for admin panel)
  static Future<List<Map<String, dynamic>>> getNotificationHistory({
    int limit = 50,
  }) async {
    try {
      // Force server fetch to ensure newly-written docs are included
      final snap = await _firestore
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get(const GetOptions(source: Source.server));

      return snap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('❌ Failed to get notification history from server: $e');
      // Fallback to default (cache + server) if server-only fails
      try {
        final snap = await _firestore
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get();
        return snap.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      } catch (_) {
        return [];
      }
    }
  }
}
