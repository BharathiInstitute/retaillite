/// Transaction model for Khata (credit book)
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Transaction type
enum TransactionType {
  purchase('Purchase', '🛒', true), // Customer bought on credit
  payment('Payment', '💵', false); // Customer made payment

  final String displayName;
  final String emoji;
  final bool isDebit; // Increases customer balance

  const TransactionType(this.displayName, this.emoji, this.isDebit);

  static TransactionType fromString(String value) {
    return TransactionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TransactionType.purchase,
    );
  }
}

class TransactionModel {
  final String id;
  final String customerId;
  final TransactionType type;
  final double amount;
  final String? billId;
  final String? note;
  final String? paymentMode; // For payments: cash/upi/bank
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.customerId,
    required this.type,
    required this.amount,
    this.billId,
    this.note,
    this.paymentMode,
    required this.createdAt,
  });

  /// Signed amount (positive for purchase, negative for payment)
  double get signedAmount => type.isDebit ? amount : -amount;

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      type: TransactionType.fromString(data['type'] ?? 'purchase'),
      amount: (data['amount'] ?? 0).toDouble(),
      billId: data['billId'],
      note: data['note'],
      paymentMode: data['paymentMode'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'type': type.name,
      'amount': amount,
      'billId': billId,
      'note': note,
      'paymentMode': paymentMode,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
