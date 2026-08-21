import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/screens/splash_screen.dart';
import 'package:dating_app/screens/login_screen.dart';
import 'package:dating_app/providers/auth_provider.dart';
import 'package:dating_app/providers/onboarding_provider.dart';
import 'package:dating_app/providers/settings_provider.dart';
import 'package:dating_app/providers/language_provider.dart';
import 'package:dating_app/providers/chat_provider.dart';
import 'package:dating_app/providers/notifications_provider.dart';
import 'package:dating_app/screens/main_screen.dart';
import 'package:dating_app/models/user.dart';
import '../../../helpers/test_helpers.dart';
import '../../../helpers/mock_api.dart';

class FakeAuthProvider extends AuthProvider {
  final bool isAuthenticatedFlag;
  final bool isServerHealthyFlag;
  final User? userValue;

  FakeAuthProvider({
    bool isAuthenticated = false,
    bool isServerHealthy = true,
    this.userValue,
  })  : isAuthenticatedFlag = isAuthenticated,
        isServerHealthyFlag = isServerHealthy;

  @override
  User? get user => userValue;

  @override
  bool get isAuthenticated => isAuthenticatedFlag;

  @override
  bool get isServerHealthy => isServerHealthyFlag;

  @override
  Future<bool> initializeApp() async {
    return isAuthenticatedFlag;
  }
}

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  Widget buildSplash({bool isAuthenticated = false, bool isServerHealthy = true}) {
    return buildTestable(
      const SplashScreen(),
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => FakeAuthProvider(
            isAuthenticated: isAuthenticated,
            isServerHealthy: isServerHealthy,
          ),
        ),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
    );
  }

  group('SplashScreen', () {
    testWidgets('shows app title and subtitle', (tester) async {
      await tester.pumpWidget(buildSplash());

      expect(find.text('Bondi'), findsOneWidget);
      expect(find.text('Find Your Match'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();
    });

    testWidgets('server down -> shows server-error state with retry',
        (tester) async {
      await tester.pumpWidget(buildSplash(isServerHealthy: false));

      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pumpAndSettle();

      expect(find.text('Connection failed'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('unauthenticated -> navigates to LoginScreen',
        (tester) async {
      await tester.pumpWidget(buildSplash());

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
    });

    testWidgets('authenticated -> navigates to MainScreen', (tester) async {
      MockApi()
        ..onGet('/discover', body: {'profiles': []})
        ..onGet('/rewards/my-limits', body: {'remaining_likes': 5})
        ..onGet('/interests', body: [])
        ..onGet('/users/me/photos', body: [
          {'id': 'p1', 'status': 'approved'},
          {'id': 'p2', 'status': 'approved'},
          {'id': 'p3', 'status': 'approved'},
        ])
        ..onGet('/swipes/stats', body: {'likes_remaining_today': 5})
        ..onGet('/notifications/counts', body: {'unread': 0})
        ..install();

      await tester.pumpWidget(
        buildTestable(
          const SplashScreen(),
          providers: [
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => FakeAuthProvider(
                isAuthenticated: true,
                userValue: User.fromJson({
                  'id': 'test-user',
                  'created_at': '2024-01-01T00:00:00Z',
                  'is_profile_complete': true,
                }),
              ),
            ),
            ChangeNotifierProvider(create: (_) => OnboardingProvider()),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
            ChangeNotifierProvider(create: (_) => ChatProvider()),
            ChangeNotifierProvider(create: (_) => NotificationsProvider()),
          ],
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      await tester.pumpAndSettle();

      expect(find.byType(MainScreen), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
    });
  });
}