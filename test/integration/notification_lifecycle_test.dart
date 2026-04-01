/// Integration tests for notification lifecycle — end-to-end notification flow.
///
/// Tests the complete notification lifecycle:
///   1. Admin sends notification → stored in Firestore
///   2. User receives notification → appears in stream
///   3. User reads notification → marked as read
///   4. User deletes notification → removed from stream
///
/// Uses FakeFirebaseFirestore for the Firestore layer.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/features/notifications/models/notification_model.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  // ── Full notification lifecycle via FakeFirestore ──

  group('Notification lifecycle', () {
    test('send → receive → read → delete cycle', () async {
      const userId = 'user1';
      final notifRef = fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications');

      // 1. Send notification
      final docRef = await notifRef.add({
        'title': 'Welcome',
        'body': 'Thanks for joining!',
        'type': 'announcement',
        'targetType': 'user',
        'sentBy': 'admin',
        'read': false,
        'readAt': null,
        'createdAt': Timestamp.fromDate(DateTime(2026, 4)),
      });

      // 2. Verify it exists
      final snap = await notifRef.get();
      expect(snap.docs.length, 1);
      final model = NotificationModel.fromFirestore(snap.docs.first);
      expect(model.title, 'Welcome');
      expect(model.read, isFalse);

      // 3. Mark as read
      await docRef.update({
        'read': true,
        'readAt': Timestamp.fromDate(DateTime(2026, 4, 1, 10)),
      });
      final readDoc = await docRef.get();
      final readModel = NotificationModel.fromFirestore(readDoc);
      expect(readModel.read, isTrue);

      // 4. Delete
      await docRef.delete();
      final afterDelete = await notifRef.get();
      expect(afterDelete.docs, isEmpty);
    });

    test('unread count decreases when notification is read', () async {
      const userId = 'user1';
      final notifRef = fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications');

      // Add 3 unread notifications
      for (var i = 0; i < 3; i++) {
        await notifRef.add({
          'title': 'Notif $i',
          'body': 'Body $i',
          'type': 'system',
          'read': false,
          'createdAt': Timestamp.fromDate(DateTime(2026, 4, 1, i)),
        });
      }

      // Count unread
      var unread = await notifRef.where('read', isEqualTo: false).get();
      expect(unread.docs.length, 3);

      // Mark first as read
      await unread.docs.first.reference.update({'read': true});
      unread = await notifRef.where('read', isEqualTo: false).get();
      expect(unread.docs.length, 2);
    });

    test('markAllAsRead batch updates all unread notifications', () async {
      const userId = 'user1';
      final notifRef = fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications');

      // Add mix of read and unread
      await notifRef.add({
        'title': 'A',
        'read': false,
        'createdAt': Timestamp.now(),
      });
      await notifRef.add({
        'title': 'B',
        'read': false,
        'createdAt': Timestamp.now(),
      });
      await notifRef.add({
        'title': 'C',
        'read': true,
        'createdAt': Timestamp.now(),
      });

      // Batch mark all unread as read
      final unread = await notifRef.where('read', isEqualTo: false).get();
      final batch = fakeFirestore.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();

      // All should be read now
      final afterMark = await notifRef.where('read', isEqualTo: false).get();
      expect(afterMark.docs, isEmpty);

      final allNotifs = await notifRef.get();
      expect(allNotifs.docs.length, 3); // nothing deleted
    });
  });

  // ── Notification ordering ──

  group('Notification ordering', () {
    test('notifications ordered by createdAt descending', () async {
      const userId = 'user1';
      final notifRef = fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications');

      await notifRef.add({
        'title': 'Old',
        'createdAt': Timestamp.fromDate(DateTime(2026, 3)),
      });
      await notifRef.add({
        'title': 'New',
        'createdAt': Timestamp.fromDate(DateTime(2026, 4)),
      });
      await notifRef.add({
        'title': 'Mid',
        'createdAt': Timestamp.fromDate(DateTime(2026, 3, 15)),
      });

      final snap = await notifRef.orderBy('createdAt', descending: true).get();

      expect(snap.docs[0].data()['title'], 'New');
      expect(snap.docs[1].data()['title'], 'Mid');
      expect(snap.docs[2].data()['title'], 'Old');
    });
  });

  // ── Send to selected users ──

  group('Send to selected users', () {
    test('creates notification in each user subcollection', () async {
      final userIds = ['user1', 'user2', 'user3'];
      final notification = NotificationModel(
        id: '',
        title: 'Broadcast',
        body: 'Hello everyone',
        type: NotificationType.announcement,
        targetType: NotificationTargetType.all,
        createdAt: DateTime(2026, 4),
        sentBy: 'admin',
      );

      // Simulate sendToSelectedUsers
      final batch = fakeFirestore.batch();
      for (final userId in userIds) {
        final ref = fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc();
        batch.set(ref, notification.toUserNotification());
      }
      await batch.commit();

      // Verify each user got the notification
      for (final userId in userIds) {
        final snap = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .get();
        expect(snap.docs.length, 1);
        expect(snap.docs.first.data()['title'], 'Broadcast');
      }
    });

    test('global notification history is saved', () async {
      // Simulate saving to global notifications collection
      final ref = await fakeFirestore.collection('notifications').add({
        'title': 'Global Announcement',
        'body': 'For history',
        'type': 'announcement',
        'targetType': 'all',
        'sentBy': 'admin',
        'recipientCount': 100,
      });

      final doc = await ref.get();
      expect(doc.data()?['recipientCount'], 100);
      expect(doc.data()?['title'], 'Global Announcement');
    });
  });
}
