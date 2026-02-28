/// Admin Notifications Screen — compose and send notifications to users
/// Features: Templates, send to all/selected/by plan, user search & picker, history
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/features/notifications/models/notification_model.dart';
import 'package:retaillite/features/notifications/services/notification_firestore_service.dart';
import 'package:retaillite/features/super_admin/screens/admin_shell_screen.dart';

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
  late TabController _tabController;
  Stream<List<Map<String, dynamic>>>? _historyStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _historyStream = FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList(),
        );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications Manager',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Color(0xFF7C4DFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: MediaQuery.of(context).size.width >= 1024
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  adminShellScaffoldKey.currentState?.openDrawer();
                },
              ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.send_rounded), text: 'Compose'),
            Tab(icon: Icon(Icons.history_rounded), text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ComposeTab(
            ref: ref,
            onSent: () {
              _tabController.animateTo(1);
            },
          ),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _historyStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final history = snapshot.data ?? [];
              if (history.isEmpty) {
                return Center(
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
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final notif = history[index];
                  return _HistoryCard(data: notif);
                },
              );
            },
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
  int? _selectedTemplateIndex;

  void _applyTemplate(int index) {
    setState(() {
      if (_selectedTemplateIndex == index) {
        _selectedTemplateIndex = null;
        _titleCtrl.clear();
        _bodyCtrl.clear();
      } else {
        _selectedTemplateIndex = index;
        _titleCtrl.text = _templates[index].title;
        _bodyCtrl.text = _templates[index].body;
        _selectedType = _templates[index].type;
      }
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

    int count = 0;
    try {
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
    } catch (e) {
      setState(() => _isSending = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('❌ Failed to send: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    setState(() => _isSending = false);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          count > 0
              ? '✅ Notification sent to $count users'
              : '⚠️ No users found to send to',
        ),
        backgroundColor: count > 0 ? Colors.green : Colors.orange,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey.shade900 : Colors.white;
    final surfaceColor = isDark ? Colors.grey.shade800 : Colors.grey.shade50;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Templates Section ───
          _SectionCard(
            cardColor: cardColor,
            icon: Icons.dashboard_customize,
            title: 'Quick Templates',
            subtitle: 'Tap to auto-fill the form',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_templates.length, (index) {
                final t = _templates[index];
                final isSelected = _selectedTemplateIndex == index;
                return _TemplateChip(
                  template: t,
                  isSelected: isSelected,
                  onTap: () => _applyTemplate(index),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),

          // ─── Configuration Section ───
          _SectionCard(
            cardColor: cardColor,
            icon: Icons.tune,
            title: 'Configuration',
            subtitle: 'Choose type and audience',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type selector
                Text(
                  'Notification Type',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<NotificationType>(
                    segments: const [
                      ButtonSegment(
                        value: NotificationType.announcement,
                        label: Text('Announce', style: TextStyle(fontSize: 12)),
                        icon: Icon(Icons.campaign, size: 16),
                      ),
                      ButtonSegment(
                        value: NotificationType.alert,
                        label: Text('Alert', style: TextStyle(fontSize: 12)),
                        icon: Icon(Icons.warning_amber, size: 16),
                      ),
                      ButtonSegment(
                        value: NotificationType.reminder,
                        label: Text('Remind', style: TextStyle(fontSize: 12)),
                        icon: Icon(Icons.alarm, size: 16),
                      ),
                      ButtonSegment(
                        value: NotificationType.system,
                        label: Text('System', style: TextStyle(fontSize: 12)),
                        icon: Icon(Icons.info_outline, size: 16),
                      ),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: (set) {
                      setState(() => _selectedType = set.first);
                    },
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Target selector
                Text(
                  'Send To',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'all',
                        label: Text(
                          'All Users',
                          style: TextStyle(fontSize: 12),
                        ),
                        icon: Icon(Icons.people, size: 16),
                      ),
                      ButtonSegment(
                        value: 'selected',
                        label: Text('Selected', style: TextStyle(fontSize: 12)),
                        icon: Icon(Icons.person_search, size: 16),
                      ),
                      ButtonSegment(
                        value: 'plan',
                        label: Text('By Plan', style: TextStyle(fontSize: 12)),
                        icon: Icon(Icons.credit_card, size: 16),
                      ),
                    ],
                    selected: {_targetMode},
                    onSelectionChanged: (set) {
                      setState(() => _targetMode = set.first);
                    },
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ─── Plan picker ───
                if (_targetMode == 'plan') ...[
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedPlan,
                    decoration: InputDecoration(
                      labelText: 'Select Plan',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: surfaceColor,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'free', child: Text('Free')),
                      DropdownMenuItem(value: 'trial', child: Text('Trial')),
                      DropdownMenuItem(value: 'pro', child: Text('Pro')),
                      DropdownMenuItem(
                        value: 'business',
                        child: Text('Business'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedPlan = v);
                    },
                  ),
                ],

                // ─── User picker ───
                if (_targetMode == 'selected') ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.deepPurple.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.people_alt_outlined,
                              size: 18,
                              color: Colors.deepPurple.shade300,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedUserIds.isEmpty
                                    ? 'No users selected'
                                    : '${_selectedUserIds.length} user(s) selected',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: () => _showUserPicker(context),
                              icon: const Icon(Icons.person_add, size: 16),
                              label: const Text(
                                'Pick',
                                style: TextStyle(fontSize: 13),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.deepPurple.withValues(
                                  alpha: 0.1,
                                ),
                                foregroundColor: Colors.deepPurple,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                        if (_selectedUserNames.isNotEmpty) ...[
                          const SizedBox(height: 10),
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
                                backgroundColor: Colors.deepPurple.withValues(
                                  alpha: 0.08,
                                ),
                                side: BorderSide.none,
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── Message Section ───
          _SectionCard(
            cardColor: cardColor,
            icon: Icons.edit_note,
            title: 'Compose Message',
            subtitle: 'Write your notification content',
            child: Column(
              children: [
                TextField(
                  controller: _titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g. New Feature Available!',
                    prefixIcon: const Icon(Icons.title, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: surfaceColor,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _bodyCtrl,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Message',
                    hintText: 'Write your notification message here...',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 64),
                      child: Icon(Icons.message_outlined, size: 20),
                    ),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: surfaceColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── Send Button ───
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [Colors.deepPurple, Color(0xFF7C4DFF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FilledButton.icon(
                onPressed: _isSending ? null : _send,
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 20),
                label: Text(
                  _isSending ? 'Sending...' : 'Send Notification',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
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
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Flexible(
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

// ─── Section Card ───

class _SectionCard extends StatelessWidget {
  final Color cardColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.cardColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: Colors.deepPurple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

// ─── Template Chip (Radio-style) ───

class _TemplateChip extends StatelessWidget {
  final _NotifTemplate template;
  final bool isSelected;
  final VoidCallback onTap;

  const _TemplateChip({
    required this.template,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: isSelected
                ? Colors.deepPurple
                : Colors.deepPurple.withValues(alpha: 0.06),
            border: Border.all(
              color: isSelected
                  ? Colors.deepPurple
                  : Colors.deepPurple.withValues(alpha: 0.2),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                template.icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.deepPurple,
              ),
              const SizedBox(width: 6),
              Text(
                template.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.deepPurple,
                ),
              ),
            ],
          ),
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
    final recipientCount = data['recipientCount'] as int?;
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
                const SizedBox(width: 12),
                // Recipient count
                Icon(
                  Icons.group,
                  size: 14,
                  color: recipientCount != null && recipientCount > 0
                      ? Colors.green.shade400
                      : Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Text(
                  recipientCount != null
                      ? 'Sent to $recipientCount user${recipientCount == 1 ? '' : 's'}'
                      : 'Processing…',
                  style: TextStyle(
                    fontSize: 12,
                    color: recipientCount != null && recipientCount > 0
                        ? Colors.green.shade400
                        : Colors.grey.shade500,
                    fontWeight: recipientCount != null && recipientCount > 0
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
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
