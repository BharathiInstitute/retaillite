/// Force update screen shown when min_app_version in Remote Config
/// is higher than the currently running app version.
///
/// On Windows: Downloads and installs the update directly via WindowsUpdateService.
/// On other platforms: Opens the update URL in browser (Play Store / web).
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:retaillite/core/services/windows_update_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ForceUpdateScreen extends StatefulWidget {
  final String currentVersion;
  final String requiredVersion;
  final String? updateUrl;

  const ForceUpdateScreen({
    super.key,
    required this.currentVersion,
    required this.requiredVersion,
    this.updateUrl,
  });

  @override
  State<ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

class _ForceUpdateScreenState extends State<ForceUpdateScreen> {
  bool _downloading = false;
  double _progress = 0;
  String? _error;

  Future<void> _handleUpdate() async {
    // On Windows: download and install directly
    if (!kIsWeb && Platform.isWindows) {
      setState(() {
        _downloading = true;
        _progress = 0;
        _error = null;
      });

      try {
        final result = await WindowsUpdateService.checkForUpdate();
        if (result.status == UpdateStatus.updateAvailable) {
          final success = await WindowsUpdateService.downloadAndInstall(
            result.versionInfo!,
            onProgress: (p) {
              if (mounted) setState(() => _progress = p);
            },
          );

          if (success && mounted) {
            setState(() {
              _downloading = false;
              _error = null;
            });
            // Show success — app will update on close
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => AlertDialog(
                title: const Text('Update Ready'),
                content: const Text(
                  'The update has been downloaded. Please close and reopen the app to complete the update.',
                ),
                actions: [
                  FilledButton(
                    onPressed: () => exit(0),
                    child: const Text('Restart Now'),
                  ),
                ],
              ),
            );
            return;
          }
        }

        if (mounted) {
          setState(() {
            _downloading = false;
            _error = 'Update failed. Please try again.';
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _downloading = false;
            _error = 'Update failed: ${e.toString().split('\n').first}';
          });
        }
      }
      return;
    }

    // On other platforms: open URL in browser
    if (widget.updateUrl != null && widget.updateUrl!.isNotEmpty) {
      final uri = Uri.parse(widget.updateUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.system_update_rounded,
                  size: 80,
                  color: Color(0xFF6366F1),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Update Required',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'A new version (${widget.requiredVersion}) is available.\n'
                  'Your version (${widget.currentVersion}) is no longer supported.\n'
                  'Please update to continue.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                // Download progress (Windows only)
                if (_downloading) ...[
                  SizedBox(
                    width: 300,
                    child: LinearProgressIndicator(
                      value: _progress > 0 ? _progress : null,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF6366F1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _progress > 0
                        ? 'Downloading... ${(_progress * 100).toInt()}%'
                        : 'Preparing download...',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
                // Error message
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (!_downloading)
                  ElevatedButton.icon(
                    onPressed: _handleUpdate,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Update Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
