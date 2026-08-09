import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/screens/auth/sign_up_screen.dart';
import "package:dating_app/providers/auth_provider.dart";
import "package:dating_app/providers/language_provider.dart";
import 'package:dating_app/screens/login_screen.dart';
import '../../../helpers/test_helpers.dart';

class FakeOnboardingProvider extends ChangeNotifier {
  String _email = '';
  String _password = '';
  String get email => _email;
  String get password => _password;
  void setEmailAndPassword(String email, String password) {
    _email = email;
    _password = password;
    notifyListeners();
  }
}

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('SignUpScreen', () {
    testWidgets('shows validation errors for empty fields on submit', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestable(
          const SignUpScreen(),
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => FakeOnboardingProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
        ),
      );

      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(find.text('Please confirm your password'), findsOneWidget);
    });

    testWidgets('shows error for invalid email format', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const SignUpScreen(),
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => FakeOnboardingProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'not-an-email');
      await tester.pump();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('shows error for password shorter than 8 characters', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestable(
          const SignUpScreen(),
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => FakeOnboardingProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(1), 'short');
      await tester.pump();

      expect(
        find.text('Password must be at least 8 characters'),
        findsOneWidget,
      );
    });

    testWidgets('shows error when passwords do not match', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const SignUpScreen(),
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => FakeOnboardingProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.enterText(find.byType(TextFormField).at(2), 'different123');
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('back button navigates to LoginScreen', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const SignUpScreen(),
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => FakeOnboardingProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
        ),
      );

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
