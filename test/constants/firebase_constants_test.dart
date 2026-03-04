/// Tests for FirebaseConstants — collection/field name integrity
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/constants/firebase_constants.dart';

void main() {
  group('FirebaseConstants collections', () {
    test('collection names are non-empty', () {
      expect(FirebaseConstants.usersCollection, isNotEmpty);
      expect(FirebaseConstants.productsCollection, isNotEmpty);
      expect(FirebaseConstants.customersCollection, isNotEmpty);
      expect(FirebaseConstants.billsCollection, isNotEmpty);
      expect(FirebaseConstants.transactionsCollection, isNotEmpty);
    });

    test('collection names are lowercase', () {
      expect(FirebaseConstants.usersCollection, matches(RegExp(r'^[a-z]+$')));
      expect(
        FirebaseConstants.productsCollection,
        matches(RegExp(r'^[a-z]+$')),
      );
      expect(
        FirebaseConstants.customersCollection,
        matches(RegExp(r'^[a-z]+$')),
      );
      expect(FirebaseConstants.billsCollection, matches(RegExp(r'^[a-z]+$')));
      expect(
        FirebaseConstants.transactionsCollection,
        matches(RegExp(r'^[a-z]+$')),
      );
    });

    test('expected collection values', () {
      expect(FirebaseConstants.usersCollection, 'users');
      expect(FirebaseConstants.productsCollection, 'products');
      expect(FirebaseConstants.customersCollection, 'customers');
      expect(FirebaseConstants.billsCollection, 'bills');
      expect(FirebaseConstants.transactionsCollection, 'transactions');
    });
  });

  group('FirebaseConstants field names', () {
    test('user fields are non-empty', () {
      expect(FirebaseConstants.fieldShopName, isNotEmpty);
      expect(FirebaseConstants.fieldOwnerName, isNotEmpty);
      expect(FirebaseConstants.fieldPhone, isNotEmpty);
      expect(FirebaseConstants.fieldSettings, isNotEmpty);
      expect(FirebaseConstants.fieldIsPaid, isNotEmpty);
    });

    test('product fields are non-empty', () {
      expect(FirebaseConstants.fieldName, isNotEmpty);
      expect(FirebaseConstants.fieldPrice, isNotEmpty);
      expect(FirebaseConstants.fieldPurchasePrice, isNotEmpty);
      expect(FirebaseConstants.fieldStock, isNotEmpty);
      expect(FirebaseConstants.fieldBarcode, isNotEmpty);
    });

    test('bill fields are non-empty', () {
      expect(FirebaseConstants.fieldBillNumber, isNotEmpty);
      expect(FirebaseConstants.fieldItems, isNotEmpty);
      expect(FirebaseConstants.fieldTotal, isNotEmpty);
      expect(FirebaseConstants.fieldPaymentMethod, isNotEmpty);
    });

    test('field names use camelCase convention', () {
      // Spot-check that multi-word fields use camelCase
      expect(FirebaseConstants.fieldShopName, 'shopName');
      expect(FirebaseConstants.fieldOwnerName, 'ownerName');
      expect(FirebaseConstants.fieldPurchasePrice, 'purchasePrice');
      expect(FirebaseConstants.fieldLowStockAlert, 'lowStockAlert');
      expect(FirebaseConstants.fieldBillNumber, 'billNumber');
      expect(FirebaseConstants.fieldPaymentMethod, 'paymentMethod');
      expect(FirebaseConstants.fieldCustomerId, 'customerId');
      expect(FirebaseConstants.fieldReceivedAmount, 'receivedAmount');
    });
  });
}
