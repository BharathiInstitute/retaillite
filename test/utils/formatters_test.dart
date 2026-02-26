import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/utils/formatters.dart';

void main() {
  // ── Currency Formatting ──

  group('Formatters.currency', () {
    test('formats zero', () {
      expect(Formatters.currency(0), '₹0');
    });

    test('formats small amount', () {
      expect(Formatters.currency(5), '₹5');
    });

    test('formats with Indian commas', () {
      expect(Formatters.currency(1234), '₹1,234');
    });

    test('formats large amount with Indian commas', () {
      expect(Formatters.currency(123456), '₹1,23,456');
    });

    test('formats very large amount', () {
      expect(Formatters.currency(1000000), '₹10,00,000');
    });

    test('truncates decimals', () {
      // No decimals format — should round/truncate
      final result = Formatters.currency(1234.56);
      expect(result, contains('₹'));
      expect(result, contains('1,235')); // rounded
    });

    test('formats negative amount', () {
      final result = Formatters.currency(-500);
      expect(result, contains('500'));
    });
  });

  group('Formatters.currencyWithDecimals', () {
    test('formats with 2 decimals', () {
      expect(Formatters.currencyWithDecimals(1234.56), '₹1,234.56');
    });

    test('adds trailing zeros', () {
      expect(Formatters.currencyWithDecimals(100), '₹100.00');
    });

    test('formats zero', () {
      expect(Formatters.currencyWithDecimals(0), '₹0.00');
    });
  });

  group('Formatters.number', () {
    test('formats with Indian commas', () {
      expect(Formatters.number(123456), '1,23,456');
    });

    test('formats small number without commas', () {
      expect(Formatters.number(999), '999');
    });

    test('formats zero', () {
      expect(Formatters.number(0), '0');
    });
  });

  // ── Phone Formatting ──

  group('Formatters.phone', () {
    test('formats 10-digit number with country code', () {
      expect(Formatters.phone('9876543210'), '+91 98765 43210');
    });

    test('returns original if not 10 digits', () {
      expect(Formatters.phone('12345'), '12345');
    });

    test('strips non-digit chars before formatting', () {
      expect(Formatters.phone('987-654-3210'), '+91 98765 43210');
    });
  });

  group('Formatters.phoneShort', () {
    test('formats 10-digit number with space', () {
      expect(Formatters.phoneShort('9876543210'), '98765 43210');
    });

    test('strips country code prefix', () {
      expect(Formatters.phoneShort('+919876543210'), '98765 43210');
    });

    test('returns original if too short', () {
      expect(Formatters.phoneShort('12345'), '12345');
    });
  });

  // ── Date Formatting ──

  group('Formatters.date', () {
    test('formats date correctly', () {
      final date = DateTime(2026, 1, 30);
      expect(Formatters.date(date), '30 Jan 2026');
    });

    test('formats single-digit day', () {
      final date = DateTime(2026, 3, 5);
      expect(Formatters.date(date), '5 Mar 2026');
    });
  });

  group('Formatters.dateForStorage', () {
    test('formats in ISO-like format', () {
      final date = DateTime(2026, 1, 30);
      expect(Formatters.dateForStorage(date), '2026-01-30');
    });

    test('pads month and day', () {
      final date = DateTime(2026, 3, 5);
      expect(Formatters.dateForStorage(date), '2026-03-05');
    });
  });

  group('Formatters.time', () {
    test('formats AM time', () {
      final date = DateTime(2026, 1, 1, 9, 30);
      expect(Formatters.time(date), '9:30 AM');
    });

    test('formats PM time', () {
      final date = DateTime(2026, 1, 1, 14, 45);
      expect(Formatters.time(date), '2:45 PM');
    });

    test('formats midnight', () {
      final date = DateTime(2026, 1, 1, 0);
      expect(Formatters.time(date), '12:00 AM');
    });
  });

  group('Formatters.dateTime', () {
    test('formats full date time', () {
      final date = DateTime(2026, 1, 30, 11, 30);
      expect(Formatters.dateTime(date), '30 Jan 2026, 11:30 AM');
    });
  });

  group('Formatters.relativeDate', () {
    test('returns Today for today', () {
      expect(Formatters.relativeDate(DateTime.now()), 'Today');
    });

    test('returns Yesterday for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(Formatters.relativeDate(yesterday), 'Yesterday');
    });

    test('returns days ago for < 7 days', () {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      expect(Formatters.relativeDate(threeDaysAgo), '3 days ago');
    });

    test('returns weeks ago for < 30 days', () {
      final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));
      expect(Formatters.relativeDate(twoWeeksAgo), '2 weeks ago');
    });

    test('returns formatted date for > 30 days', () {
      final oldDate = DateTime.now().subtract(const Duration(days: 60));
      final result = Formatters.relativeDate(oldDate);
      // Should be a formatted date, not "X days ago"
      expect(result, isNot(contains('days ago')));
      expect(result, isNot(contains('weeks ago')));
    });
  });

  // ── Quantity, Percentage, BillNumber, Stock ──

  group('Formatters.quantity', () {
    test('formats integer quantity', () {
      expect(Formatters.quantity(5, 'kg'), '5 kg');
    });

    test('formats decimal quantity', () {
      expect(Formatters.quantity(2.5, 'liter'), '2.5 liter');
    });

    test('formats zero quantity', () {
      expect(Formatters.quantity(0, 'pcs'), '0 pcs');
    });
  });

  group('Formatters.percentage', () {
    test('formats with one decimal', () {
      expect(Formatters.percentage(10.5), '10.5%');
    });

    test('formats zero', () {
      expect(Formatters.percentage(0), '0.0%');
    });

    test('formats whole number', () {
      expect(Formatters.percentage(100), '100.0%');
    });
  });

  group('Formatters.billNumber', () {
    test('adds hash prefix', () {
      expect(Formatters.billNumber(1234), '#1234');
    });

    test('formats zero', () {
      expect(Formatters.billNumber(0), '#0');
    });
  });

  group('Formatters.stockStatus', () {
    test('returns Out of Stock for 0', () {
      expect(Formatters.stockStatus(0, 10), 'Out of Stock');
    });

    test('returns Low Stock when at alert threshold', () {
      expect(Formatters.stockStatus(5, 5), 'Low Stock');
    });

    test('returns Low Stock when below alert threshold', () {
      expect(Formatters.stockStatus(3, 5), 'Low Stock');
    });

    test('returns In Stock when above alert threshold', () {
      expect(Formatters.stockStatus(50, 5), 'In Stock');
    });

    test('returns In Stock when no alert threshold', () {
      expect(Formatters.stockStatus(50, null), 'In Stock');
    });

    test('returns Out of Stock with null threshold and 0 stock', () {
      expect(Formatters.stockStatus(0, null), 'Out of Stock');
    });
  });

  // ── Extensions ──

  group('FormatterExtensions on num', () {
    test('asCurrency works', () {
      expect(1234.asCurrency, '₹1,234');
    });

    test('asNumber works', () {
      expect(123456.asNumber, '1,23,456');
    });

    test('asPercentage works', () {
      expect(10.5.asPercentage, '10.5%');
    });
  });

  group('DateFormatterExtensions on DateTime', () {
    test('formatted works', () {
      final date = DateTime(2026, 1, 30);
      expect(date.formatted, '30 Jan 2026');
    });

    test('formattedTime works', () {
      final date = DateTime(2026, 1, 1, 14, 30);
      expect(date.formattedTime, '2:30 PM');
    });

    test('formattedDateTime works', () {
      final date = DateTime(2026, 1, 30, 11, 30);
      expect(date.formattedDateTime, '30 Jan 2026, 11:30 AM');
    });

    test('relative works', () {
      expect(DateTime.now().relative, 'Today');
    });

    test('forStorage works', () {
      final date = DateTime(2026, 1, 30);
      expect(date.forStorage, '2026-01-30');
    });
  });
}
