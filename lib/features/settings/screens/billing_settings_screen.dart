/// Billing Settings Screen - Invoice, Tax, Terms, Payments
/// Mirrors Web Billing Tab
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:retaillite/core/design/app_colors.dart';
import 'package:retaillite/core/services/payment_link_service.dart';
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
  late TextEditingController _upiIdController;

  bool _taxEnabled = true;
  bool _taxInclusive = false;
  String? _invoiceLogoPath;
  String? _upiQrPath;
  String? _upiValidationError;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    final settings = user?.settings;
    _invoiceTitleController = TextEditingController(text: 'Tax Invoice');
    _taxRateController = TextEditingController(
      text: (settings?.taxRate ?? 5.0).toStringAsFixed(0),
    );
    _termsController = TextEditingController(
      text: settings?.receiptFooter ?? 'Thank you for your business!',
    );
    _upiIdController = TextEditingController(text: PaymentLinkService.upiId);
    _upiIdController.addListener(_validateUpiId);
    _taxEnabled = settings?.gstEnabled ?? true;
  }

  void _validateUpiId() {
    final id = _upiIdController.text.trim();
    setState(() {
      if (id.isEmpty) {
        _upiValidationError = null;
      } else if (!id.contains('@')) {
        _upiValidationError = 'UPI ID must contain @ (e.g. shop@ybl)';
      } else if (!PaymentLinkService.isValidUpiId(id)) {
        _upiValidationError = 'Invalid format. Use: name@provider';
      } else {
        _upiValidationError = null;
      }
    });
  }

  @override
  void dispose() {
    _invoiceTitleController.dispose();
    _taxRateController.dispose();
    _termsController.dispose();
    _upiIdController.dispose();
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

  void _showBusinessUpiGuide() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.account_balance_wallet, color: AppColors.primary),
            const SizedBox(width: 8),
            const Expanded(child: Text('Get Business UPI')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Business UPI gives you unlimited free transactions per day.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              const Text(
                '🥇 PhonePe Business (Recommended)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• Download from Play Store / App Store'),
              const Text('• Enter PAN + link bank account'),
              const Text('• Setup time: ~5 minutes'),
              const Text('• Cost: ₹0 forever'),
              const SizedBox(height: 12),
              const Text(
                '🥈 Google Pay for Business',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• Download from Play Store'),
              const Text('• Links to existing Google account'),
              const Text('• Setup time: ~10 minutes'),
              const Text('• Cost: ₹0 forever'),
              const SizedBox(height: 12),
              const Text(
                '🥉 BharatPe',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• Download from Play Store'),
              const Text('• Free QR stand delivered to shop'),
              const Text('• Setup time: ~15 minutes'),
              const Text('• Cost: ₹0 forever'),
              const SizedBox(height: 16),
              Text(
                'After setup, copy your Business UPI ID and paste it above.',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendTestPayment() async {
    final upiId = _upiIdController.text.trim();
    if (!PaymentLinkService.isValidUpiId(upiId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid UPI ID first'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    final launched = await PaymentLinkService.launchTestPayment(
      upiId: upiId,
      shopName: user?.shopName,
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No UPI app found. Install GPay or PhonePe.'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final upiId = _upiIdController.text.trim();
    final isValidUpi = PaymentLinkService.isValidUpiId(upiId);

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

          // ═══════════════════════════════════════════════
          // UPI Payment Setup Section — all 4 improvements
          // ═══════════════════════════════════════════════
          _buildSectionHeader(theme, 'UPI Payment Setup'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. UPI ID Input with validation ──
                  TextField(
                    controller: _upiIdController,
                    decoration: InputDecoration(
                      labelText: 'Business UPI ID',
                      hintText: 'e.g. myshop@ybl',
                      prefixIcon: const Icon(Icons.account_balance_wallet),
                      errorText: _upiValidationError,
                      suffixIcon: isValidUpi
                          ? const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                            )
                          : null,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z0-9._@-]'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ── 3. Setup guide link ──
                  InkWell(
                    onTap: _showBusinessUpiGuide,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.help_outline,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'How to get a Business UPI ID (free)',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── 2. Auto-generated QR Code ──
                  if (isValidUpi) ...[
                    Text(
                      'Auto-Generated QR Code',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Customers scan this to pay via any UPI app',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppShadows.small,
                        ),
                        child: QrImageView(
                          data: PaymentLinkService.generateUpiQrData(
                            upiId: upiId,
                            payeeName: user?.shopName,
                          ),
                          size: 180,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── 4. Test Payment Button ──
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _sendTestPayment,
                        icon: const Icon(Icons.send, size: 18),
                        label: const Text('Send ₹1 Test Payment'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        'Verify your UPI ID by sending ₹1 to yourself',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  ],

                  // Empty state
                  if (!isValidUpi && upiId.isEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.info,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Enter your Business UPI ID to auto-generate a QR code for invoices and enable payment links.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Optional: Manual QR Upload
                  Text(
                    'Custom QR Code (Optional)',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Upload your own QR image to override the auto-generated one',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickUpiQr,
                    child: Container(
                      width: 100,
                      height: 100,
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
                                  size: 32,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Upload',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
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

  void _saveSettings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    // Save UPI ID if valid
    final upiId = _upiIdController.text.trim();
    if (upiId.isNotEmpty && PaymentLinkService.isValidUpiId(upiId)) {
      PaymentLinkService.setUpiId(upiId);
    }

    // Save all billing settings to Firestore
    if (uid != null) {
      try {
        final taxRate = double.tryParse(_taxRateController.text.trim()) ?? 5.0;
        final footer = _termsController.text.trim();

        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          if (upiId.isNotEmpty) 'upiId': upiId,
          'settings.gstEnabled': _taxEnabled,
          'settings.taxRate': taxRate,
          'settings.receiptFooter': footer,
        });

        // Update local state instantly
        final authNotifier = ref.read(authNotifierProvider.notifier);
        final currentUser = ref.read(currentUserProvider);
        if (currentUser != null) {
          authNotifier.updateLocalUserSettings(
            currentUser.settings.copyWith(
              gstEnabled: _taxEnabled,
              taxRate: taxRate,
              receiptFooter: footer,
            ),
          );
        }
      } catch (_) {
        // Non-fatal: settings saved locally
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Billing settings saved'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context);
    }
  }
}
