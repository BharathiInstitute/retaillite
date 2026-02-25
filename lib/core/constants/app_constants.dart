/// App-wide constants for Tulasi Stores retail billing app
library;

class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Tulasi Stores';
  static const String appTagline = 'भारत का सबसे आसान बिलिंग ऐप';
  static const String version = '1.0.0';

  // FREE Tier Limits
  static const int freeMaxProducts = 20;
  static const int freeMaxBillsPerDay = 5;
  static const int freeMaxCustomers = 10;

  // PAID Tier Limits
  static const int paidMaxProducts = 500;
  static const int paidMaxCustomers = 1000;
  static const int paidPriceInr = 100;

  // OTP Settings
  static const int otpLength = 4;
  static const int otpResendSeconds = 30;
  static const int otpTimeoutSeconds = 60;

  // Bill Settings
  static const String currencySymbol = '₹';
  static const String countryCode = '+91';

  // Date Formats
  static const String dateFormatDisplay = 'd MMM yyyy';
  static const String dateFormatStorage = 'yyyy-MM-dd';
  static const String timeFormat = 'h:mm a';

  // Animation Durations
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);

  // Firestore Query Limits
  static const int queryLimitBills = 500;
  static const int queryLimitExpenses = 500;
  static const int queryLimitProducts = 500;
  static const int queryLimitCustomers = 500;
  static const int queryLimitTransactions = 100;
  static const int queryLimitNotifications = 50;
  static const int queryLimitAdminAnalytics = 200;
}
