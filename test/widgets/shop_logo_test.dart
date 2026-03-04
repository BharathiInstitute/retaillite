import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/shared/widgets/shop_logo_widget.dart';
import '../helpers/test_app.dart';

void main() {
  group('ShopLogoWidget', () {
    testWidgets('shows storefront icon when logoPath is null', (tester) async {
      await tester.pumpWidget(
        testApp(const ShopLogoWidget(logoPath: null)),
      );
      expect(find.byIcon(Icons.storefront), findsOneWidget);
    });

    testWidgets('shows storefront icon when logoPath is empty', (tester) async {
      await tester.pumpWidget(
        testApp(const ShopLogoWidget(logoPath: '')),
      );
      expect(find.byIcon(Icons.storefront), findsOneWidget);
    });

    testWidgets('respects custom size', (tester) async {
      await tester.pumpWidget(
        testApp(const ShopLogoWidget(logoPath: null, size: 64)),
      );
      final container = tester.widget<Container>(find.byType(Container).first);
      final constraints = container.constraints;
      expect(constraints?.maxWidth, 64);
      expect(constraints?.maxHeight, 64);
    });

    testWidgets('applies borderRadius', (tester) async {
      await tester.pumpWidget(
        testApp(const ShopLogoWidget(logoPath: null, borderRadius: 16)),
      );
      // Widget should render without error
      expect(find.byType(ShopLogoWidget), findsOneWidget);
    });

    testWidgets('renders without error for http URL', (tester) async {
      // CachedNetworkImage will show error widget since URL is fake,
      // which falls back to storefront icon
      await tester.pumpWidget(
        testApp(const ShopLogoWidget(logoPath: 'https://example.com/logo.png')),
      );
      await tester.pump();
      expect(find.byType(ShopLogoWidget), findsOneWidget);
    });

    testWidgets('default size is 36', (tester) async {
      await tester.pumpWidget(
        testApp(const ShopLogoWidget(logoPath: null)),
      );
      final container = tester.widget<Container>(find.byType(Container).first);
      final constraints = container.constraints;
      expect(constraints?.maxWidth, 36);
    });
  });
}
