/// Input validation utilities
library;

class Validators {
  Validators._();

  /// Validate Indian mobile number (10 digits)
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length != 10) {
      return 'Enter valid 10 digit number';
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned)) {
      return 'Enter valid mobile number';
    }
    return null;
  }

  /// Validate OTP (4 digits)
  static String? otp(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    if (value.length != 4) {
      return 'Enter 4 digit OTP';
    }
    if (!RegExp(r'^\d{4}$').hasMatch(value)) {
      return 'Invalid OTP';
    }
    return null;
  }

  /// Validate required field
  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate name (2+ characters, letters only)
  static String? name(String? value, [String fieldName = 'Name']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    return null;
  }

  /// Validate price (positive number)
  static String? price(String? value) {
    if (value == null || value.isEmpty) {
      return 'Price is required';
    }
    final price = double.tryParse(value);
    if (price == null) {
      return 'Enter valid price';
    }
    if (price <= 0) {
      return 'Price must be greater than 0';
    }
    return null;
  }

  /// Validate positive number (non-negative integer)
  static String? positiveNumber(String? value, [String fieldName = 'Value']) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    final number = int.tryParse(value);
    if (number == null) {
      return 'Enter valid number';
    }
    if (number < 0) {
      return '$fieldName cannot be negative';
    }
    return null;
  }

  /// Validate stock (non-negative integer)
  static String? stock(String? value) {
    if (value == null || value.isEmpty) {
      return 'Stock is required';
    }
    final stock = int.tryParse(value);
    if (stock == null) {
      return 'Enter valid number';
    }
    if (stock < 0) {
      return 'Stock cannot be negative';
    }
    return null;
  }

  /// Validate GST number (optional, 15 alphanumeric)
  static String? gstNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    if (!RegExp(
      r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
    ).hasMatch(value.toUpperCase())) {
      return 'Enter valid GST number';
    }
    return null;
  }

  /// Validate barcode (optional)
  static String? barcode(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    if (value.length < 8 || value.length > 14) {
      return 'Barcode must be 8-14 characters';
    }
    return null;
  }

  /// Validate amount (positive number)
  static String? amount(String? value, {double? max}) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Enter valid amount';
    }
    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }
    if (max != null && amount > max) {
      return 'Amount cannot exceed ₹${max.toInt()}';
    }
    return null;
  }
}
