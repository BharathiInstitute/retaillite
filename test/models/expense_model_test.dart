import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/models/expense_model.dart';
import 'package:retaillite/models/bill_model.dart';

void main() {
  group('ExpenseCategory', () {
    test('should have correct display names', () {
      expect(ExpenseCategory.rent.displayName, 'Rent');
      expect(ExpenseCategory.salary.displayName, 'Salary');
      expect(ExpenseCategory.utilities.displayName, 'Utilities');
      expect(ExpenseCategory.supplies.displayName, 'Supplies');
      expect(ExpenseCategory.transport.displayName, 'Transport');
      expect(ExpenseCategory.maintenance.displayName, 'Maintenance');
      expect(ExpenseCategory.other.displayName, 'Other');
    });

    test('should have correct emojis', () {
      expect(ExpenseCategory.rent.emoji, '🏠');
      expect(ExpenseCategory.salary.emoji, '💰');
      expect(ExpenseCategory.utilities.emoji, '💡');
      expect(ExpenseCategory.supplies.emoji, '📦');
      expect(ExpenseCategory.transport.emoji, '🚗');
      expect(ExpenseCategory.maintenance.emoji, '🔧');
      expect(ExpenseCategory.other.emoji, '📋');
    });

    test('should parse from string correctly', () {
      expect(ExpenseCategory.fromString('rent'), ExpenseCategory.rent);
      expect(ExpenseCategory.fromString('salary'), ExpenseCategory.salary);
      expect(
        ExpenseCategory.fromString('utilities'),
        ExpenseCategory.utilities,
      );
    });

    test('should default to other for unknown values', () {
      expect(ExpenseCategory.fromString('nonexistent'), ExpenseCategory.other);
      expect(ExpenseCategory.fromString(''), ExpenseCategory.other);
    });
  });

  group('ExpenseModel', () {
    final testDate = DateTime(2024, 6, 15, 10, 30);

    test('should create expense with required fields', () {
      final expense = ExpenseModel(
        id: 'exp-1',
        amount: 5000.0,
        category: ExpenseCategory.rent,
        paymentMethod: PaymentMethod.cash,
        createdAt: testDate,
        date: '2024-06-15',
      );

      expect(expense.id, 'exp-1');
      expect(expense.amount, 5000.0);
      expect(expense.category, ExpenseCategory.rent);
      expect(expense.description, isNull);
      expect(expense.paymentMethod, PaymentMethod.cash);
      expect(expense.createdAt, testDate);
      expect(expense.date, '2024-06-15');
    });

    test('should create expense with optional description', () {
      final expense = ExpenseModel(
        id: 'exp-2',
        amount: 200.0,
        category: ExpenseCategory.transport,
        description: 'Delivery charges',
        paymentMethod: PaymentMethod.upi,
        createdAt: testDate,
        date: '2024-06-15',
      );

      expect(expense.description, 'Delivery charges');
    });

    test('should serialize to map correctly', () {
      final expense = ExpenseModel(
        id: 'exp-1',
        amount: 5000.0,
        category: ExpenseCategory.rent,
        description: 'Monthly rent',
        paymentMethod: PaymentMethod.cash,
        createdAt: testDate,
        date: '2024-06-15',
      );

      final map = expense.toMap();

      expect(map['id'], 'exp-1');
      expect(map['amount'], 5000.0);
      expect(map['category'], 'rent');
      expect(map['description'], 'Monthly rent');
      expect(map['paymentMethod'], 'cash');
      expect(map['date'], '2024-06-15');
    });

    test('should deserialize from map correctly', () {
      final map = {
        'id': 'exp-1',
        'amount': 5000.0,
        'category': 'rent',
        'description': 'Monthly rent',
        'paymentMethod': 'cash',
        'createdAt': testDate.toIso8601String(),
        'date': '2024-06-15',
      };

      final expense = ExpenseModel.fromMap(map);

      expect(expense.id, 'exp-1');
      expect(expense.amount, 5000.0);
      expect(expense.category, ExpenseCategory.rent);
      expect(expense.description, 'Monthly rent');
      expect(expense.paymentMethod, PaymentMethod.cash);
      expect(expense.date, '2024-06-15');
    });

    test('should handle missing/null fields in fromMap', () {
      final map = <String, dynamic>{
        'id': null,
        'amount': null,
        'category': null,
        'paymentMethod': null,
        'createdAt': null,
        'date': null,
      };

      final expense = ExpenseModel.fromMap(map);

      expect(expense.id, '');
      expect(expense.amount, 0.0);
      expect(expense.category, ExpenseCategory.other);
      expect(expense.description, isNull);
      expect(
        expense.paymentMethod,
        PaymentMethod.cash,
      ); // defaults to 'cash' when null
      expect(expense.date, '');
    });

    test('should handle wrong types in fromMap gracefully', () {
      final map = <String, dynamic>{
        'id': 'exp-test',
        'amount': 100, // int instead of double
        'category': 'salary',
        'paymentMethod': 'upi',
        'createdAt': testDate.toIso8601String(),
        'date': '2024-06-15',
      };

      final expense = ExpenseModel.fromMap(map);

      expect(expense.amount, 100.0); // should be converted to double
      expect(expense.category, ExpenseCategory.salary);
    });

    test('should serialize to Firestore format correctly', () {
      final expense = ExpenseModel(
        id: 'exp-1',
        amount: 1500.0,
        category: ExpenseCategory.utilities,
        description: 'Electricity bill',
        paymentMethod: PaymentMethod.upi,
        createdAt: testDate,
        date: '2024-06-15',
      );

      final firestoreMap = expense.toFirestore();

      // Firestore format should NOT include 'id'
      expect(firestoreMap.containsKey('id'), isFalse);
      expect(firestoreMap['amount'], 1500.0);
      expect(firestoreMap['category'], 'utilities');
      expect(firestoreMap['description'], 'Electricity bill');
      expect(firestoreMap['paymentMethod'], 'upi');
      expect(firestoreMap['date'], '2024-06-15');
    });

    test('should round-trip through toMap/fromMap', () {
      final original = ExpenseModel(
        id: 'exp-round',
        amount: 3500.75,
        category: ExpenseCategory.supplies,
        description: 'Packaging materials',
        paymentMethod: PaymentMethod.cash,
        createdAt: testDate,
        date: '2024-06-15',
      );

      final restored = ExpenseModel.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.amount, original.amount);
      expect(restored.category, original.category);
      expect(restored.description, original.description);
      expect(restored.paymentMethod, original.paymentMethod);
      expect(restored.date, original.date);
    });
  });
}
