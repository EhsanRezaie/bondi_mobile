import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/widgets/matched_avatar_strip.dart';
import 'package:dating_app/models/match.dart';
import 'package:dating_app/providers/settings_provider.dart';
import '../../helpers/test_helpers.dart';
import '../../helpers/fixtures.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('MatchedAvatarStrip', () {
    testWidgets('shows nothing when matches list is empty', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          MatchedAvatarStrip(
            matches: [],
            onMatchTap: (_) {},
          ),
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      expect(find.byType(MatchedAvatarStrip), findsOneWidget);
    });

    testWidgets('filters to only match kind', (tester) async {
      final nonMatch = match(kind: 'like');
      final matchItem = match(kind: 'match');

      await tester.pumpWidget(
        buildTestable(
          MatchedAvatarStrip(
            matches: [nonMatch, matchItem],
            onMatchTap: (_) {},
          ),
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      expect(find.text(matchItem.user.name), findsOneWidget);
    });

    testWidgets('limits to 5 avatars max', (tester) async {
      final matches = List.generate(
        10,
        (i) => match(kind: 'match'),
      );

      await tester.pumpWidget(
        buildTestable(
          MatchedAvatarStrip(
            matches: matches,
            onMatchTap: (_) {},
          ),
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      final avatarCount = find.byType(CircleAvatar).evaluate().length;
      expect(avatarCount, lessThanOrEqualTo(5));
    });

    testWidgets('renders match user names', (tester) async {
      final matchItem = match(kind: 'match');

      await tester.pumpWidget(
        buildTestable(
          MatchedAvatarStrip(
            matches: [matchItem],
            onMatchTap: (_) {},
          ),
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      expect(find.text(matchItem.user.name), findsOneWidget);
    });
  });
}