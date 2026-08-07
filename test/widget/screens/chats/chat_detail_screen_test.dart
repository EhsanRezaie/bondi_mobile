import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/providers/chat_provider.dart';
import 'package:dating_app/screens/chats/chat_detail_screen.dart';
import 'package:dating_app/widgets/chat_message_bubble.dart';
import 'package:dating_app/widgets/chat_input_bar.dart';
import '../../../helpers/test_helpers.dart';
import '../../../helpers/mock_api.dart';
import '../../../helpers/fixtures.dart';

void main() {
setUpAll(() async {
    await initTestEnvironment(secrets: {'user_id': 'user-a'});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') return {'text': 'Hello'};
      if (call.method == 'Clipboard.setData') return null;
      return null;
    });
  });

  late ChatProvider provider;
  late MockApi api;

  setUp(() {
    provider = ChatProvider();
    api = MockApi();
  });

  tearDown(() {
    provider.dispose();
  });

  Map<String, dynamic> detailJson({
    bool isEnded = false,
    bool isBlocked = false,
  }) {
    return {
      'id': 'chat-1',
      'status': 'accepted',
      'initiator_id': 'user-a',
      'user': {'id': 'user-b', 'name': 'Bob'},
      'is_blocked': isBlocked,
      'is_ended': isEnded,
    };
  }

  Future<void> pumpChat(WidgetTester tester, {String senderId = 'user-a'}) async {
    api.onGet('/chats/chat-1', body: detailJson());
    api.onGet('/messages/chat-1', body: {
      'items': [jsonMessage(id: 'msg-1', senderId: senderId)],
    });
    api.install();

    await tester.pumpWidget(
      buildTestable(
        ChatDetailScreen(
          identifier: 'chat-1',
          userName: 'Bob',
          peerId: 'user-b',
        ),
        providers: [
          ChangeNotifierProvider<ChatProvider>.value(value: provider),
        ],
      ),
    );
    await tester.pumpAndSettle();
    // Bring the (single) message bubble into the hit-test viewport.
    if (find.byType(ChatMessageBubble).evaluate().isNotEmpty) {
      await tester.ensureVisible(find.byType(ChatMessageBubble).first);
      await tester.pumpAndSettle();
    }
  }

  group('ChatDetailScreen', () {
    testWidgets('shows conversation-over banner when chat is ended',
        (tester) async {
      api.onGet('/chats/chat-1', body: detailJson(isEnded: true));
      api.onGet('/messages/chat-1', body: {'items': []});
      api.install();

      await tester.pumpWidget(
        buildTestable(
          ChatDetailScreen(
            identifier: 'chat-1',
            userName: 'Bob',
            peerId: 'user-b',
          ),
          providers: [
            ChangeNotifierProvider<ChatProvider>.value(value: provider),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('This conversation with Bob is over.'), findsOneWidget);
      expect(find.byType(ChatInputBar), findsNothing);
    });

    testWidgets('tapping a message opens options sheet', (tester) async {
      await pumpChat(tester);

      await tester.tap(find.text('Hello'));
      await tester.pumpAndSettle();

      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Reply'), findsOneWidget);
      expect(find.text('Report'), findsOneWidget);
    });

    testWidgets('own messages show Edit and Delete options', (tester) async {
      await pumpChat(tester, senderId: 'user-a');

      await tester.tap(find.text('Hello'));
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('other users messages hide Edit and Delete options',
        (tester) async {
      await pumpChat(tester, senderId: 'user-b');

      await tester.tap(find.text('Hello'));
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsNothing);
      expect(find.text('Delete'), findsNothing);
      expect(find.text('Copy'), findsOneWidget);
    });

    testWidgets('copy writes the message content to the clipboard',
        (tester) async {
      await pumpChat(tester);

      await tester.tap(find.text('Hello'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();

      final data = await Clipboard.getData('text/plain');
      expect(data?.text, 'Hello');
    });

    testWidgets('delete dialog checkbox toggles delete for all',
        (tester) async {
      await pumpChat(tester, senderId: 'user-a');
      api.onDelete('/messages/msg-1', statusCode: 204);

      await tester.tap(find.text('Hello'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete for Bob too'), findsOneWidget);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();

      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(provider.messages.first.isDeleted, isTrue);
      api.expectCalled('/messages/msg-1');
    });
  });
}
