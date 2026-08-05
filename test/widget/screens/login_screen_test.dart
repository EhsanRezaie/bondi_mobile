import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/screens/login_screen.dart';
import 'package:dating_app/providers/settings_provider.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('LoginScreen', () {
    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const LoginScreen(),
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      expect(find.byType(TextField), findsAtLeast(1));
    });

    testWidgets('renders Login button', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const LoginScreen(),
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('renders Sign Up link', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const LoginScreen(),
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      expect(find.text('Sign Up'), findsOneWidget);
    });
  });
}