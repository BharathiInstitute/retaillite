/// Bill and Cart Item models
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Payment method types
enum PaymentMethod {
  cash('Cash', '💵'),
  upi('UPI', '📱'),
  udhar('Udhar', '📝');

  final String displayName;
  final String emoji;

  const PaymentMethod(this.displayName, this.emoji);

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentMethod.cash,
    );
  }
}

/// Cart item model (used during billing)
class CartItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String unit;

  const CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.unit,
  });

  double get total => price * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      productId: productId,
      name: name,
      price: price,
      quantity: quantity ?? this.quantity,
      unit: unit,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'unit': unit,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
      unit: map['unit'] ?? 'pcs',
    );
  }
}

/// Bill model
class BillModel {
  final String id;
  final int billNumber;
  final List<CartItem> items;
  final double total;
  final PaymentMethod paymentMethod;
  final String? customerId;
  final String? customerName;
  final double? receivedAmount;
  final DateTime createdAt;
  final String date; // YYYY-MM-DD for querying

  const BillModel({
    required this.id,
    required this.billNumber,
    required this.items,
    required this.total,
    required this.paymentMethod,
    this.customerId,
    this.customerName,
    this.receivedAmount,
    required this.createdAt,
    required this.date,
  });

  /// Calculate change to return
  double? get changeAmount {
    if (receivedAmount == null) return null;
    return receivedAmount! - total;
  }

  /// Number of total items
  int get itemCount => items.fold(0, (total, item) => total + item.quantity);

  factory BillModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BillModel(
      id: doc.id,
      billNumber: data['billNumber'] ?? 0,
      items:
          (data['items'] as List<dynamic>?)
              ?.map((e) => CartItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: (data['total'] ?? 0).toDouble(),
      paymentMethod: PaymentMethod.fromString(data['paymentMethod'] ?? 'cash'),
      customerId: data['customerId'],
      customerName: data['customerName'],
      receivedAmount: data['receivedAmount']?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      date: data['date'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'billNumber': billNumber,
      'items': items.map((e) => e.toMap()).toList(),
      'total': total,
      'paymentMethod': paymentMethod.name,
      'customerId': customerId,
      'customerName': customerName,
      'receivedAmount': receivedAmount,
      'createdAt': createdAt.toIso8601String(),
      'date': date,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'billNumber': billNumber,
      'items': items.map((e) => e.toMap()).toList(),
      'total': total,
      'paymentMethod': paymentMethod.name,
      'customerId': customerId,
      'customerName': customerName,
      'receivedAmount': receivedAmount,
      'createdAt': Timestamp.fromDate(createdAt),
      'date': date,
    };
  }
}
