/// Add/Edit product modal
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/constants/theme_constants.dart';
import 'package:retaillite/core/services/barcode_scanner_service.dart';
import 'package:retaillite/core/services/barcode_lookup_service.dart';
import 'package:retaillite/core/utils/validators.dart';
import 'package:retaillite/features/products/providers/products_provider.dart';
import 'package:retaillite/models/product_model.dart';
import 'package:retaillite/shared/widgets/app_button.dart';
import 'package:retaillite/shared/widgets/app_text_field.dart';

class AddProductModal extends ConsumerStatefulWidget {
  final ProductModel? product;

  const AddProductModal({super.key, this.product});

  @override
  ConsumerState<AddProductModal> createState() => _AddProductModalState();
}

class _AddProductModalState extends ConsumerState<AddProductModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _stockController;
  late final TextEditingController _lowStockController;
  late final TextEditingController _barcodeController;
  late ProductUnit _selectedUnit;
  bool _isLoading = false;
  bool _isLookingUp = false;
  BarcodeProduct? _lookedUpProduct;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _priceController = TextEditingController(text: p?.price.toString() ?? '');
    _purchasePriceController = TextEditingController(
      text: p?.purchasePrice?.toString() ?? '',
    );
    _stockController = TextEditingController(text: p?.stock.toString() ?? '0');
    _lowStockController = TextEditingController(
      text: p?.lowStockAlert.toString() ?? '5',
    );
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _selectedUnit = p?.unit ?? ProductUnit.piece;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _purchasePriceController.dispose();
    _stockController.dispose();
    _lowStockController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  /// Scan barcode and lookup product info from API
  Future<void> _scanAndLookupBarcode() async {
    final code = await BarcodeScannerService.scanBarcode(context);
    if (code == null || !mounted) return;

    _barcodeController.text = code;
    setState(() => _isLookingUp = true);

    try {
      final product = await BarcodeLookupService.lookupBarcode(code);
      if (product != null && mounted) {
        setState(() {
          _lookedUpProduct = product;
          // Auto-fill name if empty
          if (_nameController.text.isEmpty) {
            _nameController.text = product.displayName;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found: ${product.displayName}'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product not found in database'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      debugPrint('Barcode lookup error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLookingUp = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final product = ProductModel(
        id: widget.product?.id ?? '',
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text),
        purchasePrice: _purchasePriceController.text.isEmpty
            ? null
            : double.parse(_purchasePriceController.text),
        stock: int.parse(_stockController.text),
        lowStockAlert: int.parse(_lowStockController.text),
        unit: _selectedUnit,
        barcode: _barcodeController.text.trim().isEmpty
            ? null
            : _barcodeController.text.trim(),
        createdAt: widget.product?.createdAt ?? DateTime.now(),
      );

      final service = ref.read(productsServiceProvider);
      if (_isEditing) {
        await service.updateProduct(product);
      } else {
        await service.addProduct(product);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Product updated' : 'Product added'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
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

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final service = ref.read(productsServiceProvider);
    await service.deleteProduct(widget.product!.id);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.dividerLight)),
            ),
            child: Row(
              children: [
                Icon(
                  _isEditing ? Icons.edit : Icons.add_shopping_cart,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _isEditing ? 'Edit Product' : 'Add Product',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                if (_isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.error),
                    onPressed: _delete,
                  ),
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
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 100,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Name
                    AppTextField(
                      label: 'Product Name *',
                      hint: 'e.g., Tata Salt 1kg',
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(Icons.inventory_2_outlined),
                      validator: (v) => Validators.name(v, 'Product name'),
                    ),
                    const SizedBox(height: 16),

                    // Price
                    Row(
                      children: [
                        Expanded(
                          child: CurrencyTextField(
                            label: 'Selling Price *',
                            controller: _priceController,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CurrencyTextField(
                            label: 'Cost Price',
                            controller: _purchasePriceController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Stock & Low stock
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Current Stock *',
                            controller: _stockController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (v) =>
                                Validators.positiveNumber(v, 'Stock'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            label: 'Low Stock Alert',
                            controller: _lowStockController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Unit selection
                    Text(
                      'Unit',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ProductUnit.values.map((unit) {
                        final isSelected = _selectedUnit == unit;
                        return ChoiceChip(
                          label: Text(unit.displayName),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedUnit = unit);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Barcode
                    AppTextField(
                      label: 'Barcode (Optional)',
                      hint: 'Scan or enter barcode',
                      controller: _barcodeController,
                      prefixIcon: const Icon(Icons.qr_code),
                      suffixIcon: _isLookingUp
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.qr_code_scanner),
                              onPressed: _scanAndLookupBarcode,
                            ),
                    ),

                    // Show looked up product info
                    if (_lookedUpProduct != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Found: ${_lookedUpProduct!.displayName}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_lookedUpProduct!.brand != null)
                                    Text(
                                      'Brand: ${_lookedUpProduct!.brand}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),

                    // Submit button
                    AppButton(
                      label: _isEditing ? '✅ UPDATE PRODUCT' : '✅ ADD PRODUCT',
                      onPressed: _submit,
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
