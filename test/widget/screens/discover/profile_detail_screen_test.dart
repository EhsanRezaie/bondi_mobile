import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/screens/discover/profile_detail_screen.dart';
import 'package:dating_app/models/discover_profile.dart';
import 'package:dating_app/providers/settings_provider.dart';
import '../../../helpers/test_helpers.dart';
import '../../../helpers/fixtures.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('ProfileDetailScreen', () {
    testWidgets('renders profile name in header', (tester) async {
      final profile = discoverProfile();

      await tester.pumpWidget(
        buildTestable(
          ProfileDetailScreen(
            profile: profile,
          ),
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Sara'), findsOneWidget);
    });

    testWidgets('renders bio section when bio is present', (tester) async {
      final profile = DiscoverProfile.fromJson({
        ...jsonDiscoverProfile(),
        'bio': 'Hello there!',
      });

      await tester.pumpWidget(
        buildTestable(
          ProfileDetailScreen(
            profile: profile,
          ),
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      expect(find.text('Hello there!'), findsOneWidget);
    });

    testWidgets('renders physical stats section', (tester) async {
      final profile = DiscoverProfile.fromJson({
        ...jsonDiscoverProfile(),
        'height': 175,
        'weight': 70,
        'body_type': 'Athletic',
      });

      await tester.pumpWidget(
        buildTestable(
          ProfileDetailScreen(
            profile: profile,
          ),
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      expect(find.text('Physical'), findsOneWidget);
    });

    testWidgets('renders bottom action bar with swipe buttons', (tester) async {
      final profile = discoverProfile();

      await tester.pumpWidget(
        buildTestable(
          ProfileDetailScreen(
            profile: profile,
          ),
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    });
  });
}