import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/features/auth/widgets/auth_layout.dart';

void main() {
  group('AuthLayout', () {
    testWidgets('renders title text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthLayout(
            title: 'Welcome Back',
            child: Text('Form Content'),
          ),
        ),
      );
      expect(find.text('Welcome Back'), findsWidgets);
    });

    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthLayout(
            title: 'Login',
            child: Text('Login Form'),
          ),
        ),
      );
      expect(find.text('Login Form'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthLayout(
            title: 'Register',
            subtitle: 'Create your account',
            child: SizedBox(),
          ),
        ),
      );
      expect(find.text('Create your account'), findsWidgets);
    });

    testWidgets('shows back button when onBack provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AuthLayout(
            title: 'Setup',
            onBack: () {},
            child: const SizedBox(),
          ),
        ),
      );
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('onBack callback fires', (tester) async {
      var backed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: AuthLayout(
            title: 'Setup',
            onBack: () => backed = true,
            child: const SizedBox(),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.arrow_back));
      expect(backed, isTrue);
    });

    testWidgets('renders without crashing in admin mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthLayout(
            title: 'Admin Login',
            isAdminMode: true,
            child: Text('Admin'),
          ),
        ),
      );
      expect(find.text('Admin'), findsOneWidget);
    });
  });
}
