import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/utils/id_generator.dart';

void main() {
  group('generateSafeId', () {
    test('starts with prefix', () {
      final id = generateSafeId('bill');
      expect(id, startsWith('bill_'));
    });

    test('has expected format: prefix_timestamp_hex4', () {
      final id = generateSafeId('product');
      final parts = id.split('_');
      expect(parts.length, 3);
      expect(parts[0], 'product');
      // Timestamp should be numeric
      expect(int.tryParse(parts[1]), isNotNull);
      // Suffix should be 4 hex chars
      expect(parts[2].length, 4);
      expect(RegExp(r'^[0-9a-f]{4}$').hasMatch(parts[2]), isTrue);
    });

    test('generates unique IDs across 100 calls', () {
      final ids = <String>{};
      for (var i = 0; i < 100; i++) {
        ids.add(generateSafeId('test'));
      }
      // Allow for theoretical timestamp collision with same random,
      // but in practice should be unique
      expect(ids.length, greaterThanOrEqualTo(95));
    });

    test('works with empty prefix', () {
      final id = generateSafeId('');
      expect(id, startsWith('_'));
    });

    test('handles special characters in prefix', () {
      final id = generateSafeId('my-item');
      expect(id, startsWith('my-item_'));
    });
  });

  group('generateBillNumber', () {
    test('returns number in valid range', () {
      final num = generateBillNumber();
      expect(num, greaterThanOrEqualTo(0));
      expect(num, lessThan(100000));
    });

    test('generates different numbers across calls', () {
      final numbers = <int>{};
      for (var i = 0; i < 50; i++) {
        numbers.add(generateBillNumber());
      }
      // Should have reasonable variety
      expect(numbers.length, greaterThan(10));
    });

    test('returns integer value', () {
      final num = generateBillNumber();
      expect(num, isA<int>());
    });
  });
}
