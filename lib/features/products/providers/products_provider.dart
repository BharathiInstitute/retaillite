/// Products provider for CRUD operations (Firestore-based with offline support)
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/models/product_model.dart';

/// Firestore instance
final _firestore = FirebaseFirestore.instance;
final _auth = FirebaseAuth.instance;

/// Get user's products collection path
String get _productsPath {
  final uid = _auth.currentUser?.uid;
  if (uid == null) return 'products'; // Fallback
  return 'users/$uid/products';
}

/// Products list provider - reads from Firestore (with offline cache)
final productsProvider = StreamProvider.autoDispose<List<ProductModel>>((ref) {
  debugPrint('📦 productsProvider: Listening to Firestore products...');

  return _firestore.collection(_productsPath).orderBy('name').snapshots().map((
    snapshot,
  ) {
    final products = snapshot.docs
        .map((doc) => ProductModel.fromFirestore(doc))
        .toList();
    debugPrint('📦 productsProvider: Got ${products.length} products');
    return products;
  });
});

/// Low stock products provider
final lowStockProductsProvider = Provider<List<ProductModel>>((ref) {
  final products = ref.watch(productsProvider);
  return products.when(
    data: (list) => list.where((p) => p.isLowStock || p.isOutOfStock).toList(),
    loading: () => [],
    error: (e, _) => [],
  );
});

/// Products service for Firestore CRUD operations
class ProductsService {
  final CollectionReference _collection;

  ProductsService() : _collection = _firestore.collection(_productsPath);

  /// Add new product
  Future<String> addProduct(ProductModel product) async {
    final id = 'product_${DateTime.now().millisecondsSinceEpoch}';
    final newProduct = ProductModel(
      id: id,
      name: product.name,
      price: product.price,
      purchasePrice: product.purchasePrice,
      stock: product.stock,
      lowStockAlert: product.lowStockAlert,
      barcode: product.barcode,
      unit: product.unit,
      createdAt: DateTime.now(),
    );
    await _collection.doc(id).set(newProduct.toFirestore());
    return id;
  }

  /// Update product
  Future<void> updateProduct(ProductModel product) async {
    await _collection.doc(product.id).update(product.toFirestore());
  }

  /// Delete product
  Future<void> deleteProduct(String productId) async {
    await _collection.doc(productId).delete();
  }

  /// Update stock
  Future<void> updateStock(String productId, int newStock) async {
    await _collection.doc(productId).update({'stock': newStock});
  }

  /// Decrement stock (for billing)
  Future<void> decrementStock(String productId, int quantity) async {
    final doc = await _collection.doc(productId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>?;
      final currentStock = data?['stock'] as int? ?? 0;
      await _collection.doc(productId).update({
        'stock': currentStock - quantity,
      });
    }
  }

  /// Find product by barcode
  Future<ProductModel?> findByBarcode(String barcode) async {
    final snapshot = await _collection
        .where('barcode', isEqualTo: barcode)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return ProductModel.fromFirestore(snapshot.docs.first);
  }
}

/// Products service provider (singleton)
final productsServiceProvider = Provider<ProductsService>((ref) {
  return ProductsService();
});
