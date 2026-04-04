/// Shared chat screen — used by both store and admin sides
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:retaillite/features/support/models/support_ticket.dart';
import 'package:retaillite/features/support/providers/support_providers.dart';
import 'package:retaillite/features/support/services/support_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String ticketId;

  /// 'store' or 'admin' — determines send behavior and styling
  final String viewerRole;

  /// Optional: for admin side, pass a callback to send admin messages
  final Future<bool> Function(String ticketId, String text)? onSendAdmin;

  /// Optional: callback when admin marks ticket read
  final VoidCallback? onOpen;

  const ChatScreen({
    super.key,
    required this.ticketId,
    this.viewerRole = 'store',
    this.onSendAdmin,
    this.onOpen,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Mark as read on open
    if (widget.viewerRole == 'store') {
      SupportService.markRead(widget.ticketId);
    }
    widget.onOpen?.call();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _msgCtrl.clear();

    bool ok;
    if (widget.viewerRole == 'admin' && widget.onSendAdmin != null) {
      ok = await widget.onSendAdmin!(widget.ticketId, text);
    } else {
      ok = await SupportService.sendMessage(
        ticketId: widget.ticketId,
        text: text,
      );
    }

    if (mounted) setState(() => _sending = false);

    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to send message')));
    }
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(ticketMessagesProvider(widget.ticketId));
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Messages list
        Expanded(
          child: messagesAsync.when(
            data: (messages) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });

              if (messages.isEmpty) {
                return const Center(
                  child: Text(
                    'No messages yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final showDate =
                      index == 0 ||
                      _differentDay(
                        messages[index - 1].createdAt,
                        msg.createdAt,
                      );

                  return Column(
                    children: [
                      if (showDate && msg.createdAt != null)
                        _DateSeparator(date: msg.createdAt!),
                      if (msg.isSystem)
                        _SystemBubble(message: msg)
                      else
                        _ChatBubble(
                          message: msg,
                          isMe: msg.senderRole == widget.viewerRole,
                        ),
                    ],
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),

        // Input bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(top: BorderSide(color: cs.outlineVariant)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Type a message…',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: cs.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send, size: 20),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _differentDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return true;
    return a.year != b.year || a.month != b.month || a.day != b.day;
  }
}

// ── Chat Bubble ──

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  const _ChatBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  message.senderName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isMe ? cs.onPrimary.withAlpha(180) : cs.primary,
                  ),
                ),
              ),
            Text(
              message.text,
              style: TextStyle(
                fontSize: 14,
                color: isMe ? cs.onPrimary : cs.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              message.createdAt != null
                  ? DateFormat('h:mm a').format(message.createdAt!)
                  : '',
              style: TextStyle(
                fontSize: 10,
                color: isMe
                    ? cs.onPrimary.withAlpha(130)
                    : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── System Message ──

class _SystemBubble extends StatelessWidget {
  final ChatMessage message;
  const _SystemBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message.text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }
}

// ── Date Separator ──

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = now.difference(date);
    String label;
    if (diff.inDays == 0 && date.day == now.day) {
      label = 'Today';
    } else if (diff.inDays <= 1 && date.day == now.day - 1) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMM d, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300)),
        ],
      ),
    );
  }
}
