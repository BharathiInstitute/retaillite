/// Barcode lookup service - fetches product info from Open Food Facts API
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Product info fetched from barcode lookup
class BarcodeProduct {
  final String barcode;
  final String name;
  final String? brand;
  final String? imageUrl;
  final double? mrp;
  final String? category;
  final String? quantity;

  const BarcodeProduct({
    required this.barcode,
    required this.name,
    this.brand,
    this.imageUrl,
    this.mrp,
    this.category,
    this.quantity,
  });

  /// Create from Open Food Facts API response
  factory BarcodeProduct.fromOpenFoodFacts(
    String barcode,
    Map<String, dynamic> json,
  ) {
    final product = json['product'] as Map<String, dynamic>?;
    if (product == null) {
      return BarcodeProduct(barcode: barcode, name: 'Unknown Product');
    }

    return BarcodeProduct(
      barcode: barcode,
      name:
          product['product_name'] as String? ??
          product['product_name_en'] as String? ??
          'Unknown Product',
      brand: product['brands'] as String?,
      imageUrl:
          product['image_front_small_url'] as String? ??
          product['image_url'] as String?,
      category: product['categories'] as String?,
      quantity: product['quantity'] as String?,
    );
  }

  /// Display name with brand
  String get displayName {
    if (brand != null && brand!.isNotEmpty) {
      return '$brand $name';
    }
    return name;
  }
}

/// Service to lookup products by barcode
class BarcodeLookupService {
  static const String _openFoodFactsBaseUrl =
      'https://world.openfoodfacts.org/api/v0/product';

  /// Lookup product by barcode using Open Food Facts API
  static Future<BarcodeProduct?> lookupBarcode(String barcode) async {
    try {
      debugPrint('🔍 Looking up barcode: $barcode');

      // Clean barcode
      final cleanBarcode = barcode.trim().replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanBarcode.isEmpty) return null;

      // Try Open Food Facts
      final result = await _lookupOpenFoodFacts(cleanBarcode);
      if (result != null) {
        debugPrint('✅ Found product: ${result.displayName}');
        return result;
      }

      debugPrint('❌ Product not found in database');
      return null;
    } catch (e) {
      debugPrint('❌ Barcode lookup error: $e');
      return null;
    }
  }

  /// Lookup using Open Food Facts API
  static Future<BarcodeProduct?> _lookupOpenFoodFacts(String barcode) async {
    try {
      final url = '$_openFoodFactsBaseUrl/$barcode.json';
      final response = await http
          .get(
            Uri.parse(url),
            headers: {'User-Agent': 'RetailLite/1.0 (contact@retaillite.com)'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final status = json['status'] as int?;

        if (status == 1) {
          return BarcodeProduct.fromOpenFoodFacts(barcode, json);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Open Food Facts error: $e');
      return null;
    }
  }

  /// Check if barcode is valid format
  static bool isValidBarcode(String barcode) {
    final cleaned = barcode.trim().replaceAll(RegExp(r'[^0-9]'), '');
    // EAN-8, EAN-13, UPC-A, UPC-E
    return cleaned.length >= 8 && cleaned.length <= 14;
  }
}
