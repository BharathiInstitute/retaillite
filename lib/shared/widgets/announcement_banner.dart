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
                onPressed: () => setState(() => _announcementDismissed = true),
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
                onPressed: () => setState(() => _updateDismissed = true),
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
