/// Products provider for CRUD operations (Firestore-based with offline support)
/// Supports demo mode with local in-memory data
library;

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/constants/app_constants.dart';
import 'package:retaillite/core/utils/id_generator.dart';
import 'package:retaillite/core/services/user_metrics_service.dart';
import 'package:retaillite/core/services/demo_data_service.dart';
import 'package:retaillite/core/services/sync_status_service.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
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

/// Products list provider - reads from Firestore OR demo data
final productsProvider = StreamProvider.autoDispose<List<ProductModel>>((ref) {
  final isDemoMode = ref.watch(isDemoModeProvider);

  // Demo mode: return local demo data as a stream
  if (isDemoMode) {
    debugPrint('📦 productsProvider: Demo mode - returning local data');
    return Stream.value(DemoDataService.getProducts().toList());
  }

  // Firebase mode: stream from Firestore
  // Safety cap at 2000 products to prevent massive reads if a user
  // accidentally imports a huge inventory
  debugPrint('📦 productsProvider: Listening to Firestore products...');
  return _firestore
      .collection(_productsPath)
      .orderBy('name')
      .limit(AppConstants.queryLimitProducts)
      .snapshots()
      .map((snapshot) {
        final products = snapshot.docs
            .map((doc) => ProductModel.fromFirestore(doc))
            .toList();
        // Report sync status
        final pendingCount = snapshot.docs
            .where((d) => d.metadata.hasPendingWrites)
            .length;
        SyncStatusService.updateCollection(
          'products',
          totalDocs: products.length,
          unsyncedDocs: pendingCount,
          hasPendingWrites: snapshot.metadata.hasPendingWrites,
        );
        if (products.length >= 1000) {
          debugPrint(
            '⚠️ productsProvider: Large inventory (${products.length} products) — '
            'consider pagination for better performance',
          );
        }
        debugPrint('📦 productsProvider: Got ${products.length} products');
        return products;
      });
});

/// Per-product sync status — maps product ID → hasPendingWrites
final productsSyncStatusProvider =
    StreamProvider.autoDispose<Map<String, bool>>((ref) {
      final isDemoMode = ref.watch(isDemoModeProvider);
      if (isDemoMode) return Stream.value({});

      return _firestore
          .collection(_productsPath)
          .orderBy('name')
          .limit(AppConstants.queryLimitProducts)
          .snapshots()
          .map(
            (snapshot) => {
              for (final doc in snapshot.docs)
                doc.id: doc.metadata.hasPendingWrites,
            },
          );
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

/// Products service for CRUD operations
/// Automatically routes to demo data or Firestore based on mode
class ProductsService {
  final bool _isDemoMode;
  final CollectionReference? _collection;

  ProductsService({required bool isDemoMode})
    : _isDemoMode = isDemoMode,
      _collection = isDemoMode ? null : _firestore.collection(_productsPath);

  /// Add new product
  Future<String> addProduct(ProductModel product) async {
    if (_isDemoMode) {
      return DemoDataService.addProduct(product);
    }

    final id = generateSafeId('product');
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
    await _collection!.doc(id).set(newProduct.toFirestore());
    unawaited(UserMetricsService.trackProductAdded());
    return id;
  }

  /// Update product
  Future<void> updateProduct(ProductModel product) async {
    if (_isDemoMode) {
      DemoDataService.updateProduct(product);
      return;
    }
    await _collection!.doc(product.id).update(product.toFirestore());
  }

  /// Delete product
  Future<void> deleteProduct(String productId) async {
    if (_isDemoMode) {
      DemoDataService.deleteProduct(productId);
      return;
    }
    await _collection!.doc(productId).delete();
    unawaited(UserMetricsService.trackProductDeleted());
  }

  /// Update stock
  Future<void> updateStock(String productId, int newStock) async {
    if (_isDemoMode) {
      DemoDataService.updateStock(productId, newStock);
      return;
    }
    final collection = _collection;
    if (collection == null) {
      throw StateError(
        'Firestore collection is not initialized in Firebase mode.',
      );
    }
    await collection.doc(productId).update({'stock': newStock});
  }

  /// Decrement stock (for billing)
  Future<void> decrementStock(String productId, int quantity) async {
    if (_isDemoMode) {
      DemoDataService.decrementStock(productId, quantity);
      return;
    }

    final collection = _collection;
    if (collection == null) {
      throw StateError(
        'Firestore collection is not initialized in Firebase mode.',
      );
    }

    final doc = await collection.doc(productId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>?;
      final currentStock = data?['stock'] as int? ?? 0;
      await collection.doc(productId).update({
        'stock': currentStock - quantity,
      });
    }
  }

  /// Find product by barcode
  Future<ProductModel?> findByBarcode(String barcode) async {
    if (_isDemoMode) {
      return DemoDataService.getProductByBarcode(barcode);
    }

    final snapshot = await _collection!
        .where('barcode', isEqualTo: barcode)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return ProductModel.fromFirestore(snapshot.docs.first);
  }
}

/// Products service provider - auto-detects demo mode
final productsServiceProvider = Provider<ProductsService>((ref) {
  final isDemoMode = ref.watch(isDemoModeProvider);
  return ProductsService(isDemoMode: isDemoMode);
});
