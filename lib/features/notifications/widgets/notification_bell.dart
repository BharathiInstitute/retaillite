/// Notification bell icon with unread badge — for AppBar
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retaillite/features/notifications/providers/notification_provider.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadNotificationCountProvider);

    return unreadAsync.when(
      data: (count) => Stack(
        children: [
          IconButton(
            icon: Icon(
              count > 0
                  ? Icons.notifications_active
                  : Icons.notifications_outlined,
              color: count > 0 ? Colors.amber : null,
            ),
            tooltip: count > 0
                ? '$count unread notifications'
                : 'Notifications',
            onPressed: () => context.push('/notifications'),
          ),
          if (count > 0)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      loading: () => IconButton(
        icon: const Icon(Icons.notifications_outlined),
        onPressed: () => context.push('/notifications'),
      ),
      error: (_, _) => IconButton(
        icon: const Icon(Icons.notifications_outlined),
        onPressed: () => context.push('/notifications'),
      ),
    );
  }
}
