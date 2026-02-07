/// Pre-built product catalog service
/// Provides ready-made product lists for quick setup
library;

import 'package:retaillite/models/product_model.dart';

/// Category of products
enum ProductCategory {
  kirana('Kirana Store', 'किराना स्टोर'),
  grocery('Grocery', 'किराना'),
  dairy('Dairy', 'डेयरी'),
  snacks('Snacks & Beverages', 'स्नैक्स'),
  personal('Personal Care', 'पर्सनल केयर'),
  cleaning('Cleaning', 'सफाई');

  final String name;
  final String hindiName;
  const ProductCategory(this.name, this.hindiName);
}

/// A catalog product template
class CatalogProduct {
  final String name;
  final double suggestedPrice;
  final ProductUnit unit;
  final ProductCategory category;
  final String? barcode;

  const CatalogProduct({
    required this.name,
    required this.suggestedPrice,
    this.unit = ProductUnit.piece,
    required this.category,
    this.barcode,
  });

  /// Convert to ProductModel (user can edit before saving)
  ProductModel toProductModel({double? customPrice, int stock = 0}) {
    return ProductModel(
      id: '',
      name: name,
      price: customPrice ?? suggestedPrice,
      stock: stock,
      unit: unit,
      barcode: barcode,
      lowStockAlert: 5,
      createdAt: DateTime.now(),
    );
  }
}

/// Service providing pre-built product catalogs
class ProductCatalogService {
  /// Get all categories
  static List<ProductCategory> get categories => ProductCategory.values;

  /// Get products by category
  static List<CatalogProduct> getProductsByCategory(ProductCategory category) {
    return _allProducts.where((p) => p.category == category).toList();
  }

  /// Get all products
  static List<CatalogProduct> get allProducts => _allProducts;

