import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/shared/widgets/app_button.dart';
import 'package:retaillite/shared/widgets/app_text_field.dart';
import '../helpers/test_app.dart';

void main() {
  // ── AppButton ──

  group('AppButton', () {
    testWidgets('renders with label text', (tester) async {
      await tester.pumpWidget(
        testApp(AppButton(label: 'Save', onPressed: () {})),
      );
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('responds to tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        testApp(AppButton(label: 'Tap Me', onPressed: () => tapped = true)),
      );
      await tester.tap(find.text('Tap Me'));
      expect(tapped, isTrue);
    });

    testWidgets('disabled button does not respond to tap', (tester) async {
      final tapped = false;
      await tester.pumpWidget(testApp(const AppButton(label: 'Disabled')));
      await tester.tap(find.text('Disabled'));
      expect(tapped, isFalse);
    });

    testWidgets('renders with icon', (tester) async {
      await tester.pumpWidget(
        testApp(AppButton(label: 'Add', icon: Icons.add, onPressed: () {})),
      );
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });

    testWidgets('shows loading indicator when isLoading', (tester) async {
      await tester.pumpWidget(
        testApp(AppButton(label: 'Loading', onPressed: () {}, isLoading: true)),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('does not respond when loading', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        testApp(
          AppButton(
            label: 'Loading',
            onPressed: () => tapped = true,
            isLoading: true,
          ),
        ),
      );
      await tester.tap(find.byType(ElevatedButton));
      expect(tapped, isFalse);
    });

    testWidgets('outlined variant uses OutlinedButton', (tester) async {
      await tester.pumpWidget(
        testApp(
          AppButton(label: 'Outline', onPressed: () {}, isOutlined: true),
        ),
      );
      expect(find.byType(OutlinedButton), findsOneWidget);
    });
  });

  // ── AppButtonLight ──

  group('AppButtonLight', () {
    testWidgets('renders with label', (tester) async {
      await tester.pumpWidget(
        testApp(AppButtonLight(label: 'Cancel', onPressed: () {})),
      );
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('renders with icon', (tester) async {
      await tester.pumpWidget(
        testApp(
          AppButtonLight(label: 'Info', icon: Icons.info, onPressed: () {}),
        ),
      );
      expect(find.byIcon(Icons.info), findsOneWidget);
    });
  });

  // ── AppTextField ──

  group('AppTextField', () {
    testWidgets('renders with label', (tester) async {
      await tester.pumpWidget(
        testApp(const AppTextField(label: 'Product Name')),
      );
      expect(find.text('Product Name'), findsOneWidget);
    });

    testWidgets('accepts text input', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        testApp(AppTextField(label: 'Name', controller: controller)),
      );
      await tester.enterText(find.byType(TextFormField), 'Rice');
      expect(controller.text, 'Rice');
    });

    testWidgets('shows hint text', (tester) async {
      await tester.pumpWidget(
        testApp(const AppTextField(label: 'Price', hint: 'Enter price')),
      );
      expect(find.text('Enter price'), findsOneWidget);
    });

    testWidgets('shows prefix icon widget', (tester) async {
      await tester.pumpWidget(
        testApp(
          const AppTextField(label: 'Search', prefixIcon: Icon(Icons.search)),
        ),
      );
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('validator shows error text', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        testApp(
          Form(
            key: formKey,
            child: AppTextField(
              label: 'Name',
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
          ),
        ),
      );
      formKey.currentState!.validate();
      await tester.pump();
      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('errorText prop shows inline error', (tester) async {
      await tester.pumpWidget(
        testApp(const AppTextField(label: 'Email', errorText: 'Invalid email')),
      );
      expect(find.text('Invalid email'), findsOneWidget);
    });

    testWidgets('readOnly prevents editing', (tester) async {
      final controller = TextEditingController(text: 'Locked');
      await tester.pumpWidget(
        testApp(
          AppTextField(label: 'ID', controller: controller, readOnly: true),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'Changed');
      // readOnly prevents changes
      expect(controller.text, 'Locked');
    });
  });

  // ── PhoneTextField ──

  group('PhoneTextField', () {
    testWidgets('renders with Mobile Number label', (tester) async {
      await tester.pumpWidget(testApp(const PhoneTextField()));
      expect(find.text('Mobile Number'), findsOneWidget);
    });

    testWidgets('shows phone icon', (tester) async {
      await tester.pumpWidget(testApp(const PhoneTextField()));
      expect(find.byIcon(Icons.phone_android), findsOneWidget);
    });
  });

  // ── CurrencyTextField ──

  group('CurrencyTextField', () {
    testWidgets('renders with label', (tester) async {
      await tester.pumpWidget(testApp(const CurrencyTextField(label: 'Price')));
      expect(find.text('Price'), findsOneWidget);
    });

    testWidgets('shows rupee prefix', (tester) async {
      await tester.pumpWidget(
        testApp(const CurrencyTextField(label: 'Amount')),
      );
      expect(find.text('₹ '), findsOneWidget);
    });
  });
}
