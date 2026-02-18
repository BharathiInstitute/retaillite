/// Persistent Update Banner (Layer 5 visual fallback)
///
/// Shows a non-intrusive banner at the top of the app when user
/// has dismissed the update dialog. Tapping starts the download.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:retaillite/core/design/design_system.dart';
import 'package:retaillite/core/services/windows_update_service.dart';

class UpdateBanner extends StatefulWidget {
  final Widget child;

  const UpdateBanner({super.key, required this.child});

  @override
  State<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends State<UpdateBanner> {
  bool _showBanner = false;
  bool _downloading = false;
  double _progress = 0;
  AppVersionInfo? _versionInfo;

  @override
  void initState() {
    super.initState();
    _checkForBanner();
  }

  Future<void> _checkForBanner() async {
    if (!Platform.isWindows) return;

    final shouldShow = await WindowsUpdateService.shouldShowDialog();
    if (shouldShow && mounted) {
      final info = await WindowsUpdateService.getCachedVersionInfo();
      if (info != null && mounted) {
        setState(() {
          _showBanner = true;
          _versionInfo = info;
        });
      }
    }
  }

  Future<void> _startUpdate() async {
    if (_versionInfo == null) return;

    setState(() {
      _downloading = true;
      _progress = 0;
    });

    final success = await WindowsUpdateService.downloadAndInstall(
      _versionInfo!,
      onProgress: (progress) {
        if (mounted) setState(() => _progress = progress);
      },
    );

    if (mounted) {
      if (success) {
        setState(() => _showBanner = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Update downloaded! It will install when you close the app.',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );
        }
      } else {
        setState(() => _downloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_showBanner) return widget.child;

    return Column(
      children: [
        Material(
          color: AppColors.primary,
          child: SafeArea(
            bottom: false,
            child: InkWell(
              onTap: _downloading ? null : _startUpdate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.system_update,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _downloading
                          ? Row(
                              children: [
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: _progress > 0 ? _progress : null,
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.3,
                                    ),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${(_progress * 100).toInt()}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Update v${_versionInfo?.version} available — tap to install',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                    if (!_downloading)
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() => _showBanner = false);
                          WindowsUpdateService.markDialogDismissed();
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
