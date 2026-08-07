import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dating_app/widgets/chat_app_bar.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('ChatAppBar', () {
    testWidgets('renders user name', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const Scaffold(
            appBar: ChatAppBar(userName: 'Sara'),
          ),
        ),
      );

      expect(find.text('Sara'), findsOneWidget);
    });

    testWidgets('avatar tap fires onAvatarTap', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        buildTestable(
          Scaffold(
            appBar: ChatAppBar(
              userName: 'Sara',
              onAvatarTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CircleAvatar));
      expect(tapped, isTrue);
    });

    testWidgets('menu button fires onMenuPressed', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        buildTestable(
          Scaffold(
            appBar: ChatAppBar(
              userName: 'Sara',
              onMenuPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      expect(pressed, isTrue);
    });
  });
}