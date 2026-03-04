import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/features/billing/widgets/product_grid.dart';
import 'package:retaillite/models/product_model.dart';

void main() {
  final sampleProducts = [
    ProductModel(
      id: '1',
      name: 'Rice Basmati 5kg',
      price: 450,
      stock: 50,
      unit: ProductUnit.kg,
      createdAt: DateTime(2026),
    ),
    ProductModel(
      id: '2',
      name: 'Tata Salt 1kg',
      price: 28,
      stock: 100,
      createdAt: DateTime(2026),
    ),
  ];

  group('ProductGrid', () {
    testWidgets('renders widget without crashing', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductGrid(
              products: sampleProducts,
              onProductTap: (_) {},
              isSliver: false,
            ),
          ),
        ),
      );
      expect(find.byType(ProductGrid), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('shows empty state when no products', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductGrid(
              products: const [],
              onProductTap: (_) {},
              isSliver: false,
            ),
          ),
        ),
      );
      expect(find.byType(GridView), findsNothing);
    });
  });
}
