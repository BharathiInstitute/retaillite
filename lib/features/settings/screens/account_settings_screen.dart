/// Account Settings Screen - Profile, Password, Subscription
/// Mirrors Web Account Tab
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/design/app_colors.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/core/services/image_service.dart';
import 'dart:io';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final imagePath = await ImageService.pickAndResizeLogo();
    if (imagePath != null && mounted) {
      await ref.read(authNotifierProvider.notifier).updateShopLogo(imagePath);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile picture updated'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final logoPath = user?.shopLogoPath;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
        actions: [
          TextButton(onPressed: _saveSettings, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          _buildSectionHeader(theme, 'Profile'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Picture
                  Center(
                    child: GestureDetector(
                      onTap: _pickProfileImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage:
                                logoPath != null && File(logoPath).existsSync()
                                ? FileImage(File(logoPath))
                                : null,
                            child:
                                logoPath == null || !File(logoPath).existsSync()
                                ? const Icon(Icons.person, size: 50)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to change profile picture',
                    style: TextStyle(
                      color: theme.colorScheme.outline,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Email
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Security Section
          _buildSectionHeader(theme, 'Security'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text('Change Password'),
                  subtitle: const Text('Update your account password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showChangePasswordDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Login History'),
                  subtitle: const Text('View recent login activity'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showLoginHistory(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Subscription Section
          _buildSectionHeader(theme, 'Subscription'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Active',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Free Plan',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureRow('Unlimited Products', true),
                  _buildFeatureRow('Basic Reports', true),
                  _buildFeatureRow('Thermal Printing', true),
                  _buildFeatureRow('Cloud Backup', false),
                  _buildFeatureRow('Multi-device Sync', false),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text('Upgrade to Pro'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String feature, bool included) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            included ? Icons.check_circle : Icons.cancel,
            size: 20,
            color: included ? AppColors.primary : Colors.grey,
          ),
          const SizedBox(width: 12),
          Text(feature),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      // Validate
                      if (newPasswordController.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Password must be at least 6 characters',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      if (newPasswordController.text !=
                          confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Passwords do not match'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      try {
                        await ref
                            .read(authNotifierProvider.notifier)
                            .changePassword(
                              currentPasswordController.text,
                              newPasswordController.text,
                            );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Password changed successfully',
                              ),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLoginHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Login History'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLoginItem('Chrome on Windows', 'Just now', true),
            const Divider(),
            _buildLoginItem('Chrome on Android', '2 hours ago', false),
            const Divider(),
            _buildLoginItem('Safari on iPhone', 'Yesterday', false),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginItem(String device, String time, bool isCurrent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  time,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Current',
                style: TextStyle(fontSize: 10, color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  void _saveSettings() {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    authNotifier.updateShopInfo(phone: _phoneController.text);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Account settings saved'),
        backgroundColor: AppColors.primary,
      ),
    );
    Navigator.pop(context);
  }
}
