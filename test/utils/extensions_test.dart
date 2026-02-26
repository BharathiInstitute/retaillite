import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/utils/extensions.dart';

void main() {
  // ── String Extensions ──

  group('StringExtensions.capitalized', () {
    test('capitalizes first letter', () {
      expect('hello'.capitalized, 'Hello');
    });

    test('returns empty for empty string', () {
      expect(''.capitalized, '');
    });

    test('handles single character', () {
      expect('a'.capitalized, 'A');
    });

    test('handles already capitalized', () {
      expect('Hello'.capitalized, 'Hello');
    });

    test('handles all uppercase', () {
      expect('HELLO'.capitalized, 'HELLO');
    });
  });

  group('StringExtensions.titleCase', () {
    test('capitalizes each word', () {
      expect('hello world'.titleCase, 'Hello World');
    });

    test('returns empty for empty string', () {
      expect(''.titleCase, '');
    });

    test('handles single word', () {
      expect('hello'.titleCase, 'Hello');
    });

    test('handles mixed case', () {
      expect('hELLO wORLD'.titleCase, 'HELLO WORLD');
    });
  });

  group('StringExtensions.isDigitsOnly', () {
    test('returns true for digits', () {
      expect('123'.isDigitsOnly, isTrue);
    });

    test('returns false for mixed', () {
      expect('12a'.isDigitsOnly, isFalse);
    });

    test('returns false for empty', () {
      expect(''.isDigitsOnly, isFalse);
    });

    test('returns false for spaces', () {
      expect('12 34'.isDigitsOnly, isFalse);
    });
  });

  group('StringExtensions.initials', () {
    test('returns two initials for two words', () {
      expect('Ramesh Sharma'.initials, 'RS');
    });

    test('returns single initial for single word', () {
      expect('Ramesh'.initials, 'R');
    });

    test('returns empty for empty string', () {
      expect(''.initials, '');
    });

    test('returns empty for whitespace only', () {
      expect('   '.initials, '');
    });

    test('uses first and last word for three words', () {
      expect('Ramesh Kumar Sharma'.initials, 'RS');
    });

    test('returns uppercase initials', () {
      expect('ramesh sharma'.initials, 'RS');
    });
  });

  group('StringExtensions.truncate', () {
    test('returns original if within limit', () {
      expect('hello'.truncate(10), 'hello');
    });

    test('truncates with ellipsis', () {
      expect('hello world'.truncate(5), 'hello...');
    });

    test('returns original at exact limit', () {
      expect('hello'.truncate(5), 'hello');
    });
  });

  // ── Nullable String Extensions ──

  group('NullableStringExtensions', () {
    test('isNullOrEmpty returns true for null', () {
      const String? s = null;
      expect(s.isNullOrEmpty, isTrue);
    });

    test('isNullOrEmpty returns true for empty', () {
      const String s = '';
      expect(s.isNullOrEmpty, isTrue);
    });

    test('isNullOrEmpty returns false for non-empty', () {
      const String s = 'hello';
      expect(s.isNullOrEmpty, isFalse);
    });

    test('isNotNullOrEmpty returns true for non-empty', () {
      const String s = 'hello';
      expect(s.isNotNullOrEmpty, isTrue);
    });

    test('isNotNullOrEmpty returns false for null', () {
      const String? s = null;
      expect(s.isNotNullOrEmpty, isFalse);
    });
  });

  // ── List Extensions ──

  group('ListExtensions.safeElementAt', () {
    test('returns element at valid index', () {
      expect([1, 2, 3].safeElementAt(1), 2);
    });

    test('returns null for negative index', () {
      expect([1, 2, 3].safeElementAt(-1), isNull);
    });

    test('returns null for out of bounds index', () {
      expect([1, 2, 3].safeElementAt(5), isNull);
    });

    test('returns null for empty list', () {
      expect(<int>[].safeElementAt(0), isNull);
    });

    test('returns first element at 0', () {
      expect(['a', 'b'].safeElementAt(0), 'a');
    });
  });

  group('ListExtensions.sumBy', () {
    test('sums with selector', () {
      final items = [
        {'price': 10},
        {'price': 20},
        {'price': 30},
      ];
      expect(items.sumBy((i) => (i['price'] as int).toDouble()), 60.0);
    });

    test('returns 0 for empty list', () {
      expect(<int>[].sumBy((i) => i), 0);
    });

    test('sums integers directly', () {
      expect([1, 2, 3, 4, 5].sumBy((i) => i), 15);
    });
  });

  // ── DateTime Extensions ──

  group('DateTimeExtensions.isSameDay', () {
    test('returns true for same day', () {
      final a = DateTime(2026, 1, 30, 10, 30);
      final b = DateTime(2026, 1, 30, 18, 45);
      expect(a.isSameDay(b), isTrue);
    });

    test('returns false for different day', () {
      final a = DateTime(2026, 1, 30);
      final b = DateTime(2026, 1, 31);
      expect(a.isSameDay(b), isFalse);
    });

    test('returns false for different month', () {
      final a = DateTime(2026, 1, 30);
      final b = DateTime(2026, 2, 30);
      expect(a.isSameDay(b), isFalse);
    });
  });

  group('DateTimeExtensions.startOfDay', () {
    test('returns midnight of same day', () {
      final date = DateTime(2026, 1, 30, 14, 30, 45);
      final start = date.startOfDay;
      expect(start, DateTime(2026, 1, 30));
      expect(start.hour, 0);
      expect(start.minute, 0);
      expect(start.second, 0);
    });
  });

  group('DateTimeExtensions.endOfDay', () {
    test('returns 23:59:59 of same day', () {
      final date = DateTime(2026, 1, 30, 10);
      final end = date.endOfDay;
      expect(end.year, 2026);
      expect(end.month, 1);
      expect(end.day, 30);
      expect(end.hour, 23);
      expect(end.minute, 59);
      expect(end.second, 59);
    });
  });

  group('DateTimeExtensions.startOfWeek', () {
    test('returns Monday for a Wednesday', () {
      // 2026-01-28 is Wednesday
      final wed = DateTime(2026, 1, 28);
      final monday = wed.startOfWeek;
      expect(monday.weekday, DateTime.monday);
      expect(monday.day, 26); // Monday Jan 26
    });

    test('returns same day for Monday', () {
      // 2026-01-26 is Monday
      final mon = DateTime(2026, 1, 26);
      final result = mon.startOfWeek;
      expect(result.weekday, DateTime.monday);
      expect(result.day, 26);
    });
  });

  group('DateTimeExtensions.startOfMonth', () {
    test('returns first of month', () {
      final date = DateTime(2026, 3, 15);
      expect(date.startOfMonth, DateTime(2026, 3));
    });
  });

  group('DateTimeExtensions.isToday', () {
    test('returns true for today', () {
      expect(DateTime.now().isToday, isTrue);
    });

    test('returns false for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(yesterday.isToday, isFalse);
    });
  });

  group('DateTimeExtensions.isYesterday', () {
    test('returns true for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(yesterday.isYesterday, isTrue);
    });

    test('returns false for today', () {
      expect(DateTime.now().isYesterday, isFalse);
    });
  });

  // ── Num Extensions ──

  group('NumExtensions.clampTo', () {
    test('returns value within range', () {
      expect(5.clampTo(0, 10), 5);
    });

    test('clamps below min', () {
      expect((-5).clampTo(0, 10), 0);
    });

    test('clamps above max', () {
      expect(15.clampTo(0, 10), 10);
    });

    test('returns min when equal to min', () {
      expect(0.clampTo(0, 10), 0);
    });

    test('returns max when equal to max', () {
      expect(10.clampTo(0, 10), 10);
    });
  });
}
