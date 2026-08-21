// Lint: intentionally builds screens at multiple sizes to catch overflow.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nested/nested.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/screens/login_screen.dart';
import 'package:dating_app/screens/discover/discover_screen.dart';
import 'package:dating_app/screens/discover/profile_detail_screen.dart';
import 'package:dating_app/models/photo.dart';
import 'package:dating_app/screens/search/search_screen.dart';
import 'package:dating_app/screens/search/search_profile_detail.dart';
import 'package:dating_app/screens/profile/profile_screen.dart';
import 'package:dating_app/providers/auth_provider.dart';
import 'package:dating_app/providers/language_provider.dart';
import 'package:dating_app/providers/settings_provider.dart';
import 'package:dating_app/providers/discover_provider.dart';
import 'package:dating_app/providers/search_provider.dart';
import 'package:dating_app/providers/notifications_provider.dart';
import 'package:dating_app/providers/profile_provider.dart';
import 'package:dating_app/models/discover_profile.dart';
import 'package:dating_app/models/user.dart';
import '../helpers/test_helpers.dart';
import '../helpers/fixtures.dart' as fixtures;

/// Widths covering phones through large tablets (5" -> 14").
const kWidths = [360.0, 428.0, 600.0, 800.0, 1024.0, 1280.0];

class _FakeDiscoverProvider extends DiscoverProvider {
  @override
  List<DiscoverProfile> get profiles => <DiscoverProfile>[fixtures.discoverProfile()];

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  Future<void> loadProfiles() async {}
}

class _FakeProfileProvider extends ProfileProvider {
  @override
  List<PhotoResponse> get photos => const [];

  @override
  bool get isLoading => false;

  @override
  Future<void> loadPhotos() async {}

  @override
  Future<void> loadStats() async {}

  @override
  Future<void> refreshData() async {}
}

class _FakeAuthProvider extends AuthProvider {
  @override
  User? get user => fixtures.user();

  @override
  bool get isLoading => false;

  @override
  bool get isAuthenticated => true;
}

Future<void> _pumpAt(
  WidgetTester tester,
  double width,
  Widget child,
  List<SingleChildWidget> providers,
) async {
  tester.view.physicalSize = Size(width * 3, 800 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    buildTestable(child, providers: providers),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(seconds: 2));

  final exception = tester.takeException();
  expect(exception, isNull,
      reason: 'overflow/exception at width $width');
}

void main() {
  setUpAll(() => initTestEnvironment());

  group('responsive layout', () {
    for (final width in kWidths) {
      testWidgets('login no overflow @$width', (tester) async {
        await _pumpAt(
          tester,
          width,
          const LoginScreen(),
          [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
        );
      });

      testWidgets('discover no overflow @$width', (tester) async {
        await _pumpAt(
          tester,
          width,
          const DiscoverScreen(),
          [
            ChangeNotifierProvider<DiscoverProvider>(
              create: (_) => _FakeDiscoverProvider(),
            ),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        );
      });

      testWidgets('profile no overflow @$width', (tester) async {
        await _pumpAt(
          tester,
          width,
          const ProfileScreen(),
          [
            ChangeNotifierProvider<ProfileProvider>(
              create: (_) => _FakeProfileProvider(),
            ),
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => _FakeAuthProvider(),
            ),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        );
      });

      testWidgets('search no overflow @$width', (tester) async {
        await _pumpAt(
          tester,
          width,
          const SearchScreen(),
          [
            ChangeNotifierProvider(create: (_) => SearchProvider()),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => NotificationsProvider()),
          ],
        );
      });

      testWidgets('discover profile detail no overflow @$width',
          (tester) async {
        await _pumpAt(
          tester,
          width,
          ProfileDetailScreen(profile: fixtures.discoverProfile()),
          [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        );
      });

      testWidgets('search profile detail no overflow @$width', (tester) async {
        await _pumpAt(
          tester,
          width,
          SearchProfileDetail(profile: fixtures.discoverProfile(), interestIcons: {}),
          [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        );
      });
    }
  });
}