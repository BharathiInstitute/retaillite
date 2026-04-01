/// Product model for RetailLite app
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Sentinel value for distinguishing "not provided" from "set to null" in copyWith
const _sentinel = Object();

/// Product unit types
enum ProductUnit {
  piece('Piece', 'pcs'),
  kg('Kilogram', 'kg'),
  gram('Gram', 'g'),
  liter('Liter', 'L'),
  ml('Milliliter', 'ml'),
  pack('Pack', 'pack'),
  box('Box', 'box'),
  dozen('Dozen', 'dz'),
  unknown('Unknown', '?');

  final String displayName;
  final String shortName;

  const ProductUnit(this.displayName, this.shortName);

  static ProductUnit fromString(String value) {
    return ProductUnit.values.firstWhere(
      (e) => e.name == value || e.shortName == value,
      orElse: () => ProductUnit.unknown,
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
  final String? category;
  final String? hsnCode;
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
    this.category,
    this.hsnCode,
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
      name: (data['name'] as String?) ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      purchasePrice: (data['purchasePrice'] as num?)?.toDouble(),
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      lowStockAlert: (data['lowStockAlert'] as num?)?.toInt(),
      barcode: data['barcode'] as String?,
      imageUrl: data['imageUrl'] as String?,
      category: data['category'] as String?,
      hsnCode: data['hsnCode'] as String?,
      unit: ProductUnit.fromString((data['unit'] as String?) ?? 'piece'),
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
      'category': category,
      'hsnCode': hsnCode,
      'unit': unit.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  ProductModel copyWith({
    String? name,
    double? price,
    Object? purchasePrice = _sentinel,
    int? stock,
    Object? lowStockAlert = _sentinel,
    Object? barcode = _sentinel,
    Object? imageUrl = _sentinel,
    Object? category = _sentinel,
    Object? hsnCode = _sentinel,
    ProductUnit? unit,
  }) {
    return ProductModel(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      purchasePrice: purchasePrice == _sentinel
          ? this.purchasePrice
          : purchasePrice as double?,
      stock: stock ?? this.stock,
      lowStockAlert: lowStockAlert == _sentinel
          ? this.lowStockAlert
          : lowStockAlert as int?,
      barcode: barcode == _sentinel ? this.barcode : barcode as String?,
      imageUrl: imageUrl == _sentinel ? this.imageUrl : imageUrl as String?,
      category: category == _sentinel ? this.category : category as String?,
      hsnCode: hsnCode == _sentinel ? this.hsnCode : hsnCode as String?,
      unit: unit ?? this.unit,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
