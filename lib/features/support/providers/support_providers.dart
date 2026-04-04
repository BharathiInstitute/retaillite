/// Support providers — store-side ticket & message streams
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/features/support/models/support_ticket.dart';
import 'package:retaillite/features/support/services/support_service.dart';

/// Stream of current user's support tickets
final myTicketsProvider = StreamProvider<List<SupportTicket>>((ref) {
  return SupportService.getMyTicketsStream();
});

/// Stream of messages for a given ticket
final ticketMessagesProvider = StreamProvider.family<List<ChatMessage>, String>(
  (ref, ticketId) {
    return SupportService.getMessagesStream(ticketId);
  },
);

/// Unread support ticket count (for badge)
final supportUnreadCountProvider = StreamProvider<int>((ref) {
  return SupportService.getUnreadCountStream();
});
