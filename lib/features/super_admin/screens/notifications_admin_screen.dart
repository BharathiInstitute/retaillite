/// Admin Notifications Screen — compose and send notifications to users
/// Features: Templates, send to all/selected/by plan, user search & picker, history
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/features/notifications/models/notification_model.dart';
import 'package:retaillite/features/notifications/services/notification_firestore_service.dart';

// ─── Notification Templates ───
class _NotifTemplate {
  final String name;
  final String title;
  final String body;
  final NotificationType type;
  final IconData icon;

  const _NotifTemplate({
    required this.name,
    required this.title,
    required this.body,
    required this.type,
    required this.icon,
  });
}

const _templates = [
  _NotifTemplate(
    name: 'Welcome',
    title: 'Welcome to Tulasi Stores! 🎉',
    body:
        'Thank you for joining! Start by adding your products and making your first sale.',
    type: NotificationType.announcement,
    icon: Icons.celebration,
  ),
  _NotifTemplate(
    name: 'New Feature',
    title: 'New Feature Available ✨',
    body:
        'We\'ve added exciting new features. Update your app to get the latest improvements!',
    type: NotificationType.announcement,
    icon: Icons.auto_awesome,
  ),
  _NotifTemplate(
    name: 'Maintenance',
    title: 'Scheduled Maintenance 🔧',
    body:
        'We\'ll be performing maintenance on [DATE] from [TIME] to [TIME]. The app might be briefly unavailable.',
    type: NotificationType.alert,
    icon: Icons.construction,
  ),
  _NotifTemplate(
    name: 'Payment Reminder',
    title: 'Subscription Renewal Reminder 💳',
    body:
        'Your subscription expires soon. Renew now to continue enjoying premium features.',
    type: NotificationType.reminder,
    icon: Icons.payment,
  ),
  _NotifTemplate(
    name: 'Holiday',
    title: 'Happy Holidays! 🎊',
    body:
        'Wishing you and your business a wonderful holiday season. Special offers coming soon!',
    type: NotificationType.announcement,
    icon: Icons.card_giftcard,
  ),
  _NotifTemplate(
    name: 'Security',
    title: 'Security Update ⚠️',
    body:
        'Please update your password for enhanced security. Go to Settings → Account to change it.',
    type: NotificationType.alert,
    icon: Icons.security,
  ),
  _NotifTemplate(
    name: 'Tip',
    title: 'Pro Tip 💡',
    body:
        'Did you know you can scan barcodes to quickly add products? Try it from the Products screen!',
    type: NotificationType.system,
    icon: Icons.lightbulb_outline,
  ),
];

class NotificationsAdminScreen extends ConsumerStatefulWidget {
  const NotificationsAdminScreen({super.key});

  @override
  ConsumerState<NotificationsAdminScreen> createState() =>
      _NotificationsAdminScreenState();
}

class _NotificationsAdminScreenState
    extends ConsumerState<NotificationsAdminScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final history = await NotificationFirestoreService.getNotificationHistory();
    setState(() {
      _history = history;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications Manager'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadHistory),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.send), text: 'Compose'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ComposeTab(
            ref: ref,
            onSent: () {
              _loadHistory();
              _tabController.animateTo(1);
            },
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No notifications sent yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final notif = _history[index];
                      return _HistoryCard(data: notif);
                    },
                  ),
                ),
        ],
      ),
    );
  }
}

// ─── Compose Tab ───

class _ComposeTab extends StatefulWidget {
  final WidgetRef ref;
  final VoidCallback onSent;

  const _ComposeTab({required this.ref, required this.onSent});

  @override
  State<_ComposeTab> createState() => _ComposeTabState();
}

