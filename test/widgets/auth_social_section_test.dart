import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/features/auth/widgets/auth_social_section.dart';
import '../helpers/test_app.dart';

void main() {
  group('AuthSocialSection', () {
    testWidgets('renders Google button text', (tester) async {
      await tester.pumpWidget(
        testApp(
          AuthSocialSection(
            isGoogleLoading: false,
            isOtherLoading: false,
            showEmailForm: false,
            emailButtonLabel: 'Sign in with Email',
            onGooglePressed: () {},
            onEmailToggle: () {},
          ),
        ),
      );
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('shows loading text when Google is loading', (tester) async {
      await tester.pumpWidget(
        testApp(
          AuthSocialSection(
            isGoogleLoading: true,
            isOtherLoading: false,
            showEmailForm: false,
            emailButtonLabel: 'Sign in with Email',
            onGooglePressed: () {},
            onEmailToggle: () {},
          ),
        ),
      );
      expect(find.text('Signing in...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows OR divider', (tester) async {
      await tester.pumpWidget(
        testApp(
          AuthSocialSection(
            isGoogleLoading: false,
            isOtherLoading: false,
            showEmailForm: false,
            emailButtonLabel: 'Sign in with Email',
            onGooglePressed: () {},
            onEmailToggle: () {},
          ),
        ),
      );
      expect(find.text('OR'), findsOneWidget);
    });

    testWidgets('shows email button when not showing email form', (tester) async {
      await tester.pumpWidget(
        testApp(
          AuthSocialSection(
            isGoogleLoading: false,
            isOtherLoading: false,
            showEmailForm: false,
            emailButtonLabel: 'Sign in with Email',
            onGooglePressed: () {},
            onEmailToggle: () {},
          ),
        ),
      );
      expect(find.text('Sign in with Email'), findsOneWidget);
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    });

    testWidgets('hides email button when showing email form', (tester) async {
      await tester.pumpWidget(
        testApp(
          AuthSocialSection(
            isGoogleLoading: false,
            isOtherLoading: false,
            showEmailForm: true,
            emailButtonLabel: 'Sign in with Email',
            onGooglePressed: () {},
            onEmailToggle: () {},
          ),
        ),
      );
      expect(find.text('Sign in with Email'), findsNothing);
    });

    testWidgets('onGooglePressed callback fires', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        testApp(
          AuthSocialSection(
            isGoogleLoading: false,
            isOtherLoading: false,
            showEmailForm: false,
            emailButtonLabel: 'Sign in with Email',
            onGooglePressed: () => pressed = true,
            onEmailToggle: () {},
          ),
        ),
      );
      await tester.tap(find.text('Continue with Google'));
      expect(pressed, isTrue);
    });

    testWidgets('onEmailToggle callback fires', (tester) async {
      var toggled = false;
      await tester.pumpWidget(
        testApp(
          AuthSocialSection(
            isGoogleLoading: false,
            isOtherLoading: false,
            showEmailForm: false,
            emailButtonLabel: 'Sign in with Email',
            onGooglePressed: () {},
            onEmailToggle: () => toggled = true,
          ),
        ),
      );
      await tester.tap(find.text('Sign in with Email'));
      expect(toggled, isTrue);
    });

    testWidgets('Google button disabled when other loading', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        testApp(
          AuthSocialSection(
            isGoogleLoading: false,
            isOtherLoading: true,
            showEmailForm: false,
            emailButtonLabel: 'Sign in with Email',
            onGooglePressed: () => pressed = true,
            onEmailToggle: () {},
          ),
        ),
      );
      await tester.tap(find.text('Continue with Google'));
      expect(pressed, isFalse);
    });
  });
}
