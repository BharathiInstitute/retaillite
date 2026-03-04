/// Announcement Banner — shows Remote Config messages to all users
///
/// Two triggers:
/// 1. `announcement` key is non-empty → shows banner with message
/// 2. `latest_version` > current appVersion → shows "Update available" nudge
///
/// Dismissible per-session. Does NOT block the app.
library;

import 'package:flutter/material.dart';
import 'package:retaillite/core/config/remote_config_state.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';

class AnnouncementBanner extends StatefulWidget {
  final Widget child;
  const AnnouncementBanner({super.key, required this.child});

  @override
  State<AnnouncementBanner> createState() => _AnnouncementBannerState();
}

class _AnnouncementBannerState extends State<AnnouncementBanner> {
  bool _announcementDismissed = false;
  bool _updateDismissed = false;

  @override
  void initState() {
    super.initState();
    _loadDismissState();
  }

  void _loadDismissState() {
    final prefs = OfflineStorageService.prefs;
    if (prefs == null) return;

    // Check if current announcement was already dismissed
    final dismissedHash = prefs.getString('dismissed_announcement_hash');
    final currentHash = RemoteConfigState.announcement.hashCode.toString();
    if (dismissedHash == currentHash &&
        RemoteConfigState.announcement.isNotEmpty) {
      _announcementDismissed = true;
    }

    // Check if update was dismissed (with 24h TTL)
    final dismissedAt = prefs.getInt('dismissed_update_at');
    if (dismissedAt != null) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - dismissedAt;
      if (elapsed < const Duration(hours: 24).inMilliseconds) {
        _updateDismissed = true;
      }
    }
  }

  void _dismissAnnouncement() {
    setState(() => _announcementDismissed = true);
    OfflineStorageService.prefs?.setString(
      'dismissed_announcement_hash',
      RemoteConfigState.announcement.hashCode.toString(),
    );
  }

  void _dismissUpdate() {
    setState(() => _updateDismissed = true);
    OfflineStorageService.prefs?.setInt(
      'dismissed_update_at',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  Widget build(BuildContext context) {
    final announcement = RemoteConfigState.announcement;
    final hasUpdate = RemoteConfigState.hasNewerVersion;
    final latestVersion = RemoteConfigState.latestVersion;

    final showAnnouncement = announcement.isNotEmpty && !_announcementDismissed;
    final showUpdate = hasUpdate && !_updateDismissed;

    if (!showAnnouncement && !showUpdate) return widget.child;

    return Column(
      children: [
        // ─── Announcement Banner ───
        if (showAnnouncement)
          MaterialBanner(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: const Icon(Icons.campaign, color: Colors.white),
            backgroundColor: Theme.of(context).colorScheme.primary,
            content: Text(
              announcement,
              style: const TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: _dismissAnnouncement,
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),

        // ─── Update Available Banner ───
        if (showUpdate)
          MaterialBanner(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: const Icon(Icons.system_update, color: Colors.white),
            backgroundColor: Colors.green.shade700,
            content: Text(
              'Version $latestVersion available! Update for latest features.',
              style: const TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: _dismissUpdate,
                child: const Text(
                  'LATER',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),

        // ─── Main Content ───
        Expanded(child: widget.child),
      ],
    );
  }
}
