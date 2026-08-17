import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dating_app/screens/chats/chat_list_screen.dart';
import 'package:dating_app/models/chat_card.dart';
import '../../../helpers/test_helpers.dart';
import '../../../helpers/fixtures.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('ChatListScreen', () {
    testWidgets('renders conversations list', (tester) async {
      final c = chatCard(name: 'Bob');

      await tester.pumpWidget(
        buildTestable(
          Material(
            child: ChatListScreen(
              chats: [c],
              isLoading: false,
              isLoadingMore: false,
              hasMore: false,
              emptyText: 'No chats',
              onRefresh: () async {},
              onLoadMore: () async {},
              onChatTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('shows empty state when no conversations', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const Material(
            child: ChatListScreen(
              chats: [],
              isLoading: false,
              isLoadingMore: false,
              hasMore: false,
              emptyText: 'No chats',
              onRefresh: _noop,
              onLoadMore: _noop,
              onChatTap: _noopTap,
            ),
          ),
        ),
      );

      expect(find.byType(ChatListScreen), findsOneWidget);
      expect(find.text('No chats'), findsOneWidget);
    });

    testWidgets('shows loading indicator while fetching', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          Material(
            child: ChatListScreen(
              chats: const <ChatCard>[],
              isLoading: true,
              isLoadingMore: false,
              hasMore: false,
              emptyText: 'No chats',
              onRefresh: () async {},
              onLoadMore: () async {},
              onChatTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('tap fires onChatTap with the card', (tester) async {
      final c = chatCard(name: 'Bob');
      ChatCard? tapped;

      await tester.pumpWidget(
        buildTestable(
          Material(
            child: ChatListScreen(
              chats: [c],
              isLoading: false,
              isLoadingMore: false,
              hasMore: false,
              emptyText: 'No chats',
              onRefresh: () async {},
              onLoadMore: () async {},
              onChatTap: (chat) => tapped = chat,
              onChatLongPress: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Bob'));
      expect(tapped?.id, c.id);
    });

    testWidgets('long-press fires onChatLongPress with the card', (tester) async {
      final c = chatCard(name: 'Bob');
      ChatCard? longPressed;

      await tester.pumpWidget(
        buildTestable(
          Material(
            child: ChatListScreen(
              chats: [c],
              isLoading: false,
              isLoadingMore: false,
              hasMore: false,
              emptyText: 'No chats',
              onRefresh: () async {},
              onLoadMore: () async {},
              onChatTap: (_) {},
              onChatLongPress: (chat) => longPressed = chat,
            ),
          ),
        ),
      );

      await tester.longPress(find.text('Bob'));
      expect(longPressed?.id, c.id);
    });
  });
}

Future<void> _noop() async {}

void _noopTap(ChatCard _) {}
