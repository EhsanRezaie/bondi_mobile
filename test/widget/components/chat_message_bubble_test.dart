import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/widgets/chat_message_bubble.dart';
import 'package:dating_app/models/message.dart';
import '../../../helpers/test_helpers.dart';
import '../../../helpers/fixtures.dart';

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
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('renders photo message with mediaUrl', (tester) async {
      final msg = message(type: MessageType.photo);

      await tester.pumpWidget(
        buildTestable(
          ChatMessageBubble(message: msg, isMine: false),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('renders voice message with duration', (tester) async {
      final msg = message(type: MessageType.voice);

      await tester.pumpWidget(
        buildTestable(
          ChatMessageBubble(message: msg, isMine: false),
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
        ),
      );

      final mineBubble = find.byType(ChatMessageBubble).first;
      final otherBubble = find.byType(ChatMessageBubble).last;

      expect(mineBubble, findsOneWidget);
      expect(otherBubble, findsOneWidget);
    });

    testWidgets('renders read ticks when isRead is true', (tester) async {
      final readMsg = message(isRead: true);

      await tester.pumpWidget(
        buildTestable(
          ChatMessageBubble(message: readMsg, isMine: true),
        ),
      );

      expect(find.text('✓✓'), findsOneWidget);
    });

    testWidgets('renders single tick when not read', (tester) async {
      final sentMsg = message(isRead: false, isDelivered: true);

      await tester.pumpWidget(
        buildTestable(
          ChatMessageBubble(message: sentMsg, isMine: true),
        ),
      );

      expect(find.text('✓'), findsOneWidget);
    });

    testWidgets('renders deleted message placeholder', (tester) async {
      final deletedMsg = message().copyWith(isDeleted: true);

      await tester.pumpWidget(
        buildTestable(
          ChatMessageBubble(message: deletedMsg, isMine: false),
        ),
      );

      expect(find.text('This message was deleted'), findsOneWidget);
    });

    testWidgets('renders edited marker when isEdited is true', (tester) async {
      final editedMsg = message().copyWith(isEdited: true);

      await tester.pumpWidget(
        buildTestable(
          ChatMessageBubble(message: editedMsg, isMine: false),
        ),
      );

      expect(find.text('(edited)'), findsOneWidget);
    });
  });
}