class _ComposeTabState extends State<_ComposeTab> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  var _selectedType = NotificationType.announcement;
  var _targetMode = 'all'; // 'all', 'selected', 'plan'
  var _selectedPlan = 'free';
  final _selectedUserIds = <String>{};
  final _selectedUserNames = <String, String>{}; // id -> displayName
  var _isSending = false;

  void _applyTemplate(_NotifTemplate template) {
    setState(() {
      _titleCtrl.text = template.title;
      _bodyCtrl.text = template.body;
      _selectedType = template.type;
    });
  }

  Future<void> _send() async {
    if (_titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and message are required')),
      );
      return;
    }

    if (_targetMode == 'selected' && _selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one user')),
      );
      return;
    }

    setState(() => _isSending = true);
    final messenger = ScaffoldMessenger.of(context);

    final adminEmail =
        widget.ref.read(authNotifierProvider).user?.email ?? 'admin';

    final targetType = switch (_targetMode) {
      'all' => NotificationTargetType.all,
      'plan' => NotificationTargetType.plan,
      _ => NotificationTargetType.user,
    };

    final notification = NotificationModel(
      id: '',
      title: _titleCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
      type: _selectedType,
      targetType: targetType,
      targetPlan: _targetMode == 'plan' ? _selectedPlan : null,
      createdAt: DateTime.now(),
      sentBy: adminEmail,
    );

    int count;
    if (_targetMode == 'all') {
      count = await NotificationFirestoreService.sendToAllUsers(
        notification: notification,
      );
    } else if (_targetMode == 'plan') {
      count = await NotificationFirestoreService.sendToPlanUsers(
        plan: _selectedPlan,
        notification: notification,
      );
    } else {
      count = await NotificationFirestoreService.sendToSelectedUsers(
        userIds: _selectedUserIds.toList(),
        notification: notification,
      );
    }

    setState(() => _isSending = false);

    messenger.showSnackBar(
      SnackBar(
        content: Text('✅ Notification sent to $count users'),
        backgroundColor: Colors.green,
      ),
    );

    // Reset form
    _titleCtrl.clear();
    _bodyCtrl.clear();
    _selectedUserIds.clear();
    _selectedUserNames.clear();
    setState(() {});

    widget.onSent();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Templates Section ───
          const Text(
            '📋 Quick Templates',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _templates.length,
              separatorBuilder: (_, separatorIndex) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final t = _templates[index];
                return _TemplateCard(
                  template: t,
                  onTap: () => _applyTemplate(t),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // ─── Type Selector ───
          const Text(
            'Notification Type',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SegmentedButton<NotificationType>(
            segments: const [
              ButtonSegment(
                value: NotificationType.announcement,
                label: Text('Announce'),
                icon: Icon(Icons.campaign, size: 16),
              ),
              ButtonSegment(
                value: NotificationType.alert,
                label: Text('Alert'),
                icon: Icon(Icons.warning_amber, size: 16),
              ),
              ButtonSegment(
                value: NotificationType.reminder,
                label: Text('Remind'),
                icon: Icon(Icons.alarm, size: 16),
              ),
              ButtonSegment(
                value: NotificationType.system,
                label: Text('System'),
                icon: Icon(Icons.info_outline, size: 16),
              ),
            ],
            selected: {_selectedType},
            onSelectionChanged: (set) {
              setState(() => _selectedType = set.first);
            },
          ),
          const SizedBox(height: 20),

          // ─── Target Selector ───
          const Text('Send To', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'all',
                label: Text('All Users'),
                icon: Icon(Icons.people, size: 16),
              ),
              ButtonSegment(
                value: 'selected',
                label: Text('Selected'),
                icon: Icon(Icons.person_search, size: 16),
              ),
              ButtonSegment(
                value: 'plan',
                label: Text('By Plan'),
                icon: Icon(Icons.credit_card, size: 16),
              ),
            ],
            selected: {_targetMode},
            onSelectionChanged: (set) {
              setState(() => _targetMode = set.first);
            },
          ),
          const SizedBox(height: 12),

          // ─── Plan Selector (if by plan) ───
          if (_targetMode == 'plan') ...[
            DropdownButtonFormField<String>(
              initialValue: _selectedPlan,
              decoration: const InputDecoration(
                labelText: 'Select Plan',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'free', child: Text('Free')),
                DropdownMenuItem(value: 'trial', child: Text('Trial')),
                DropdownMenuItem(value: 'pro', child: Text('Pro')),
                DropdownMenuItem(value: 'business', child: Text('Business')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _selectedPlan = v);
              },
            ),
            const SizedBox(height: 12),
          ],

          // ─── User Picker (if selected) ───
          if (_targetMode == 'selected') ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_selectedUserIds.length} user(s) selected',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _showUserPicker(context),
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text('Pick Users'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            if (_selectedUserNames.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _selectedUserNames.entries.map((entry) {
                  return Chip(
                    label: Text(
                      entry.value,
                      style: const TextStyle(fontSize: 12),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () {
                      setState(() {
                        _selectedUserIds.remove(entry.key);
                        _selectedUserNames.remove(entry.key);
                      });
                    },
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
          ],

          // ─── Title & Body ───
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
              hintText: 'e.g. New Feature Available!',
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Message',
              border: OutlineInputBorder(),
              hintText: 'Notification message body...',
              prefixIcon: Icon(Icons.message),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),

          // ─── Send Button ───
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _isSending ? null : _send,
              icon: _isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(_isSending ? 'Sending...' : 'Send Notification'),
              style: FilledButton.styleFrom(backgroundColor: Colors.deepPurple),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _UserPickerDialog(
        alreadySelected: _selectedUserIds,
        onConfirm: (ids, names) {
          setState(() {
            _selectedUserIds
              ..clear()
              ..addAll(ids);
            _selectedUserNames
              ..clear()
              ..addAll(names);
          });
        },
      ),
    );
  }
}

// ─── User Picker Dialog ───

class _UserPickerDialog extends StatefulWidget {
  final Set<String> alreadySelected;
  final void Function(Set<String> ids, Map<String, String> names) onConfirm;

  const _UserPickerDialog({
    required this.alreadySelected,
    required this.onConfirm,
  });

  @override
  State<_UserPickerDialog> createState() => _UserPickerDialogState();
}

class _UserPickerDialogState extends State<_UserPickerDialog> {
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  final _selected = <String>{};
  final _searchCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.alreadySelected);
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await NotificationFirestoreService.getAllUsers();
    setState(() {
      _allUsers = users;
      _filteredUsers = users;
      _loading = false;
    });
  }

  void _filter(String query) {
    final q = query.toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredUsers = _allUsers;
      } else {
        _filteredUsers = _allUsers.where((u) {
          final name = (u['ownerName'] as String? ?? '').toLowerCase();
          final email = (u['email'] as String? ?? '').toLowerCase();
          final shop = (u['shopName'] as String? ?? '').toLowerCase();
          return name.contains(q) || email.contains(q) || shop.contains(q);
        }).toList();
      }
    });
  }

  String _displayName(Map<String, dynamic> user) {
    final name = user['ownerName'] as String? ?? '';
    final shop = user['shopName'] as String? ?? '';
    if (name.isNotEmpty && shop.isNotEmpty) return '$name ($shop)';
    if (name.isNotEmpty) return name;
    if (shop.isNotEmpty) return shop;
    return user['email'] as String? ?? 'Unknown';
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.people, color: Colors.deepPurple),
          const SizedBox(width: 8),
          const Expanded(child: Text('Select Users')),
          Text(
            '${_selected.length} selected',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        height: 400,
        child: Column(
          children: [
            // Search bar
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search by name, email, or shop...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: _filter,
            ),
            const SizedBox(height: 8),
            // Select all / Clear
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selected.addAll(
                        _filteredUsers.map((u) => u['id'] as String),
                      );
                    });
                  },
                  child: const Text('Select All'),
                ),
                TextButton(
                  onPressed: () => setState(() => _selected.clear()),
                  child: const Text('Clear All'),
                ),
              ],
            ),
            const Divider(height: 1),
            // User list
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredUsers.isEmpty
                  ? const Center(child: Text('No users found'))
                  : ListView.builder(
                      itemCount: _filteredUsers.length,
                      itemBuilder: (ctx, index) {
                        final user = _filteredUsers[index];
                        final id = user['id'] as String;
                        final isChecked = _selected.contains(id);
                        return CheckboxListTile(
                          value: isChecked,
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                _selected.add(id);
                              } else {
                                _selected.remove(id);
                              }
                            });
                          },
                          title: Text(
                            _displayName(user),
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            user['email'] as String? ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          secondary: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.deepPurple.shade50,
                            child: Text(
                              (user['ownerName'] as String? ?? '?')
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          dense: true,
                          controlAffinity: ListTileControlAffinity.trailing,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () {
            final names = <String, String>{};
            for (final id in _selected) {
              final user = _allUsers.firstWhere(
                (u) => u['id'] == id,
                orElse: () => <String, dynamic>{},
              );
              if (user.isNotEmpty) {
                names[id] = _displayName(user);
              }
            }
            widget.onConfirm(_selected, names);
            Navigator.pop(context);
          },
          icon: const Icon(Icons.check, size: 16),
          label: Text('Confirm (${_selected.length})'),
          style: FilledButton.styleFrom(backgroundColor: Colors.deepPurple),
        ),
      ],
    );
  }
}

