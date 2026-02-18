/// Add customer modal
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/design/design_system.dart';
import 'package:retaillite/core/utils/validators.dart';
import 'package:retaillite/features/khata/providers/khata_provider.dart';
import 'package:retaillite/models/customer_model.dart';
import 'package:retaillite/shared/widgets/app_button.dart';
import 'package:retaillite/shared/widgets/app_text_field.dart';

class AddCustomerModal extends ConsumerStatefulWidget {
  final CustomerModel? customer; // For edit mode

  const AddCustomerModal({super.key, this.customer});

  @override
  ConsumerState<AddCustomerModal> createState() => _AddCustomerModalState();
}

class _AddCustomerModalState extends ConsumerState<AddCustomerModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');
  bool _owesMe = true;
  bool _isLoading = false;

  bool get _isEditMode => widget.customer != null;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _nameController.text = widget.customer!.name;
      _phoneController.text = widget.customer!.phone;
      _addressController.text = widget.customer!.address ?? '';
      _balanceController.text = widget.customer!.balance.abs().toString();
      _owesMe = widget.customer!.balance >= 0;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final service = ref.read(khataServiceProvider);

      final balance = double.tryParse(_balanceController.text) ?? 0;

      final customer = CustomerModel(
        id: widget.customer?.id ?? '',
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        balance: _owesMe ? balance : -balance,
        createdAt: widget.customer?.createdAt ?? DateTime.now(),
        updatedAt: _isEditMode ? DateTime.now() : null,
      );

      if (_isEditMode) {
        await service.updateCustomer(customer);
      } else {
        await service.addCustomer(customer);
      }

      // Refresh the customers list
      ref.invalidate(customersProvider);
      if (_isEditMode) {
        ref.invalidate(customerProvider(customer.id));
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Customer updated successfully'
                  : 'Customer added successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to ${_isEditMode ? 'update' : 'add'} customer: $e',
            ),
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
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: ResponsiveHelper.modalPadding(context),
            right: ResponsiveHelper.modalPadding(context),
            top: ResponsiveHelper.modalPadding(context),
            bottom:
                MediaQuery.of(context).viewInsets.bottom +
                ResponsiveHelper.modalPadding(context),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      _isEditMode ? Icons.edit : Icons.person_add,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isEditMode ? 'Edit Customer' : 'Add New Customer',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Scrollable form fields
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Name
                        AppTextField(
                          label: 'Name *',
                          hint: 'Customer name',
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(Icons.person_outline),
                          validator: (v) => Validators.name(v),
                        ),
                        const SizedBox(height: 16),

                        // Phone
                        PhoneTextField(controller: _phoneController),
                        const SizedBox(height: 16),

                        // Address (optional)
                        AppTextField(
                          label: 'Address (Optional)',
                          hint: 'Customer address',
                          controller: _addressController,
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(Icons.location_on_outlined),
                        ),
                        const SizedBox(height: 16),

                        // Opening balance
                        CurrencyTextField(
                          label: 'Opening Balance (Optional)',
                          controller: _balanceController,
                        ),
                        const SizedBox(height: 8),

                        // Owes me checkbox
                        CheckboxListTile(
                          value: _owesMe,
                          onChanged: (v) => setState(() => _owesMe = v ?? true),
                          title: const Text('Customer owes me (Udhar)'),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        const SizedBox(height: 20),

                        // Submit button
                        AppButton(
                          label: _isEditMode
                              ? 'UPDATE CUSTOMER'
                              : 'ADD CUSTOMER',
                          onPressed: _submit,
                          isLoading: _isLoading,
                        ),
                      ],
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
