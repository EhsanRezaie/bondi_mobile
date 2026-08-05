import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:dating_app/widgets/online_indicator.dart';
import 'package:dating_app/providers/settings_provider.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('OnlineIndicator golden', () {
    testGoldens('renders online indicator', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const OnlineIndicator(isOnline: true),
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      await expectLater(
        find.byType(OnlineIndicator),
        matchesGoldenFile('online_indicator.png'),
      );
    });

    testGoldens('renders last seen indicator', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const OnlineIndicator(
            isOnline: false,
            lastSeenAt: '2026-08-05T10:00:00Z',
          ),
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      await expectLater(
        find.byType(OnlineIndicator),
        matchesGoldenFile('last_seen_indicator.png'),
      );
    });
  });
}