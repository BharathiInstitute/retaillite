import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/features/billing/providers/cart_provider.dart';
import 'package:retaillite/features/billing/widgets/cart_section.dart';
import 'package:retaillite/models/product_model.dart';

void main() {
  final sampleProducts = [
    ProductModel(
      id: '1',
      name: 'Rice 5kg',
      price: 450,
      stock: 100,
      unit: ProductUnit.kg,
      createdAt: DateTime(2026),
    ),
    ProductModel(
      id: '2',
      name: 'Salt 1kg',
      price: 28,
      stock: 50,
      createdAt: DateTime(2026),
    ),
  ];

  Widget buildCart({
    List<ProductModel> products = const [],
    bool showHeader = false,
    VoidCallback? onPay,
  }) {
    final notifier = CartNotifier();
    for (final product in products) {
      notifier.addProduct(product);
    }

    return ProviderScope(
      overrides: [
        cartProvider.overrideWith((_) => notifier),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 600,
            child: CartSection(
              onPay: onPay ?? () {},
              showHeader: showHeader,
            ),
          ),
        ),
      ),
    );
  }

  group('CartSection', () {
    testWidgets('hidden when cart is empty and showHeader is false',
        (tester) async {
      await tester.pumpWidget(buildCart());
      // SizedBox.shrink when empty + !showHeader
      expect(find.text('Cart is empty'), findsNothing);
    });

    testWidgets('shows empty state when cart is empty and showHeader is true',
        (tester) async {
      await tester.pumpWidget(buildCart(showHeader: true));
      expect(find.text('Cart is empty'), findsOneWidget);
      expect(find.text('Tap products to add'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
    });

    testWidgets('shows Cart header with showHeader', (tester) async {
      await tester.pumpWidget(buildCart(showHeader: true));
      expect(find.text('Cart'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
    });

    testWidgets('renders cart items', (tester) async {
      await tester.pumpWidget(buildCart(products: sampleProducts, showHeader: true));
      expect(find.text('Rice 5kg'), findsOneWidget);
      expect(find.text('Salt 1kg'), findsOneWidget);
    });

    testWidgets('shows Clear button when items exist', (tester) async {
      await tester.pumpWidget(buildCart(products: sampleProducts, showHeader: true));
      expect(find.text('Clear'), findsOneWidget);
    });

    testWidgets('shows item count in collapsed header', (tester) async {
      await tester.pumpWidget(buildCart(products: sampleProducts));
      // collapsed header shows "CART (N items)"
      expect(find.textContaining('CART'), findsOneWidget);
      expect(find.textContaining('items'), findsOneWidget);
    });

    testWidgets('shows PAY button with total', (tester) async {
      await tester.pumpWidget(buildCart(products: sampleProducts, showHeader: true));
      expect(find.textContaining('PAY'), findsOneWidget);
    });

    testWidgets('fires onPay callback', (tester) async {
      var called = false;
      await tester.pumpWidget(
          buildCart(products: sampleProducts, showHeader: true, onPay: () => called = true));
      final payButton = find.textContaining('PAY');
      expect(payButton, findsOneWidget);
      await tester.tap(payButton);
      expect(called, isTrue);
    });
  });
}
