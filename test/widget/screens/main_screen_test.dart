import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dating_app/models/chat_card.dart';
import 'package:dating_app/models/swipe_user.dart';
import 'package:dating_app/models/user.dart';
import 'package:dating_app/providers/auth_provider.dart';
import 'package:dating_app/providers/chat_provider.dart';
import 'package:dating_app/providers/language_provider.dart';
import 'package:dating_app/providers/notifications_provider.dart';
import 'package:dating_app/providers/onboarding_provider.dart';
import 'package:dating_app/providers/settings_provider.dart';
import 'package:dating_app/screens/main_screen.dart';

import '../../helpers/fixtures.dart' as fixtures;
import '../../helpers/mock_api.dart';
import '../../helpers/test_helpers.dart';

class _MainAuthProvider extends AuthProvider {
  @override
  User? get user => User.fromJson({
    ...fixtures.jsonUser(),
    'is_profile_complete': true,
  });

  @override
  bool get isAuthenticated => true;

  @override
  bool get isServerHealthy => true;

  @override
  Future<bool> initializeApp() async => true;
}

class _FakeChatProvider extends ChatProvider {
  @override
  List<ChatCard> get conversations => [];

  @override
  List<ChatCard> get pendingChats => [];

  @override
  List<ChatCard> get incomingChats => [];

  @override
  List<SwipeUser> get likedUsers => [];

  @override
  List<SwipeUser> get likers => [];

  @override
  bool get isLoading => false;

  @override
  bool get isLoadingMore => false;

  @override
  Future<void> loadConversations() async {}

  @override
  Future<void> loadPendingIncoming() async {}

  @override
  Future<void> refreshLimits() async {}

  @override
  Future<void> connectSessionSocket() async {}
}

class _FakeNotificationsProvider extends NotificationsProvider {
  @override
  bool get isLoading => false;

  @override
  Future<void> loadNotifications() async {}
}

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  Future<void> pumpMainScreen(WidgetTester tester) async {
    MockApi()
      ..onGet('/discover', body: {'profiles': []})
      ..onGet('/search', body: {'profiles': []})
      ..onGet('/rewards/my-limits', body: {'remaining_likes': 5})
      ..onGet('/interests', body: [])
      ..onGet('/users/me/photos', body: [
        fixtures.photoResponse().toJson(),
        fixtures.photoResponse().toJson(),
        fixtures.photoResponse().toJson(),
      ])
      ..install();

    await tester.pumpWidget(
      buildTestable(
        const MainScreen(),
        providers: [
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => _MainAuthProvider(),
          ),
          ChangeNotifierProvider(create: (_) => OnboardingProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider<ChatProvider>(
            create: (_) => _FakeChatProvider(),
          ),
          ChangeNotifierProvider<NotificationsProvider>(
            create: (_) => _FakeNotificationsProvider(),
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  group('MainScreen exit confirmation', () {
    testWidgets('system back shows the exit dialog instead of closing', (
      tester,
    ) async {
      await pumpMainScreen(tester);

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Exit Bondi?'), findsOneWidget);
      expect(find.text('Are you sure you want to close the app?'), findsOneWidget);
    });

    testWidgets('cancel dismisses the dialog and stays in the app', (
      tester,
    ) async {
      await pumpMainScreen(tester);

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Exit Bondi?'), findsNothing);
      expect(find.byType(MainScreen), findsOneWidget);
    });

    testWidgets('confirming exits the app via SystemNavigator.pop', (
      tester,
    ) async {
      final platformCalls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          platformCalls.add(call);
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      await pumpMainScreen(tester);

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('Exit'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        platformCalls.any((c) => c.method == 'SystemNavigator.pop'),
        isTrue,
      );
    });
  });
}
