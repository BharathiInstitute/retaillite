/// Notification data model
library;

import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { announcement, alert, reminder, system }

enum NotificationTargetType { all, user, plan }

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationTargetType targetType;
  final String? targetUserId;
  final String? targetPlan;
  final DateTime createdAt;
  final String sentBy;
  final Map<String, dynamic>? data;
  final bool read;
  final DateTime? readAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.targetType,
    this.targetUserId,
    this.targetPlan,
    required this.createdAt,
    required this.sentBy,
    this.data,
    this.read = false,
    this.readAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: (d['title'] as String?) ?? '',
      body: (d['body'] as String?) ?? '',
      type: _parseType(d['type']),
      targetType: _parseTargetType(d['targetType']),
      targetUserId: d['targetUserId'] as String?,
      targetPlan: d['targetPlan'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sentBy: (d['sentBy'] as String?) ?? 'system',
      data: d['data'] as Map<String, dynamic>?,
      read: (d['read'] as bool?) ?? false,
      readAt: (d['readAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Create from user's personal notification subcollection
  /// Merges data from parent notification + user-specific read status
  factory NotificationModel.fromUserNotification(
    DocumentSnapshot userDoc,
    Map<String, dynamic>? parentData,
  ) {
    final d = userDoc.data() as Map<String, dynamic>;
    final parent = parentData ?? {};
    return NotificationModel(
      id: userDoc.id,
      title: ((parent['title'] ?? d['title']) as String?) ?? '',
      body: ((parent['body'] ?? d['body']) as String?) ?? '',
      type: _parseType(parent['type'] ?? d['type']),
      targetType: _parseTargetType(parent['targetType'] ?? d['targetType']),
      targetUserId: (parent['targetUserId'] ?? d['targetUserId']) as String?,
      targetPlan: (parent['targetPlan'] ?? d['targetPlan']) as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sentBy: ((parent['sentBy'] ?? d['sentBy']) as String?) ?? 'system',
      data:
          parent['data'] as Map<String, dynamic>? ??
          d['data'] as Map<String, dynamic>?,
      read: (d['read'] as bool?) ?? false,
      readAt: (d['readAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'body': body,
    'type': type.name,
    'targetType': targetType.name,
    if (targetUserId != null) 'targetUserId': targetUserId,
    if (targetPlan != null) 'targetPlan': targetPlan,
    'createdAt': FieldValue.serverTimestamp(),
    'sentBy': sentBy,
    if (data != null) 'data': data,
  };

  /// Data for user's personal subcollection entry
  Map<String, dynamic> toUserNotification() => {
    'title': title,
    'body': body,
    'type': type.name,
    'targetType': targetType.name,
    'sentBy': sentBy,
    'read': false,
    'readAt': null,
    'createdAt': FieldValue.serverTimestamp(),
    if (data != null) 'data': data,
  };

  NotificationModel copyWith({bool? read, DateTime? readAt}) =>
      NotificationModel(
        id: id,
        title: title,
        body: body,
        type: type,
        targetType: targetType,
        targetUserId: targetUserId,
        targetPlan: targetPlan,
        createdAt: createdAt,
        sentBy: sentBy,
        data: data,
        read: read ?? this.read,
        readAt: readAt ?? this.readAt,
      );

  static NotificationType _parseType(dynamic value) {
    if (value is String) {
      return NotificationType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => NotificationType.system,
      );
    }
    return NotificationType.system;
  }

  static NotificationTargetType _parseTargetType(dynamic value) {
    if (value is String) {
      return NotificationTargetType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => NotificationTargetType.all,
      );
    }
    return NotificationTargetType.all;
  }
}
