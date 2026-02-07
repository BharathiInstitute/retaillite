/// Cart provider for billing
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/models/bill_model.dart';
import 'package:retaillite/models/product_model.dart';

/// Cart state
class CartState {
  final List<CartItem> items;
  final String? customerId;
  final String? customerName;

  const CartState({this.items = const [], this.customerId, this.customerName});

  double get total => items.fold(0, (sum, item) => sum + item.total);
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  CartState copyWith({
    List<CartItem>? items,
    String? customerId,
    String? customerName,
  }) {
    return CartState(
      items: items ?? this.items,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
    );
  }

  CartState clearCustomer() {
    return CartState(items: items);
  }
}

/// Cart notifier
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  /// Add product to cart
  void addProduct(ProductModel product, {int quantity = 1}) {
    final existingIndex = state.items.indexWhere(
      (item) => item.productId == product.id,
    );

    if (existingIndex >= 0) {
      // Update existing item quantity
      final updatedItems = [...state.items];
      final existing = updatedItems[existingIndex];
      updatedItems[existingIndex] = existing.copyWith(
        quantity: existing.quantity + quantity,
      );
      state = state.copyWith(items: updatedItems);
    } else {
      // Add new item
      final newItem = CartItem(
        productId: product.id,
        name: product.name,
        price: product.price,
        quantity: quantity,
        unit: product.unit.shortName,
      );
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  /// Update item quantity
  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    final updatedItems = state.items.map((item) {
      if (item.productId == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  /// Increment item quantity
  void incrementQuantity(String productId) {
    final item = state.items.firstWhere(
      (item) => item.productId == productId,
      orElse: () => throw Exception('Item not found'),
    );
    updateQuantity(productId, item.quantity + 1);
  }

  /// Decrement item quantity
  void decrementQuantity(String productId) {
    final item = state.items.firstWhere(
      (item) => item.productId == productId,
      orElse: () => throw Exception('Item not found'),
    );
    updateQuantity(productId, item.quantity - 1);
  }

  /// Remove item from cart
  void removeItem(String productId) {
    final updatedItems = state.items
        .where((item) => item.productId != productId)
        .toList();
    state = state.copyWith(items: updatedItems);
  }

  /// Set customer for the bill
  void setCustomer(String customerId, String customerName) {
    state = state.copyWith(customerId: customerId, customerName: customerName);
  }

  /// Clear customer
  void clearCustomer() {
    state = state.clearCustomer();
  }

  /// Clear entire cart
  void clearCart() {
    state = const CartState();
  }
}

/// Cart provider
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