// ─── Template Card ───

class _TemplateCard extends StatelessWidget {
  final _NotifTemplate template;
  final VoidCallback onTap;

  const _TemplateCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.deepPurple.shade100),
          color: Colors.deepPurple.shade50,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(template.icon, color: Colors.deepPurple, size: 24),
            const SizedBox(height: 6),
            Text(
              template.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── History Card ───

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _HistoryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final title = (data['title'] as String?) ?? 'Untitled';
    final body = (data['body'] as String?) ?? '';
    final type = (data['type'] as String?) ?? 'system';
    final sentBy = (data['sentBy'] as String?) ?? 'unknown';
    final targetType = (data['targetType'] as String?) ?? 'all';
    final createdAt = data['createdAt'];
    String dateStr = 'Unknown date';
    if (createdAt != null) {
      try {
        final date = createdAt is DateTime
            ? createdAt
            : (createdAt as dynamic).toDate();
        dateStr = DateFormat('MMM d, yyyy h:mm a').format(date as DateTime);
      } catch (_) {
        dateStr = 'Unknown date';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _TypeBadge(type: type),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                _TargetBadge(target: targetType),
              ],
            ),
            const SizedBox(height: 8),
            Text(body, style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  sentBy,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const Spacer(),
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final colors = {
      'announcement': Colors.blue,
      'alert': Colors.orange,
      'reminder': Colors.green,
      'system': Colors.grey,
    };
    final icons = {
      'announcement': Icons.campaign,
      'alert': Icons.warning_amber,
      'reminder': Icons.alarm,
      'system': Icons.info_outline,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (colors[type] ?? Colors.grey).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icons[type] ?? Icons.info_outline,
            size: 14,
            color: colors[type] ?? Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            type.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: colors[type] ?? Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetBadge extends StatelessWidget {
  final String target;
  const _TargetBadge({required this.target});

  @override
  Widget build(BuildContext context) {
    final label = switch (target) {
      'all' => '👥 All Users',
      'user' => '👤 Selected',
      'plan' => '📋 By Plan',
      _ => '📋 $target',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}
