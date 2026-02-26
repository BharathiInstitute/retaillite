import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/constants/app_constants.dart';
import 'package:retaillite/core/data/mock_data.dart';
import 'package:retaillite/models/product_model.dart';

void main() {
  // ── AppConstants ──

  group('AppConstants', () {
    test('app name is set', () {
      expect(AppConstants.appName, isNotEmpty);
    });

    test('currency symbol is ₹', () {
      expect(AppConstants.currencySymbol, '₹');
    });

    test('country code is +91', () {
      expect(AppConstants.countryCode, '+91');
    });

    test('date format display is correct', () {
      expect(AppConstants.dateFormatDisplay, 'd MMM yyyy');
    });

    test('OTP length is 4', () {
      expect(AppConstants.otpLength, 4);
    });

    test('free tier has product limit', () {
      expect(AppConstants.freeMaxProducts, greaterThan(0));
    });

    test('free tier has bill limit', () {
      expect(AppConstants.freeMaxBillsPerDay, greaterThan(0));
    });

    test('free tier has customer limit', () {
      expect(AppConstants.freeMaxCustomers, greaterThan(0));
    });

    test('paid tier limits exceed free tier', () {
      expect(
        AppConstants.paidMaxProducts,
        greaterThan(AppConstants.freeMaxProducts),
      );
      expect(
        AppConstants.paidMaxCustomers,
        greaterThan(AppConstants.freeMaxCustomers),
      );
    });

    test('animation durations are ordered', () {
      expect(
        AppConstants.animFast.inMilliseconds,
        lessThan(AppConstants.animNormal.inMilliseconds),
      );
      expect(
        AppConstants.animNormal.inMilliseconds,
        lessThan(AppConstants.animSlow.inMilliseconds),
      );
    });

    test('query limits are positive', () {
      expect(AppConstants.queryLimitBills, greaterThan(0));
      expect(AppConstants.queryLimitProducts, greaterThan(0));
      expect(AppConstants.queryLimitCustomers, greaterThan(0));
      expect(AppConstants.queryLimitExpenses, greaterThan(0));
    });
  });

  // ── MockData ──

  group('MockData', () {
    test('sampleProducts returns non-empty list', () {
      final products = MockData.products;
      expect(products, isNotEmpty);
    });

    test('sampleProducts have valid prices', () {
      for (final product in MockData.products) {
        expect(product.price, greaterThan(0));
      }
    });

    test('sampleProducts have names', () {
      for (final product in MockData.products) {
        expect(product.name, isNotEmpty);
      }
    });

    test('sampleProducts have non-negative stock', () {
      for (final product in MockData.products) {
        expect(product.stock, greaterThanOrEqualTo(0));
      }
    });

    test('sampleProducts have valid product units', () {
      for (final product in MockData.products) {
        expect(ProductUnit.values, contains(product.unit));
      }
    });
  });
}
