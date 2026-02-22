/// Windows Update Dialog (Layer 4)
///
/// Shows a dialog when silent updates have failed 3+ times.
/// User can click "Update Now" to download with visible progress,
/// or dismiss to see the persistent banner instead.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:retaillite/core/design/design_system.dart';
import 'package:retaillite/core/services/windows_update_service.dart';

class UpdateDialog extends StatefulWidget {
  final AppVersionInfo versionInfo;

  const UpdateDialog({super.key, required this.versionInfo});

  /// Check if dialog should be shown and show it. Call on app start.
  static Future<void> checkAndShow(BuildContext context) async {
    if (!Platform.isWindows) return;

    // Only show if Layer 4 is triggered (3+ silent failures)
    final shouldShow = await WindowsUpdateService.shouldShowDialog();
    if (!shouldShow) return;

    // Fetch latest version info
    final result = await WindowsUpdateService.checkForUpdate();
    if (result.status != UpdateStatus.updateAvailable) return;
    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: !result.versionInfo!.forceUpdate,
      builder: (_) => UpdateDialog(versionInfo: result.versionInfo!),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _downloading = false;
  double _progress = 0;
  String? _error;

  Future<void> _startUpdate() async {
    setState(() {
      _downloading = true;
      _progress = 0;
      _error = null;
    });

    final success = await WindowsUpdateService.downloadAndInstall(
      widget.versionInfo,
      onProgress: (progress) {
        if (mounted) setState(() => _progress = progress);
      },
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Update downloaded! It will install when you close the app.',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );
    } else {
      setState(() {
        _downloading = false;
        _error = 'Download failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.system_update, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          const Text('Update Available'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Version ${widget.versionInfo.version} is available!',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'The automatic update could not complete. Please update manually.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          if (widget.versionInfo.changelog.isNotEmpty) ...[
            const Text(
              "What's new:",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(maxHeight: 150),
              child: SingleChildScrollView(
                child: Text(
                  widget.versionInfo.changelog,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_downloading) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _progress > 0 ? _progress : null,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              _progress > 0
                  ? 'Downloading... ${(_progress * 100).toInt()}%'
                  : 'Preparing download...',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ],
        ],
      ),
      actions: [
        if (!widget.versionInfo.forceUpdate && !_downloading)
          TextButton(
            onPressed: () {
              // Mark dismissed so banner shows instead
              WindowsUpdateService.markDialogDismissed();
              Navigator.of(context).pop();
            },
            child: const Text('Later'),
          ),
        if (!_downloading)
          FilledButton.icon(
            onPressed: _startUpdate,
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Update Now'),
          ),
      ],
    );
  }
}
