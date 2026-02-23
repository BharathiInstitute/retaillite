/// Manage Admins Screen - Add/remove super admin access
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/features/super_admin/providers/super_admin_provider.dart';
import 'package:retaillite/features/super_admin/services/admin_firestore_service.dart';
import 'package:retaillite/features/super_admin/screens/admin_shell_screen.dart';

class ManageAdminsScreen extends ConsumerWidget {
  const ManageAdminsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminEmailsAsync = ref.watch(adminEmailsProvider);
    final isPrimaryOwner = ref.watch(isPrimaryOwnerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Admins'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        leading: MediaQuery.of(context).size.width >= 1024
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  adminShellScaffoldKey.currentState?.openDrawer();
                },
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminEmailsProvider),
          ),
        ],
      ),
      floatingActionButton: isPrimaryOwner
          ? FloatingActionButton.extended(
              onPressed: () => _showAddAdminDialog(context, ref),
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add),
              label: const Text('Add Admin'),
            )
          : null,
      body: adminEmailsAsync.when(
        data: (emails) => _buildAdminList(context, ref, emails, isPrimaryOwner),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading admins: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(adminEmailsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminList(
    BuildContext context,
    WidgetRef ref,
    List<String> emails,
    bool isPrimaryOwner,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.deepPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isPrimaryOwner
                      ? 'You are the primary owner. You can add or remove other admins.'
                      : 'Only the primary owner can add or remove admins.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Admin count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            '${emails.length} Admin${emails.length != 1 ? 's' : ''}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),

        // Admin list
        ...emails.map((email) {
          final isOwner = email == AdminFirestoreService.primaryOwnerEmail;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isOwner
                    ? Colors.deepPurple
                    : Colors.grey.shade300,
                child: Icon(
                  isOwner ? Icons.shield : Icons.admin_panel_settings,
                  color: isOwner ? Colors.white : Colors.grey.shade700,
                  size: 20,
                ),
              ),
              title: Text(
                email,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                isOwner ? 'Primary Owner (cannot be removed)' : 'Admin',
                style: TextStyle(
                  fontSize: 13,
                  color: isOwner ? Colors.deepPurple : Colors.grey.shade600,
                ),
              ),
              trailing: isOwner
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.deepPurple),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock, size: 14, color: Colors.deepPurple),
                          SizedBox(width: 4),
                          Text(
                            'Owner',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ],
                      ),
                    )
                  : isPrimaryOwner
                  ? IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                      ),
                      onPressed: () => _confirmRemoveAdmin(context, ref, email),
                    )
                  : null,
            ),
          );
        }),
      ],
    );
  }

  void _showAddAdminDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Admin'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              hintText: 'admin@example.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final email = controller.text.trim();
              Navigator.pop(dialogContext);

              final success = await AdminFirestoreService.addAdminEmail(email);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? '$email added as admin'
                          : 'Failed to add admin (may already exist)',
                    ),
                    backgroundColor: success ? Colors.green : Colors.orange,
                  ),
                );
              }

              ref.invalidate(adminEmailsProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveAdmin(BuildContext context, WidgetRef ref, String email) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Admin?'),
        content: Text(
          'Are you sure you want to remove admin access for:\n\n$email\n\nThey will no longer be able to access the Super Admin panel.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              final success = await AdminFirestoreService.removeAdminEmail(
                email,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? '$email removed from admins'
                          : 'Failed to remove admin',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }

              ref.invalidate(adminEmailsProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
