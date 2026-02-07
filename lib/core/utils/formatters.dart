/// Formatting utilities for currency, dates, and numbers
library;

import 'package:intl/intl.dart';
import 'package:retaillite/core/constants/app_constants.dart';

class Formatters {
  Formatters._();

  // Currency Formatting
  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: AppConstants.currencySymbol,
    decimalDigits: 0,
  );

  static final _currencyFormatWithDecimals = NumberFormat.currency(
    locale: 'en_IN',
    symbol: AppConstants.currencySymbol,
    decimalDigits: 2,
  );

  /// Format amount as currency (₹1,234)
  static String currency(num amount) => _currencyFormat.format(amount);

  /// Format amount with decimals (₹1,234.56)
  static String currencyWithDecimals(num amount) =>
      _currencyFormatWithDecimals.format(amount);

  /// Format amount without symbol (1,234)
  static String number(num value) =>
      NumberFormat('#,##,###', 'en_IN').format(value);

  // Phone Formatting
  /// Format phone number (+91 98765 43210)
  static String phone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length == 10) {
      return '${AppConstants.countryCode} ${cleaned.substring(0, 5)} ${cleaned.substring(5)}';
    }
    return phone;
  }

  /// Format phone for display (98765 43210)
  static String phoneShort(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length >= 10) {
      final last10 = cleaned.substring(cleaned.length - 10);
      return '${last10.substring(0, 5)} ${last10.substring(5)}';
    }
    return phone;
  }

  // Date Formatting
  static final _displayDateFormat = DateFormat(AppConstants.dateFormatDisplay);
  static final _storageDateFormat = DateFormat(AppConstants.dateFormatStorage);
  static final _timeFormat = DateFormat(AppConstants.timeFormat);
  static final _dateTimeFormat = DateFormat('d MMM yyyy, h:mm a');

  /// Format date for display (30 Jan 2026)
  static String date(DateTime date) => _displayDateFormat.format(date);

  /// Format date for storage (2026-01-30)
  static String dateForStorage(DateTime date) =>
      _storageDateFormat.format(date);

  /// Format time (11:30 AM)
  static String time(DateTime date) => _timeFormat.format(date);

  /// Format full date time (30 Jan 2026, 11:30 AM)
  static String dateTime(DateTime date) => _dateTimeFormat.format(date);

  /// Relative time (Today, Yesterday, 3 days ago)
  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateOnly).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    if (difference < 30) return '${(difference / 7).floor()} weeks ago';
    return Formatters.date(date);
  }

  // Quantity Formatting
  /// Format quantity with unit (5 kg, 2 pcs)
  static String quantity(num qty, String unit) {
    final qtyStr = qty % 1 == 0 ? qty.toInt().toString() : qty.toString();
    return '$qtyStr $unit';
  }

  // Percentage Formatting
  /// Format as percentage (10.5%)
  static String percentage(num value) => '${value.toStringAsFixed(1)}%';

  // Bill Number Formatting
  /// Format bill number (#1234)
  static String billNumber(int number) => '#$number';

  // Stock Status
  /// Get stock status text
  static String stockStatus(int stock, int? lowAlert) {
    if (stock == 0) return 'Out of Stock';
    if (lowAlert != null && stock <= lowAlert) return 'Low Stock';
    return 'In Stock';
  }
}

/// Extension for easy access
extension FormatterExtensions on num {
  String get asCurrency => Formatters.currency(this);
  String get asNumber => Formatters.number(this);
  String get asPercentage => Formatters.percentage(this);
}

extension DateFormatterExtensions on DateTime {
  String get formatted => Formatters.date(this);
  String get formattedTime => Formatters.time(this);
  String get formattedDateTime => Formatters.dateTime(this);
  String get relative => Formatters.relativeDate(this);
  String get forStorage => Formatters.dateForStorage(this);
}
