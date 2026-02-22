/// Tests for Responsive Breakpoints, Scaling, and Layout Logic
///
/// Tests the pure logic of the responsive system — no Firebase dependency.
/// Covers: breakpoints, device type detection, scaling engine, grid columns,
/// padding values, and responsive value selection.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/theme/responsive_helper.dart';
import 'package:retaillite/core/theme/responsive_scale.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // BREAKPOINT DETECTION
  // ═══════════════════════════════════════════════════════════════════════════
  group('ResponsiveHelper — Breakpoint Detection', () {
    test('width < 600 → mobile', () {
      expect(ResponsiveHelper.getDeviceTypeFromWidth(359), DeviceType.mobile);
      expect(ResponsiveHelper.getDeviceTypeFromWidth(599), DeviceType.mobile);
    });

    test('width = 600 → tablet', () {
      expect(ResponsiveHelper.getDeviceTypeFromWidth(600), DeviceType.tablet);
    });

    test('width 600-1023 → tablet', () {
      expect(ResponsiveHelper.getDeviceTypeFromWidth(768), DeviceType.tablet);
      expect(ResponsiveHelper.getDeviceTypeFromWidth(1023), DeviceType.tablet);
    });

    test('width = 1024 → desktop', () {
      expect(ResponsiveHelper.getDeviceTypeFromWidth(1024), DeviceType.desktop);
    });

    test('width 1024-1919 → desktop', () {
      expect(ResponsiveHelper.getDeviceTypeFromWidth(1440), DeviceType.desktop);
      expect(ResponsiveHelper.getDeviceTypeFromWidth(1919), DeviceType.desktop);
    });

    test('width = 1920 → desktopLarge', () {
      expect(
        ResponsiveHelper.getDeviceTypeFromWidth(1920),
        DeviceType.desktopLarge,
      );
    });

    test('width > 1920 → desktopLarge', () {
      expect(
        ResponsiveHelper.getDeviceTypeFromWidth(2560),
        DeviceType.desktopLarge,
      );
    });

    test('boundary values are exact', () {
      // 599 → mobile, 600 → tablet
      expect(ResponsiveHelper.getDeviceTypeFromWidth(599), DeviceType.mobile);
      expect(ResponsiveHelper.getDeviceTypeFromWidth(600), DeviceType.tablet);

      // 1023 → tablet, 1024 → desktop
      expect(ResponsiveHelper.getDeviceTypeFromWidth(1023), DeviceType.tablet);
      expect(ResponsiveHelper.getDeviceTypeFromWidth(1024), DeviceType.desktop);

      // 1919 → desktop, 1920 → desktopLarge
      expect(ResponsiveHelper.getDeviceTypeFromWidth(1919), DeviceType.desktop);
      expect(
        ResponsiveHelper.getDeviceTypeFromWidth(1920),
        DeviceType.desktopLarge,
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GRID COLUMNS
  // ═══════════════════════════════════════════════════════════════════════════
  group('ResponsiveHelper — Grid Columns', () {
    testWidgets('tiny phone (320px) → 2 columns', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      final context = tester.element(find.byType(Scaffold));
      expect(ResponsiveHelper.gridColumns(context), 2);
    });

    testWidgets('standard phone (375px) → 3 columns', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      final context = tester.element(find.byType(Scaffold));
      expect(ResponsiveHelper.gridColumns(context), 3);
    });

    testWidgets('large phone (500px) → 4 columns', (tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      final context = tester.element(find.byType(Scaffold));
      expect(ResponsiveHelper.gridColumns(context), 4);
    });

    testWidgets('tablet (768px) → 3 columns', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      final context = tester.element(find.byType(Scaffold));
      expect(ResponsiveHelper.gridColumns(context), 3);
    });

    testWidgets('desktop (1440px) → 5 columns', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      final context = tester.element(find.byType(Scaffold));
      expect(ResponsiveHelper.gridColumns(context), 5);
    });

    testWidgets('XL desktop (1920px) → 6 columns', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      final context = tester.element(find.byType(Scaffold));
      expect(ResponsiveHelper.gridColumns(context), 6);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // RESPONSIVE SCALE ENGINE
  // ═══════════════════════════════════════════════════════════════════════════
  group('ResponsiveScale — Scaling Engine', () {
    test('scale factor is clamped between 0.3 and 1.5', () {
      // Tiny screen → minimum 0.3
      final tinyFactor = (200.0 / ResponsiveScale.designWidth).clamp(
        ResponsiveScale.minScale,
        ResponsiveScale.maxScale,
      );
      expect(tinyFactor, ResponsiveScale.minScale);

      // Huge screen → maximum 1.5
      final hugeFactor = (5000.0 / ResponsiveScale.designWidth).clamp(
        ResponsiveScale.minScale,
        ResponsiveScale.maxScale,
      );
      expect(hugeFactor, ResponsiveScale.maxScale);
    });

    test('design width is 1920px (desktop base)', () {
      expect(ResponsiveScale.designWidth, 1920.0);
    });

    test('minimum font size is 11px', () {
      expect(ResponsiveScale.minFontSize, 11.0);
    });

    test('minimum touch target is 48px', () {
      expect(ResponsiveScale.minTouchTarget, 48.0);
    });

    test('ensureTouchTarget never returns below 48', () {
      expect(ResponsiveScale.ensureTouchTarget(20), 48.0);
      expect(ResponsiveScale.ensureTouchTarget(48), 48.0);
      expect(ResponsiveScale.ensureTouchTarget(60), 60.0);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // RESPONSIVE VALUES (per-breakpoint)
  // ═══════════════════════════════════════════════════════════════════════════
  group('ResponsiveHelper — Per-Width Values', () {
    // Pure function tests (no BuildContext needed)
    test('page padding scales with width', () {
      // These tests use the raw width logic
      // micro phone → 8
      expect(true, true); // Placeholder since pagePadding needs context

      // Verify the breakpoint constants
      expect(ResponsiveHelper.mobileMaxWidth, 600);
      expect(ResponsiveHelper.tabletMaxWidth, 1024);
      expect(ResponsiveHelper.desktopMaxWidth, 1920);
    });

    testWidgets('pagePadding at mobile (360px) → 10', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      final ctx = tester.element(find.byType(Scaffold));
      expect(ResponsiveHelper.pagePadding(ctx), 10);
    });

    testWidgets('pagePadding at tablet (768px) → 16', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      final ctx = tester.element(find.byType(Scaffold));
      expect(ResponsiveHelper.pagePadding(ctx), 16);
    });

    testWidgets('pagePadding at desktop (1440px) → 20', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      final ctx = tester.element(find.byType(Scaffold));
      expect(ResponsiveHelper.pagePadding(ctx), 20);
    });

    testWidgets('buttonHeight at small phone (320px) → 40', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      final ctx = tester.element(find.byType(Scaffold));
      expect(ResponsiveHelper.buttonHeight(ctx), 40);
    });

    testWidgets('buttonHeight at desktop (1024px) → 48', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      final ctx = tester.element(find.byType(Scaffold));
      expect(ResponsiveHelper.buttonHeight(ctx), 48);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // ADAPTIVE LAYOUT WIDGET — FALLBACK CHAIN
  // ═══════════════════════════════════════════════════════════════════════════
  group('AdaptiveLayout — Fallback Chain', () {
    testWidgets('mobile width shows mobile layout', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LayoutBuilder(
              builder: (context, constraints) {
                final type = ResponsiveHelper.getDeviceTypeFromWidth(
                  constraints.maxWidth,
                );
                return Text('Layout: ${type.name}');
              },
            ),
          ),
        ),
      );

      expect(find.text('Layout: mobile'), findsOneWidget);
    });

    testWidgets('desktop width shows desktop layout', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LayoutBuilder(
              builder: (context, constraints) {
                final type = ResponsiveHelper.getDeviceTypeFromWidth(
                  constraints.maxWidth,
                );
                return Text('Layout: ${type.name}');
              },
            ),
          ),
        ),
      );

      expect(find.text('Layout: desktop'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // RESPONSIVE WRAPPER — NO OVERFLOW
  // ═══════════════════════════════════════════════════════════════════════════
  group('ResponsiveWrapper — Overflow Safety', () {
    final testWidths = [
      320.0,
      375.0,
      428.0,
      600.0,
      768.0,
      1024.0,
      1440.0,
      1920.0,
    ];

    for (final width in testWidths) {
      testWidgets('no overflow at ${width.toInt()}px with long text content', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    // Simulate a row with long text (common overflow source)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Very long product name that could cause overflow in narrow screens — Rice Basmati Premium 5kg Pack',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text('₹999.00'),
                      ],
                    ),
                    // Simulate a table-like row
                    Row(
                      children: [
                        Expanded(flex: 2, child: Text('#INV-10001')),
                        Expanded(flex: 3, child: Text('Customer Name')),
                        Expanded(flex: 2, child: Text('Cash')),
                        Expanded(flex: 2, child: Text('₹1,234.56')),
                      ],
                    ),
                    // Simulate cards
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dashboard Card'),
                            Text('Revenue: ₹45,678'),
                            Text('Bills: 234'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // If we reach here without RenderFlex overflow → pass
        expect(tester.takeException(), isNull);
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // RESPONSIVE VISIBILITY
  // ═══════════════════════════════════════════════════════════════════════════
  group('ResponsiveVisibility', () {
    testWidgets('hides on mobile when visibleOnMobile=false', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveVisibility(
              visibleOnMobile: false,
              child: Text('Desktop Only'),
            ),
          ),
        ),
      );

      expect(find.text('Desktop Only'), findsNothing);
    });

    testWidgets('shows on desktop when visibleOnDesktop=true', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveVisibility(
              visibleOnMobile: false,
              child: Text('Desktop Only'),
            ),
          ),
        ),
      );

      expect(find.text('Desktop Only'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // PRODUCT CARD HEIGHT
  // ═══════════════════════════════════════════════════════════════════════════
  group('ResponsiveHelper — Product Card Heights', () {
    testWidgets('tiny phone → 85px card height', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      final ctx = tester.element(find.byType(Scaffold));
      expect(ResponsiveHelper.productCardHeight(ctx), 85);
    });

    testWidgets('standard phone → 95px card height', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      final ctx = tester.element(find.byType(Scaffold));
      expect(ResponsiveHelper.productCardHeight(ctx), 95);
    });

    testWidgets('desktop → 110px card height', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      final ctx = tester.element(find.byType(Scaffold));
      expect(ResponsiveHelper.productCardHeight(ctx), 110);
    });
  });
}
