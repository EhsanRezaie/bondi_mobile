import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/screens/login_screen.dart';
import 'package:dating_app/providers/auth_provider.dart';
import 'package:dating_app/providers/language_provider.dart';
import 'package:dating_app/providers/settings_provider.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('LoginScreen', () {
    testWidgets('renders phone field', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const LoginScreen(),
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders Send Code button', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const LoginScreen(),
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
        ),
      );

      expect(find.text('Send Code'), findsOneWidget);
    });

    testWidgets('shows error for empty phone on submit', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const LoginScreen(),
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
        ),
      );

      await tester.tap(find.text('Send Code'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your phone number'), findsOneWidget);
    });

    testWidgets('shows error for short phone number', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const LoginScreen(),
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
        ),
      );

      await tester.enterText(find.byType(TextField).first, '123');
      await tester.tap(find.text('Send Code'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid phone number'), findsOneWidget);
    });

    testWidgets('renders terms and privacy footer links', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const LoginScreen(),
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
        ),
      );

      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
    });

    testWidgets('language selector switches language to Persian', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const LoginScreen(),
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
        ),
      );

      await tester.tap(find.byTooltip('Select Language'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Persian'));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(LoginScreen));
      expect(
        Provider.of<LanguageProvider>(context, listen: false).currentLanguageCode,
        'fa',
      );
    });

    testWidgets('theme toggle switches dark mode', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const LoginScreen(),
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
        ),
      );

      final context = tester.element(find.byType(LoginScreen));
      final initialDark = Provider.of<SettingsProvider>(
        context,
        listen: false,
      ).darkMode;

      await tester.tap(find.byTooltip('Dark Mode'));
      await tester.pumpAndSettle();

      expect(
        Provider.of<SettingsProvider>(context, listen: false).darkMode,
        isNot(initialDark),
      );
    });
  });
}