  /// Search products
  static List<CatalogProduct> searchProducts(String query) {
    final q = query.toLowerCase();
    return _allProducts.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  /// Pre-built product list (100+ common Indian retail items)
  static const List<CatalogProduct> _allProducts = [
    // ===== GROCERY / STAPLES =====
    CatalogProduct(
      name: 'Rice Basmati 1kg',
      suggestedPrice: 120,
      unit: ProductUnit.kg,
      category: ProductCategory.grocery,
    ),
    CatalogProduct(
      name: 'Rice Basmati 5kg',
      suggestedPrice: 550,
      unit: ProductUnit.kg,
      category: ProductCategory.grocery,
    ),
    CatalogProduct(
      name: 'Wheat Flour (Atta) 5kg',
      suggestedPrice: 280,
      unit: ProductUnit.kg,
      category: ProductCategory.grocery,
    ),
    CatalogProduct(
      name: 'Wheat Flour (Atta) 10kg',
      suggestedPrice: 520,
      unit: ProductUnit.kg,
      category: ProductCategory.grocery,
    ),
    CatalogProduct(
      name: 'Sugar 1kg',
      suggestedPrice: 48,
      unit: ProductUnit.kg,
      category: ProductCategory.grocery,
    ),
    CatalogProduct(
      name: 'Sugar 5kg',
      suggestedPrice: 230,
      unit: ProductUnit.kg,
      category: ProductCategory.grocery,
    ),
    CatalogProduct(
      name: 'Salt 1kg',
      suggestedPrice: 25,
      unit: ProductUnit.kg,
      category: ProductCategory.grocery,
    ),
    CatalogProduct(
      name: 'Tata Salt 1kg',
      suggestedPrice: 28,
      unit: ProductUnit.piece,
      category: ProductCategory.grocery,
      barcode: '8901725181116',
    ),
    CatalogProduct(
      name: 'Toor Dal 1kg',
      suggestedPrice: 140,
      unit: ProductUnit.kg,
      category: ProductCategory.grocery,
    ),
    CatalogProduct(
      name: 'Chana Dal 1kg',
      suggestedPrice: 90,
      unit: ProductUnit.kg,
      category: ProductCategory.grocery,
    ),
    CatalogProduct(
      name: 'Moong Dal 1kg',
      suggestedPrice: 130,
      unit: ProductUnit.kg,
      category: ProductCategory.grocery,
    ),
    CatalogProduct(
      name: 'Urad Dal 1kg',
      suggestedPrice: 120,
      unit: ProductUnit.kg,
      category: ProductCategory.grocery,
    ),
    CatalogProduct(
      name: 'Mustard Oil 1L',
      suggestedPrice: 180,
      unit: ProductUnit.liter,
      category: ProductCategory.grocery,
    ),
    CatalogProduct(
      name: 'Sunflower Oil 1L',
      suggestedPrice: 160,
      unit: ProductUnit.liter,
      category: ProductCategory.grocery,
    ),
    CatalogProduct(
      name: 'Fortune Refined Oil 1L',
      suggestedPrice: 175,
      unit: ProductUnit.liter,
      category: ProductCategory.grocery,
    ),
    CatalogProduct(
      name: 'Ghee 500g',
      suggestedPrice: 320,
      unit: ProductUnit.gram,
      category: ProductCategory.grocery,
    ),
    CatalogProduct(
      name: 'Amul Ghee 1L',
      suggestedPrice: 620,
      unit: ProductUnit.liter,
      category: ProductCategory.grocery,
    ),

    // ===== KIRANA / SPICES =====
    CatalogProduct(
      name: 'Red Chili Powder 100g',
      suggestedPrice: 35,
      unit: ProductUnit.gram,
      category: ProductCategory.kirana,
    ),
    CatalogProduct(
      name: 'Turmeric Powder 100g',
      suggestedPrice: 30,
      unit: ProductUnit.gram,
      category: ProductCategory.kirana,
    ),
    CatalogProduct(
      name: 'Coriander Powder 100g',
      suggestedPrice: 25,
      unit: ProductUnit.gram,
      category: ProductCategory.kirana,
    ),
    CatalogProduct(
      name: 'Cumin (Jeera) 100g',
      suggestedPrice: 45,
      unit: ProductUnit.gram,
      category: ProductCategory.kirana,
    ),
    CatalogProduct(
      name: 'Garam Masala 50g',
      suggestedPrice: 40,
      unit: ProductUnit.gram,
      category: ProductCategory.kirana,
    ),
    CatalogProduct(
      name: 'MDH Chana Masala',
      suggestedPrice: 55,
      unit: ProductUnit.piece,
      category: ProductCategory.kirana,
    ),
    CatalogProduct(
      name: 'Everest Meat Masala',
      suggestedPrice: 65,
      unit: ProductUnit.piece,
      category: ProductCategory.kirana,
    ),
    CatalogProduct(
      name: 'Mustard Seeds 100g',
      suggestedPrice: 20,
      unit: ProductUnit.gram,
      category: ProductCategory.kirana,
    ),
    CatalogProduct(
      name: 'Ajwain 50g',
      suggestedPrice: 25,
      unit: ProductUnit.gram,
      category: ProductCategory.kirana,
    ),
    CatalogProduct(
      name: 'Black Pepper 50g',
      suggestedPrice: 60,
      unit: ProductUnit.gram,
      category: ProductCategory.kirana,
    ),
    CatalogProduct(
      name: 'Besan 500g',
      suggestedPrice: 65,
      unit: ProductUnit.gram,
      category: ProductCategory.kirana,
    ),
    CatalogProduct(
      name: 'Maida 500g',
      suggestedPrice: 35,
      unit: ProductUnit.gram,
      category: ProductCategory.kirana,
    ),
    CatalogProduct(
      name: 'Sooji 500g',
      suggestedPrice: 40,
      unit: ProductUnit.gram,
      category: ProductCategory.kirana,
    ),
    CatalogProduct(
      name: 'Poha 500g',
      suggestedPrice: 35,
      unit: ProductUnit.gram,
      category: ProductCategory.kirana,
    ),

    // ===== DAIRY =====
    CatalogProduct(
      name: 'Amul Milk 500ml',
      suggestedPrice: 28,
      unit: ProductUnit.ml,
      category: ProductCategory.dairy,
    ),
    CatalogProduct(
      name: 'Amul Milk 1L',
      suggestedPrice: 54,
      unit: ProductUnit.liter,
      category: ProductCategory.dairy,
    ),
    CatalogProduct(
      name: 'Amul Butter 100g',
      suggestedPrice: 56,
      unit: ProductUnit.gram,
      category: ProductCategory.dairy,
    ),
    CatalogProduct(
      name: 'Amul Butter 500g',
      suggestedPrice: 270,
      unit: ProductUnit.gram,
      category: ProductCategory.dairy,
    ),
    CatalogProduct(
      name: 'Amul Cheese 200g',
      suggestedPrice: 125,
      unit: ProductUnit.gram,
      category: ProductCategory.dairy,
    ),
    CatalogProduct(
      name: 'Curd 400g',
      suggestedPrice: 40,
      unit: ProductUnit.gram,
      category: ProductCategory.dairy,
    ),
    CatalogProduct(
      name: 'Paneer 200g',
      suggestedPrice: 90,
      unit: ProductUnit.gram,
      category: ProductCategory.dairy,
    ),
    CatalogProduct(
      name: 'Cream 200ml',
      suggestedPrice: 55,
      unit: ProductUnit.ml,
      category: ProductCategory.dairy,
    ),

    // ===== SNACKS & BEVERAGES =====
    CatalogProduct(
      name: 'Parle-G Biscuit',
      suggestedPrice: 10,
      unit: ProductUnit.piece,
      category: ProductCategory.snacks,
      barcode: '8901725181000',
    ),
    CatalogProduct(
      name: 'Britannia Biscuit',
      suggestedPrice: 20,
      unit: ProductUnit.piece,
      category: ProductCategory.snacks,
    ),
    CatalogProduct(
      name: 'Lays Chips',
      suggestedPrice: 20,
      unit: ProductUnit.piece,
      category: ProductCategory.snacks,
    ),
    CatalogProduct(
      name: 'Kurkure',
      suggestedPrice: 20,
      unit: ProductUnit.piece,
      category: ProductCategory.snacks,
    ),
    CatalogProduct(
      name: 'Maggi 2-Min Noodles',
      suggestedPrice: 14,
      unit: ProductUnit.piece,
      category: ProductCategory.snacks,
      barcode: '8901058851113',
    ),
    CatalogProduct(
      name: 'Maggi 4-Pack',
      suggestedPrice: 52,
      unit: ProductUnit.pack,
      category: ProductCategory.snacks,
    ),
    CatalogProduct(
      name: 'Coca Cola 750ml',
      suggestedPrice: 40,
      unit: ProductUnit.ml,
      category: ProductCategory.snacks,
    ),
    CatalogProduct(
      name: 'Pepsi 750ml',
      suggestedPrice: 40,
      unit: ProductUnit.ml,
      category: ProductCategory.snacks,
    ),
    CatalogProduct(
      name: 'Thums Up 750ml',
      suggestedPrice: 40,
      unit: ProductUnit.ml,
      category: ProductCategory.snacks,
    ),
    CatalogProduct(
      name: 'Sprite 750ml',
      suggestedPrice: 40,
      unit: ProductUnit.ml,
      category: ProductCategory.snacks,
    ),
    CatalogProduct(
      name: 'Frooti 200ml',
      suggestedPrice: 15,
      unit: ProductUnit.ml,
      category: ProductCategory.snacks,
    ),
    CatalogProduct(
      name: 'Maaza 250ml',
      suggestedPrice: 20,
      unit: ProductUnit.ml,
      category: ProductCategory.snacks,
    ),
    CatalogProduct(
      name: 'Bisleri Water 1L',
      suggestedPrice: 20,
      unit: ProductUnit.liter,
      category: ProductCategory.snacks,
    ),
    CatalogProduct(
      name: 'Red Bull 250ml',
      suggestedPrice: 115,
      unit: ProductUnit.ml,
      category: ProductCategory.snacks,
    ),
    CatalogProduct(
      name: 'Tata Tea 250g',
      suggestedPrice: 100,
      unit: ProductUnit.gram,
      category: ProductCategory.snacks,
    ),
    CatalogProduct(
      name: 'Nescafe Coffee 50g',
      suggestedPrice: 160,
      unit: ProductUnit.gram,
      category: ProductCategory.snacks,
    ),
    CatalogProduct(
      name: 'Bru Coffee 50g',
      suggestedPrice: 140,
      unit: ProductUnit.gram,
      category: ProductCategory.snacks,
    ),

    // ===== PERSONAL CARE =====
    CatalogProduct(
      name: 'Colgate Toothpaste 100g',
      suggestedPrice: 55,
      unit: ProductUnit.gram,
      category: ProductCategory.personal,
    ),
    CatalogProduct(
      name: 'Pepsodent Toothpaste 100g',
      suggestedPrice: 48,
      unit: ProductUnit.gram,
      category: ProductCategory.personal,
    ),
    CatalogProduct(
      name: 'Oral-B Toothbrush',
      suggestedPrice: 30,
      unit: ProductUnit.piece,
      category: ProductCategory.personal,
    ),
    CatalogProduct(
      name: 'Lux Soap',
      suggestedPrice: 38,
      unit: ProductUnit.piece,
      category: ProductCategory.personal,
    ),
    CatalogProduct(
      name: 'Dove Soap',
      suggestedPrice: 55,
      unit: ProductUnit.piece,
      category: ProductCategory.personal,
    ),
    CatalogProduct(
      name: 'Dettol Soap',
      suggestedPrice: 40,
      unit: ProductUnit.piece,
      category: ProductCategory.personal,
    ),
    CatalogProduct(
      name: 'Lifebuoy Soap',
      suggestedPrice: 35,
      unit: ProductUnit.piece,
      category: ProductCategory.personal,
    ),
    CatalogProduct(
      name: 'Head & Shoulders 180ml',
      suggestedPrice: 190,
      unit: ProductUnit.ml,
      category: ProductCategory.personal,
    ),
    CatalogProduct(
      name: 'Clinic Plus 175ml',
      suggestedPrice: 110,
      unit: ProductUnit.ml,
      category: ProductCategory.personal,
    ),
    CatalogProduct(
      name: 'Pantene 180ml',
      suggestedPrice: 185,
      unit: ProductUnit.ml,
      category: ProductCategory.personal,
    ),
    CatalogProduct(
      name: 'Nivea Cream 60ml',
      suggestedPrice: 120,
      unit: ProductUnit.ml,
      category: ProductCategory.personal,
    ),
    CatalogProduct(
      name: 'Fair & Lovely 50g',
      suggestedPrice: 85,
      unit: ProductUnit.gram,
      category: ProductCategory.personal,
    ),
    CatalogProduct(
      name: 'Vaseline 100g',
      suggestedPrice: 95,
      unit: ProductUnit.gram,
      category: ProductCategory.personal,
    ),
    CatalogProduct(
      name: 'Coconut Oil 200ml',
      suggestedPrice: 90,
      unit: ProductUnit.ml,
      category: ProductCategory.personal,
    ),
    CatalogProduct(
      name: 'Parachute Coconut Oil 175ml',
      suggestedPrice: 105,
      unit: ProductUnit.ml,
      category: ProductCategory.personal,
    ),

    // ===== CLEANING =====
    CatalogProduct(
      name: 'Surf Excel 1kg',
      suggestedPrice: 180,
      unit: ProductUnit.kg,
      category: ProductCategory.cleaning,
    ),
    CatalogProduct(
      name: 'Tide 1kg',
      suggestedPrice: 160,
      unit: ProductUnit.kg,
      category: ProductCategory.cleaning,
    ),
    CatalogProduct(
      name: 'Rin Detergent Bar',
      suggestedPrice: 22,
      unit: ProductUnit.piece,
      category: ProductCategory.cleaning,
    ),
    CatalogProduct(
      name: 'Vim Dishwash Bar',
      suggestedPrice: 30,
      unit: ProductUnit.piece,
      category: ProductCategory.cleaning,
    ),
    CatalogProduct(
      name: 'Vim Liquid 500ml',
      suggestedPrice: 110,
      unit: ProductUnit.ml,
      category: ProductCategory.cleaning,
    ),
    CatalogProduct(
      name: 'Harpic 500ml',
      suggestedPrice: 95,
      unit: ProductUnit.ml,
      category: ProductCategory.cleaning,
    ),
    CatalogProduct(
      name: 'Lizol 500ml',
      suggestedPrice: 115,
      unit: ProductUnit.ml,
      category: ProductCategory.cleaning,
    ),
    CatalogProduct(
      name: 'Colin Glass Cleaner',
      suggestedPrice: 90,
      unit: ProductUnit.piece,
      category: ProductCategory.cleaning,
    ),
    CatalogProduct(
      name: 'Hit Spray',
      suggestedPrice: 180,
      unit: ProductUnit.piece,
      category: ProductCategory.cleaning,
    ),
    CatalogProduct(
      name: 'Good Knight Liquid',
      suggestedPrice: 70,
      unit: ProductUnit.piece,
      category: ProductCategory.cleaning,
    ),
    CatalogProduct(
      name: 'Mortein Coil',
      suggestedPrice: 48,
      unit: ProductUnit.piece,
      category: ProductCategory.cleaning,
    ),
  ];
}
