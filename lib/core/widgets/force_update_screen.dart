/// Force update screen shown when min_app_version in Remote Config
/// is higher than the currently running app version.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ForceUpdateScreen extends StatelessWidget {
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
                  'A new version ($requiredVersion) is available.\n'
                  'Your version ($currentVersion) is no longer supported.\n'
                  'Please update to continue.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                if (updateUrl != null && updateUrl!.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(updateUrl!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
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
