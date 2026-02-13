/// Expense model for tracking business expenses
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:retaillite/models/bill_model.dart';

/// Expense category types
enum ExpenseCategory {
  rent('Rent', '🏠'),
  salary('Salary', '💰'),
  utilities('Utilities', '💡'),
  supplies('Supplies', '📦'),
  transport('Transport', '🚗'),
  maintenance('Maintenance', '🔧'),
  other('Other', '📋');

  final String displayName;
  final String emoji;

  const ExpenseCategory(this.displayName, this.emoji);

  static ExpenseCategory fromString(String value) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExpenseCategory.other,
    );
  }
}

/// Expense model
class ExpenseModel {
  final String id;
  final double amount;
  final ExpenseCategory category;
  final String? description;
  final PaymentMethod paymentMethod;
  final DateTime createdAt;
  final String date; // YYYY-MM-DD for querying

  const ExpenseModel({
    required this.id,
    required this.amount,
    required this.category,
    this.description,
    required this.paymentMethod,
    required this.createdAt,
    required this.date,
  });

  factory ExpenseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExpenseModel(
      id: doc.id,
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      category: ExpenseCategory.fromString(
        (data['category'] as String?) ?? 'other',
      ),
      description: data['description'] as String?,
      paymentMethod: PaymentMethod.fromString(
        (data['paymentMethod'] as String?) ?? 'cash',
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      date: (data['date'] as String?) ?? '',
    );
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: (map['id'] as String?) ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: ExpenseCategory.fromString(
        (map['category'] as String?) ?? 'other',
      ),
      description: map['description'] as String?,
      paymentMethod: PaymentMethod.fromString(
        (map['paymentMethod'] as String?) ?? 'cash',
      ),
      createdAt: map['createdAt'] is String
          ? DateTime.parse(map['createdAt'] as String)
          : (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      date: (map['date'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category.name,
      'description': description,
      'paymentMethod': paymentMethod.name,
      'createdAt': createdAt.toIso8601String(),
      'date': date,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'amount': amount,
      'category': category.name,
      'description': description,
      'paymentMethod': paymentMethod.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'date': date,
    };
  }
}
