/// Edit shop details modal - Localized
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/design/design_system.dart';
import 'package:retaillite/core/utils/validators.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/l10n/app_localizations.dart';
import 'package:retaillite/shared/widgets/app_button.dart';
import 'package:retaillite/shared/widgets/app_text_field.dart';

class EditShopModal extends ConsumerStatefulWidget {
  const EditShopModal({super.key});

  @override
  ConsumerState<EditShopModal> createState() => _EditShopModalState();
}

class _EditShopModalState extends ConsumerState<EditShopModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _shopNameController;
  late final TextEditingController _ownerNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _gstController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _shopNameController = TextEditingController(text: user?.shopName ?? '');
    _ownerNameController = TextEditingController(text: user?.ownerName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
    _gstController = TextEditingController(text: user?.gstNumber ?? '');
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final l10n = context.l10n;

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .updateShopDetails(
            shopName: _shopNameController.text.trim(),
            ownerName: _ownerNameController.text.trim(),
            address: _addressController.text.trim(),
            gstNumber: _gstController.text.trim(),
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.productUpdated),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
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

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(),
            child: Row(
              children: [
                Icon(Icons.store, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.editShopDetails,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: ResponsiveHelper.modalPadding(context),
                right: ResponsiveHelper.modalPadding(context),
                top: ResponsiveHelper.modalPadding(context),
                bottom: MediaQuery.of(context).viewInsets.bottom + 100,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Email - read-only
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.email,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.loginEmail,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  ref.read(currentUserProvider)?.email ?? '-',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.lock,
                            size: 16,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      label: '${l10n.shopName} *',
                      hint: 'e.g., Sharma General Store',
                      controller: _shopNameController,
                      prefixIcon: const Icon(Icons.store),
                      validator: (v) => Validators.name(v, l10n.shopName),
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      label: '${l10n.ownerName} *',
                      hint: 'e.g., Raj Sharma',
                      controller: _ownerNameController,
                      prefixIcon: const Icon(Icons.person),
                      validator: (v) => Validators.name(v, l10n.ownerName),
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      label: '${l10n.phone} *',
                      hint: '9876543210',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone),
                      validator: (v) => Validators.phone(v),
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      label: l10n.address,
                      hint: 'Shop address (optional)',
                      controller: _addressController,
                      prefixIcon: const Icon(Icons.location_on),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      label: l10n.gstNumber,
                      hint: 'e.g., 22AAAAA0000A1Z5',
                      controller: _gstController,
                      prefixIcon: const Icon(Icons.receipt_long),
                    ),
                    const SizedBox(height: 32),

                    AppButton(
                      label: '✅ ${l10n.save.toUpperCase()}',
                      onPressed: _save,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
