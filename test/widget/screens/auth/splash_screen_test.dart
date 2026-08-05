import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/screens/splash_screen.dart';
import 'package:dating_app/screens/login_screen.dart';
import 'package:dating_app/screens/main_screen.dart';
import 'package:dating_app/providers/auth_provider.dart';
import 'package:dating_app/providers/settings_provider.dart';
import 'package:dating_app/providers/language_provider.dart';
import '../../../helpers/test_helpers.dart';

class FakeAuthProvider extends AuthProvider {
  final bool _isAuthenticated;
  final bool _isServerHealthy;

  FakeAuthProvider({
    bool isAuthenticated = false,
    bool isServerHealthy = true,
  })  : _isAuthenticated = isAuthenticated,
        _isServerHealthy = isServerHealthy;

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  bool get isServerHealthy => _isServerHealthy;

  @override
  Future<bool> initializeApp() async {
    return _isAuthenticated;
  }
}

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('SplashScreen', () {
    testWidgets('shows loading state with progress bar', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const SplashScreen(),
          providers: [
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => FakeAuthProvider(isAuthenticated: false),
            ),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
        ),
      );

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows app title and subtitle', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const SplashScreen(),
          providers: [
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => FakeAuthProvider(isAuthenticated: false),
            ),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
        ),
      );

      expect(find.text('Bondi'), findsOneWidget);
    });

    testWidgets('server down -> shows server-error state with retry',
        (tester) async {
      fakeAsync((async) async {
        await tester.pumpWidget(
          buildTestable(
            const SplashScreen(),
            providers: [
              ChangeNotifierProvider<AuthProvider>(
                create: (_) => FakeAuthProvider(isServerHealthy: false),
              ),
              ChangeNotifierProvider(create: (_) => SettingsProvider()),
              ChangeNotifierProvider(create: (_) => LanguageProvider()),
            ],
          ),
        );

        async.elapse(const Duration(milliseconds: 800));
        await tester.pump();

        await tester.pump();

        expect(find.text('Connection failed'), findsOneWidget);
        expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      });
    });

    testWidgets('authenticated -> navigates to MainScreen',
        (tester) async {
      fakeAsync((async) async {
        await tester.pumpWidget(
          buildTestable(
            const SplashScreen(),
            providers: [
              ChangeNotifierProvider<AuthProvider>(
                create: (_) => FakeAuthProvider(isAuthenticated: true),
              ),
              ChangeNotifierProvider(create: (_) => SettingsProvider()),
              ChangeNotifierProvider(create: (_) => LanguageProvider()),
            ],
          ),
        );

        async.elapse(const Duration(milliseconds: 800));
        await tester.pump();

        await tester.pump();

        expect(find.byType(MainScreen), findsOneWidget);
        expect(find.byType(SplashScreen), findsNothing);
      });
    });

    testWidgets('unauthenticated -> navigates to LoginScreen',
        (tester) async {
      fakeAsync((async) async {
        await tester.pumpWidget(
          buildTestable(
            const SplashScreen(),
            providers: [
              ChangeNotifierProvider<AuthProvider>(
                create: (_) => FakeAuthProvider(isAuthenticated: false),
              ),
              ChangeNotifierProvider(create: (_) => SettingsProvider()),
              ChangeNotifierProvider(create: (_) => LanguageProvider()),
            ],
          ),
        );

        async.elapse(const Duration(milliseconds: 800));
        await tester.pump();

        await tester.pump();

        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(SplashScreen), findsNothing);
      });
    });
  });
}