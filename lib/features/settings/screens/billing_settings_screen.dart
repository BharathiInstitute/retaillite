/// Billing Settings Screen - Invoice, Tax, Terms, Payments
/// Mirrors Web Billing Tab
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/design/app_colors.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/core/services/image_service.dart';
import 'dart:io';

class BillingSettingsScreen extends ConsumerStatefulWidget {
  const BillingSettingsScreen({super.key});

  @override
  ConsumerState<BillingSettingsScreen> createState() =>
      _BillingSettingsScreenState();
}

class _BillingSettingsScreenState extends ConsumerState<BillingSettingsScreen> {
  late TextEditingController _invoiceTitleController;
  late TextEditingController _taxRateController;
  late TextEditingController _termsController;

  bool _taxEnabled = true;
  bool _taxInclusive = false;
  String? _invoiceLogoPath;
  String? _upiQrPath;

  @override
  void initState() {
    super.initState();
    _invoiceTitleController = TextEditingController(text: 'Tax Invoice');
    _taxRateController = TextEditingController(text: '18');
    _termsController = TextEditingController(
      text: 'Thank you for your business!',
    );
  }

  @override
  void dispose() {
    _invoiceTitleController.dispose();
    _taxRateController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  Future<void> _pickInvoiceLogo() async {
    final imagePath = await ImageService.pickAndResizeLogo();
    if (imagePath != null && mounted) {
      setState(() => _invoiceLogoPath = imagePath);
    }
  }

  Future<void> _pickUpiQr() async {
    final imagePath = await ImageService.pickAndResizeLogo();
    if (imagePath != null && mounted) {
      setState(() => _upiQrPath = imagePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing Settings'),
        actions: [
          TextButton(onPressed: _saveSettings, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Invoice Header Section
          _buildSectionHeader(theme, 'Invoice Header'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Invoice Logo
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _pickInvoiceLogo,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child:
                              _invoiceLogoPath != null &&
                                  File(_invoiceLogoPath!).existsSync()
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(_invoiceLogoPath!),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.camera_alt,
                                      color: Colors.grey.shade500,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Logo',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.shopName ?? 'Your Shop Name',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.address ?? 'Shop Address',
                              style: TextStyle(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Invoice Title
                  TextField(
                    controller: _invoiceTitleController,
                    decoration: const InputDecoration(
                      labelText: 'Invoice Title',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Tax Settings Section
          _buildSectionHeader(theme, 'Tax Settings'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.percent),
                  title: const Text('Enable Tax'),
                  subtitle: const Text('Add GST/tax to invoices'),
                  value: _taxEnabled,
                  onChanged: (v) => setState(() => _taxEnabled = v),
                ),
                if (_taxEnabled) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _taxRateController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Tax Rate (%)',
                        suffixText: '%',
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Tax Inclusive'),
                    subtitle: const Text('Prices already include tax'),
                    value: _taxInclusive,
                    onChanged: (v) => setState(() => _taxInclusive = v),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Terms & Conditions Section
          _buildSectionHeader(theme, 'Terms & Conditions'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _termsController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Footer / Terms',
                      hintText: 'This will appear at the bottom of invoices',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add terms, thank you message, or return policy',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Payment Setup Section
          _buildSectionHeader(theme, 'Payment Setup'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('UPI QR Code', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickUpiQr,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: AppShadows.small,
                      ),
                      child:
                          _upiQrPath != null && File(_upiQrPath!).existsSync()
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_upiQrPath!),
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.qr_code,
                                  size: 40,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Upload QR',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This QR code will be printed on invoices for UPI payments',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.outline,
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

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Billing settings saved'),
        backgroundColor: AppColors.primary,
      ),
    );
    Navigator.pop(context);
  }
}
