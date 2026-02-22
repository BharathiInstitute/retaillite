/// Notification providers — streams for real-time notification updates
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/features/notifications/models/notification_model.dart';
import 'package:retaillite/features/notifications/services/notification_firestore_service.dart';

/// Stream of user's notifications (real-time)
final notificationsStreamProvider = StreamProvider<List<NotificationModel>>((
  ref,
) {
  final authState = ref.watch(authNotifierProvider);
  final userId = authState.user?.id;

  if (userId == null) return const Stream.empty();
  return NotificationFirestoreService.getUserNotificationsStream(userId);
});

/// Unread notification count (real-time)
final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final userId = authState.user?.id;

  if (userId == null) return Stream.value(0);
  return NotificationFirestoreService.getUnreadCountStream(userId);
});
