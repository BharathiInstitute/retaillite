/// Product model for LITE app
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Product unit types
enum ProductUnit {
  piece('Piece', 'pcs'),
  kg('Kilogram', 'kg'),
  gram('Gram', 'g'),
  liter('Liter', 'L'),
  ml('Milliliter', 'ml'),
  pack('Pack', 'pack'),
  box('Box', 'box'),
  dozen('Dozen', 'dz');

  final String displayName;
  final String shortName;

  const ProductUnit(this.displayName, this.shortName);

  static ProductUnit fromString(String value) {
    return ProductUnit.values.firstWhere(
      (e) => e.name == value || e.shortName == value,
      orElse: () => ProductUnit.piece,
    );
  }
}

class ProductModel {
  final String id;
  final String name;
  final double price;
  final double? purchasePrice;
  final int stock;
  final int? lowStockAlert;
  final String? barcode;
  final String? imageUrl;
  final ProductUnit unit;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.price,
    this.purchasePrice,
    required this.stock,
    this.lowStockAlert,
    this.barcode,
    this.imageUrl,
    this.unit = ProductUnit.piece,
    required this.createdAt,
    this.updatedAt,
  });

  /// Check if stock is low
  bool get isLowStock => lowStockAlert != null && stock <= lowStockAlert!;

  /// Check if out of stock
  bool get isOutOfStock => stock <= 0;

  /// Calculate profit per unit
  double? get profit => purchasePrice != null ? price - purchasePrice! : null;

  /// Calculate profit percentage
  double? get profitPercentage => purchasePrice != null && purchasePrice! > 0
      ? ((price - purchasePrice!) / purchasePrice!) * 100
      : null;

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      purchasePrice: data['purchasePrice']?.toDouble(),
      stock: data['stock'] ?? 0,
      lowStockAlert: data['lowStockAlert'],
      barcode: data['barcode'],
      imageUrl: data['imageUrl'],
      unit: ProductUnit.fromString(data['unit'] ?? 'piece'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'purchasePrice': purchasePrice,
      'stock': stock,
      'lowStockAlert': lowStockAlert,
      'barcode': barcode,
      'imageUrl': imageUrl,
      'unit': unit.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  ProductModel copyWith({
    String? name,
    double? price,
    double? purchasePrice,
    int? stock,
    int? lowStockAlert,
    String? barcode,
    String? imageUrl,
    ProductUnit? unit,
  }) {
    return ProductModel(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      stock: stock ?? this.stock,
      lowStockAlert: lowStockAlert ?? this.lowStockAlert,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
      unit: unit ?? this.unit,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
