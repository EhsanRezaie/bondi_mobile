import 'package:flutter_test/flutter_test.dart';
import 'package:dating_app/providers/chat_provider.dart';
import '../../helpers/test_helpers.dart';
import '../../helpers/mock_api.dart';
import '../../helpers/fixtures.dart';

void main() {
  late ChatProvider provider;
  late MockApi api;

  setUpAll(() async {
    await initTestEnvironment(secrets: {'user_id': 'user-a'});
  });

  setUp(() {
    provider = ChatProvider();
    api = MockApi();
  });

  tearDown(() {
    provider.dispose();
  });

  Map<String, dynamic> chatJson({
    String id = 'chat-1',
    String status = 'accepted',
    String initiatorId = 'user-a',
    String? nextOffset,
  }) {
    return {
      'chats': [
        {
          'id': id,
          'status': status,
          'initiator_id': initiatorId,
          'user': {'id': 'user-b', 'name': 'Bob', 'age': 28},
          'last_message': {
            'content': 'Hey',
            'message_type': 'text',
            'sent_at': kNowIso,
          },
          'unread_count': 2,
          'updated_at': kNowIso,
        },
      ],
      'next_offset': nextOffset,
    };
  }

  group('loadConversations', () {
    test('populates conversations from accepted chats', () async {
      api.onGet('/chats', body: chatJson(status: 'accepted', nextOffset: null));
      api.install();

      await provider.loadConversations();

      expect(provider.conversations, hasLength(1));
      expect(provider.conversations.first.id, 'chat-1');
      expect(provider.conversations.first.user.name, 'Bob');
      expect(provider.hasMoreConversations, isFalse);
      api.expectCalled('/chats');
    });

    test('sets hasMoreConversations when next_offset is present', () async {
      api.onGet('/chats', body: chatJson(status: 'accepted', nextOffset: '20'));
      api.install();

      await provider.loadConversations();

      expect(provider.conversations, hasLength(1));
      expect(provider.hasMoreConversations, isTrue);
    });

    test('clears previous conversations on reload', () async {
      api.onGet('/chats', body: chatJson(status: 'accepted'));
      api.install();

      await provider.loadConversations();
      expect(provider.conversations, hasLength(1));

      api.onGet('/chats', body: {
        'chats': [],
        'next_offset': null,
      });
      await provider.loadConversations();

      expect(provider.conversations, isEmpty);
    });

    test('sets errorMessage when request fails', () async {
      api.onGet('/chats', body: chatJson(status: 'accepted'), statusCode: 500);
      api.install();

      await provider.loadConversations();

      expect(provider.conversations, isEmpty);
      expect(provider.errorMessage, isNotNull);
    });
  });

  group('loadPendingIncoming', () {
    test('splits pending chats by initiator', () async {
      final body = {
        'chats': [
          chatCardJson(id: 'p1', initiatorId: 'user-a', status: 'pending'),
          chatCardJson(id: 'p2', initiatorId: 'user-b', status: 'pending'),
        ],
        'next_offset': null,
      };
      api.onGet('/chats', body: body);
      api.install();

      await provider.loadPendingIncoming();

      expect(provider.pendingChats, hasLength(1));
      expect(provider.pendingChats.first.id, 'p1');
      expect(provider.incomingChats, hasLength(1));
      expect(provider.incomingChats.first.id, 'p2');
    });

    test('stores everything as incoming when I did not start any', () async {
      final body = {
        'chats': [
          chatCardJson(id: 'p1', initiatorId: 'user-b', status: 'pending'),
          chatCardJson(id: 'p2', initiatorId: 'user-c', status: 'pending'),
        ],
        'next_offset': null,
      };
      api.onGet('/chats', body: body);
      api.install();

      await provider.loadPendingIncoming();

      expect(provider.pendingChats, isEmpty);
      expect(provider.incomingChats, hasLength(2));
    });
  });

  group('loadMoreConversations', () {
    test('appends next page and updates hasMore', () async {
      api.onGet('/chats', body: chatJson(id: 'chat-1', nextOffset: '20'));
      api.install();

      await provider.loadConversations();
      expect(provider.conversations, hasLength(1));

      api.onGet('/chats', body: chatJson(id: 'chat-2', nextOffset: null));
      await provider.loadMoreConversations();

      expect(provider.conversations, hasLength(2));
      expect(provider.conversations.last.id, 'chat-2');
      expect(provider.hasMoreConversations, isFalse);
    });

    test('is a no-op when hasMore is false', () async {
      api.onGet('/chats', body: chatJson(nextOffset: null));
      api.install();

      await provider.loadConversations();
      await provider.loadMoreConversations();

      expect(provider.conversations, hasLength(1));
    });
  });
}

Map<String, dynamic> chatCardJson({
  String id = 'chat-1',
  String status = 'accepted',
  String initiatorId = 'user-a',
}) {
  return {
    'id': id,
    'status': status,
    'initiator_id': initiatorId,
    'user': {'id': 'user-b', 'name': 'Bob', 'age': 28},
    'last_message': {
      'content': 'Hey',
      'message_type': 'text',
      'sent_at': kNowIso,
    },
    'unread_count': 0,
    'updated_at': kNowIso,
  };
}
