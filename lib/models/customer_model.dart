/// Customer model for Khata (credit book)
library;

import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final String? address;
  final double balance; // Positive = customer owes money
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastTransactionAt;

  const CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.address,
    this.balance = 0,
    required this.createdAt,
    this.updatedAt,
    this.lastTransactionAt,
  });

  /// Check if customer has pending dues
  bool get hasDue => balance > 0;

  /// Days since last transaction
  int? get daysSinceLastTransaction {
    if (lastTransactionAt == null) return null;
    return DateTime.now().difference(lastTransactionAt!).inDays;
  }

  /// Check if overdue (more than 30 days)
  bool get isOverdue =>
      daysSinceLastTransaction != null && daysSinceLastTransaction! > 30;

  factory CustomerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomerModel(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'],
      balance: (data['balance'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      lastTransactionAt: (data['lastTransactionAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'balance': balance,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'lastTransactionAt': lastTransactionAt != null
          ? Timestamp.fromDate(lastTransactionAt!)
          : null,
    };
  }

  CustomerModel copyWith({
    String? name,
    String? phone,
    String? address,
    double? balance,
    DateTime? lastTransactionAt,
  }) {
    return CustomerModel(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      balance: balance ?? this.balance,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lastTransactionAt: lastTransactionAt ?? this.lastTransactionAt,
    );
  }
}
