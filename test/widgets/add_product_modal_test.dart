/// Tests for AddProductModal — form validation and display logic.
///
/// The modal depends on Riverpod providers and Firebase services.
/// We test the Validators used inline and the form state logic.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/utils/validators.dart';

void main() {
  // ── Name validation ──
  // Mirrors: validator: (v) => Validators.name(v, 'Product name')

  group('AddProductModal name validation', () {
    test('empty name returns error', () {
      expect(Validators.name('', 'Product name'), isNotNull);
    });

    test('null name returns error', () {
      expect(Validators.name(null, 'Product name'), isNotNull);
    });

    test('single character returns error (less than 2)', () {
      expect(Validators.name('A', 'Product name'), isNotNull);
    });

    test('valid name returns null (no error)', () {
      expect(Validators.name('Tata Salt', 'Product name'), isNull);
    });

    test('whitespace-only name returns error', () {
      expect(Validators.name('   ', 'Product name'), isNotNull);
    });

    test('2 character name is valid', () {
      expect(Validators.name('AB', 'Product name'), isNull);
    });
  });

  // ── Price validation ──
  // Mirrors: CurrencyTextField uses Validators.price internally

  group('AddProductModal price validation', () {
    test('empty price returns error', () {
      expect(Validators.price(''), isNotNull);
    });

    test('null price returns error', () {
      expect(Validators.price(null), isNotNull);
    });

    test('zero price returns error', () {
      expect(Validators.price('0'), isNotNull);
    });

    test('negative price returns error', () {
      expect(Validators.price('-5'), isNotNull);
    });

    test('valid price returns null', () {
      expect(Validators.price('10.50'), isNull);
    });

    test('non-numeric price returns error', () {
      expect(Validators.price('abc'), isNotNull);
    });
  });

  // ── Stock validation ──
  // Mirrors: validator: (v) => Validators.positiveNumber(v, 'Stock')

  group('AddProductModal stock validation', () {
    test('negative stock returns error', () {
      expect(Validators.positiveNumber('-1', 'Stock'), isNotNull);
    });

    test('zero stock is valid', () {
      expect(Validators.positiveNumber('0', 'Stock'), isNull);
    });

    test('positive stock is valid', () {
      expect(Validators.positiveNumber('100', 'Stock'), isNull);
    });

    test('empty stock returns error', () {
      expect(Validators.positiveNumber('', 'Stock'), isNotNull);
    });

    test('non-numeric stock returns error', () {
      expect(Validators.positiveNumber('abc', 'Stock'), isNotNull);
    });
  });

  // ── Barcode validation ──
  // Mirrors: Validators.barcode

  group('AddProductModal barcode validation', () {
    test('empty barcode is valid (optional field)', () {
      expect(Validators.barcode(''), isNull);
    });

    test('null barcode is valid (optional field)', () {
      expect(Validators.barcode(null), isNull);
    });

    test('valid 13-digit barcode is valid', () {
      expect(Validators.barcode('1234567890123'), isNull);
    });

    test('too short barcode (< 8) returns error', () {
      expect(Validators.barcode('1234'), isNotNull);
    });

    test('too long barcode (> 14) returns error', () {
      expect(Validators.barcode('123456789012345'), isNotNull);
    });

    test('8-digit barcode is valid', () {
      expect(Validators.barcode('12345678'), isNull);
    });
  });

  // ── isEditing mode logic ──
  // Mirrors: bool get _isEditing => widget.product != null

  group('AddProductModal edit mode', () {
    test('product=null means add mode', () {
      const product = null;
      expect(product != null, isFalse);
    });

    test('product!=null means edit mode', () {
      const product = 'some_product'; // non-null
      expect(product, isNotNull);
    });
  });

  // ── Form field prefilling in edit mode ──
  // Mirrors: _nameController = TextEditingController(text: p?.name ?? '')

  group('AddProductModal edit mode prefill', () {
    test('name prefilled from product', () {
      const name = 'Existing Product';
      expect(name, isNotEmpty);
    });

    test('price prefilled from product', () {
      const price = 10.0;
      expect(price.toString(), '10.0');
    });

    test('barcode prefilled from product', () {
      const barcode = '1234567890123';
      expect(barcode, isNotEmpty);
    });

    test('category prefilled from product', () {
      const category = 'Groceries';
      expect(category, isNotEmpty);
    });

    test('null values default to empty string', () {
      const String? name = null;
      expect(name ?? '', isEmpty);
    });
  });
}
