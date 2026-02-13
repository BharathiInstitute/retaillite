/// Shop setup screen - one-time setup after registration
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retaillite/core/design/design_system.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/features/auth/widgets/auth_layout.dart';
import 'package:retaillite/l10n/app_localizations.dart';

class ShopSetupScreen extends ConsumerStatefulWidget {
  const ShopSetupScreen({super.key});

  @override
  ConsumerState<ShopSetupScreen> createState() => _ShopSetupScreenState();
}

class _ShopSetupScreenState extends ConsumerState<ShopSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _addressController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  Future<void> _handleSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .completeShopSetup(
            shopName: _shopNameController.text.trim(),
            ownerName: _ownerNameController.text.trim(),
            address: _addressController.text.trim().isNotEmpty
                ? _addressController.text.trim()
                : null,
            gstNumber: _gstController.text.trim().isNotEmpty
                ? _gstController.text.trim()
                : null,
          );

      if (mounted) {
        context.go('/billing');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AuthLayout(
      title: 'Set Up Your Shop',
      subtitle: 'Enter your shop details to get started',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Shop Name
            TextFormField(
              controller: _shopNameController,
              decoration: InputDecoration(
                labelText: l10n.shopName,
                hintText: 'Enter your shop name',
                prefixIcon: const Icon(
                  Icons.store_outlined,
                  color: AppColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your shop name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Owner Name
            TextFormField(
              controller: _ownerNameController,
              decoration: InputDecoration(
                labelText: l10n.ownerName,
                hintText: 'Enter your name',
                prefixIcon: const Icon(
                  Icons.person_outlined,
                  color: AppColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Address (Optional)
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: '${l10n.address} (Optional)',
                hintText: 'Enter your shop address',
                prefixIcon: const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // GST Number (Optional)
            TextFormField(
              controller: _gstController,
              decoration: InputDecoration(
                labelText: 'GST Number (Optional)',
                hintText: 'Enter 15-digit GST number',
                prefixIcon: const Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 32),

            // Continue Button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSetup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '✅ GET STARTED',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Footer
            const Text(
              'You can update these details later in Settings',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
