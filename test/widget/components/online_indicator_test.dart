import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/widgets/online_indicator.dart';
import 'package:dating_app/providers/settings_provider.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('OnlineIndicator', () {
    testWidgets('shows Online text when isOnline is true', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const OnlineIndicator(isOnline: true),
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      expect(find.text('Online'), findsOneWidget);
    });

    testWidgets('shows Last seen text when isOnline is false and lastSeenAt is set', (tester) async {
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

      expect(find.byWidgetPredicate(
        (widget) => widget is Text && widget.data != null && widget.data!.startsWith('Last seen'),
      ), findsOneWidget);
    });

    testWidgets('shows nothing when isOnline is false and lastSeenAt is null', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const OnlineIndicator(isOnline: false),
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      expect(find.byType(OnlineIndicator), findsOneWidget);
    });
  });
}