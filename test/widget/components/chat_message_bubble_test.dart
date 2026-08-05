import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/widgets/chat_message_bubble.dart';
import 'package:dating_app/models/message.dart';
import 'package:dating_app/providers/settings_provider.dart';
import '../../helpers/test_helpers.dart';
import '../../helpers/fixtures.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('ChatMessageBubble', () {
    testWidgets('renders text message content', (tester) async {
      final msg = message();

      await tester.pumpWidget(
        buildTestable(
          ChatMessageBubble(message: msg, isMine: false),
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('renders photo message with mediaUrl', (tester) async {
      final msg = message(type: MessageType.photo);

      await tester.pumpWidget(
        buildTestable(
          ChatMessageBubble(message: msg, isMine: false),
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('renders voice message with duration', (tester) async {
      final msg = message(type: MessageType.voice);

      await tester.pumpWidget(
        buildTestable(
          ChatMessageBubble(message: msg, isMine: false),
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      expect(find.text('12s'), findsOneWidget);
    });

    testWidgets('mine-aligned right, other-aligned left', (tester) async {
      final msg = message();

      await tester.pumpWidget(
        buildTestable(
          Column(
            children: [
              ChatMessageBubble(message: msg, isMine: true),
              ChatMessageBubble(message: msg, isMine: false),
            ],
          ),
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      expect(find.byType(ChatMessageBubble), findsNWidgets(2));
    });

    testWidgets('renders edited marker when isEdited is true', (tester) async {
      final editedMsg = Message.fromJson(
        jsonMessage(
          messageType: 'text',
          content: 'Hello',
          isEdited: true,
        ),
      );

      await tester.pumpWidget(
        buildTestable(
          ChatMessageBubble(message: editedMsg, isMine: false),
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      expect(find.text('edited'), findsOneWidget);
    });
  });
}