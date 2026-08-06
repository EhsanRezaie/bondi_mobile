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
  });
}

Future<void> _noop() async {}

void _noopTap(ChatCard _) {}
