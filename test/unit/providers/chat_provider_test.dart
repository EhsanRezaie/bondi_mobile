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

  group('chat detail flags (blocked / ended)', () {
    test('marks chat as ended from detail and disables sending', () async {
      api.onGet('/chats/chat-1', body: {
        'id': 'chat-1',
        'status': 'accepted',
        'initiator_id': 'user-a',
        'user': {'id': 'user-b'},
        'is_blocked': false,
        'is_ended': true,
      });
      api.onGet('/messages/chat-1', body: {'items': []});
      api.install();

      await provider.loadMessages('chat-1');

      expect(provider.isEnded, isTrue);
      expect(provider.conversationIsOver, isTrue);
      expect(provider.canSendMessage, isFalse);
    });

    test('marks chat as blocked from detail', () async {
      api.onGet('/chats/chat-1', body: {
        'id': 'chat-1',
        'status': 'accepted',
        'initiator_id': 'user-a',
        'user': {'id': 'user-b'},
        'is_blocked': true,
        'is_ended': false,
      });
      api.onGet('/messages/chat-1', body: {'items': []});
      api.install();

      await provider.loadMessages('chat-1');

      expect(provider.isBlocked, isTrue);
      expect(provider.conversationIsOver, isTrue);
      expect(provider.canSendMessage, isFalse);
    });
  });

  group('blockUser / unblockUser', () {
    test('blockUser sets isBlocked and ends the conversation', () async {
      api.onPost('/blocks/user-b/block', body: {}, statusCode: 204);
      api.install();

      final ok = await provider.blockUser('user-b');

      expect(ok, isTrue);
      expect(provider.isBlocked, isTrue);
      expect(provider.conversationIsOver, isTrue);
    });

    test('blockUser failure reports error and keeps state', () async {
      api.onPost(
        '/blocks/user-b/block',
        body: {'detail': 'Block failed'},
        statusCode: 400,
      );
      api.install();

      final ok = await provider.blockUser('user-b');

      expect(ok, isFalse);
      expect(provider.isBlocked, isFalse);
      expect(provider.errorMessage, isNotNull);
    });

    test('unblockUser clears isBlocked', () async {
      api.onPost(
        '/blocks/user-b/unblock',
        body: {},
        statusCode: 204,
      );
      api.install();

      final ok = await provider.unblockUser('user-b');

      expect(ok, isTrue);
      expect(provider.isBlocked, isFalse);
      expect(provider.conversationIsOver, isFalse);
    });
  });

  group('deleteChat', () {
    test('calls the API and removes the card', () async {
      api.onGet('/chats', body: chatJson(status: 'accepted'));
      api.install();
      await provider.loadConversations();
      expect(provider.conversations, hasLength(1));

      api.onDelete('/chats/chat-1', statusCode: 204);
      final ok = await provider.deleteChat('chat-1');

      expect(ok, isTrue);
      expect(provider.conversations, isEmpty);
      expect(provider.isEnded, isTrue);
      api.expectCalled('/chats/chat-1');
    });
  });

  group('report', () {
    test('reportMessage returns true on 201', () async {
      api.onPost(
        '/reports/message/msg-1',
        body: {},
        statusCode: 201,
        data: {'reason': 'Spam or inappropriate'},
      );
      api.install();

      final ok = await provider.reportMessage(
        'msg-1',
        reason: 'Spam or inappropriate',
      );

      expect(ok, isTrue);
    });

    test('reportMessage failure sets errorMessage', () async {
      api.onPost(
        '/reports/message/msg-1',
        body: {'detail': 'Already reported'},
        statusCode: 400,
        data: {'reason': 'Spam or inappropriate'},
      );
      api.install();

      final ok = await provider.reportMessage(
        'msg-1',
        reason: 'Spam or inappropriate',
      );

      expect(ok, isFalse);
      expect(provider.errorMessage, isNotNull);
    });

    test('reportUser returns true on 201', () async {
      api.onPost(
        '/reports/user-1',
        body: {'reason': 'Spam'},
        statusCode: 201,
        data: {'reason': 'Spam'},
      );
      api.install();

      final ok = await provider.reportUser('user-1', 'Spam');

      expect(ok, isTrue);
    });
  });

  group('editMessage', () {
    test('updates the message content and edited flag', () async {
      api.onGet('/chats/chat-1', body: {
        'id': 'chat-1',
        'status': 'accepted',
        'initiator_id': 'user-a',
        'user': {'id': 'user-b'},
      });
      api.onGet('/messages/chat-1', body: {'items': [jsonMessage(id: 'msg-1')]});
      api.install();
      await provider.loadMessages('chat-1');
      expect(provider.messages.first.content, 'Hello');

      api.onPut(
        '/messages/msg-1',
        body: jsonMessage(id: 'msg-1', content: 'Edited!'),
        data: {'content': 'Edited!'},
      );
      final ok = await provider.editMessage('msg-1', 'Edited!');

      expect(ok, isTrue);
      expect(provider.messages.first.content, 'Edited!');
      expect(provider.messages.first.isEdited, isTrue);
    });
  });

  group('deleteMessage', () {
    Future<void> seed() async {
      api.onGet('/chats/chat-1', body: {
        'id': 'chat-1',
        'status': 'accepted',
        'initiator_id': 'user-a',
        'user': {'id': 'user-b'},
      });
      api.onGet('/messages/chat-1', body: {'items': [jsonMessage(id: 'msg-1')]});
      api.install();
      await provider.loadMessages('chat-1');
    }

    test('delete for self removes the message', () async {
      await seed();
      api.onDelete('/messages/msg-1', statusCode: 204);

      final ok = await provider.deleteMessage('msg-1');

      expect(ok, isTrue);
      expect(provider.messages, isEmpty);
    });

    test('delete for all marks the message deleted instead of removing', () async {
      await seed();
      api.onDelete('/messages/msg-1', statusCode: 204);

      final ok = await provider.deleteMessage('msg-1', deleteForAll: true);

      expect(ok, isTrue);
      expect(provider.messages, hasLength(1));
      expect(provider.messages.first.isDeleted, isTrue);
    });
  });

  group('WebSocket event handlers (state transitions)', () {
    Future<void> seed({bool blocked = false, bool ended = false}) async {
      api.onGet('/chats/chat-1', body: {
        'id': 'chat-1',
        'status': 'accepted',
        'initiator_id': 'user-a',
        'user': {'id': 'user-b'},
        'is_blocked': blocked,
        'is_ended': ended,
      });
      api.onGet('/messages/chat-1', body: {'items': [jsonMessage(id: 'msg-1')]});
      api.install();
      await provider.loadMessages('chat-1');
    }

    test('blocked event for the peer marks the chat blocked', () async {
      await seed();
      expect(provider.isBlocked, isFalse);

      provider.applyBlockedEvent(
        {'user_id': 'user-b'},
        {},
      );

      expect(provider.isBlocked, isTrue);
      expect(provider.conversationIsOver, isTrue);
    });

    test('blocked event for a different user is ignored', () async {
      await seed();

      provider.applyBlockedEvent({'user_id': 'user-other'}, {});

      expect(provider.isBlocked, isFalse);
    });

    test('chat_ended event for the active chat ends the conversation', () async {
      await seed();
      expect(provider.isEnded, isFalse);

      provider.applyChatEndedEvent({'chat_id': 'chat-1'}, {});

      expect(provider.isEnded, isTrue);
      expect(provider.conversationIsOver, isTrue);
      expect(provider.canSendMessage, isFalse);
    });

    test('chat_ended event for a different chat is ignored', () async {
      await seed();

      provider.applyChatEndedEvent({'chat_id': 'chat-999'}, {});

      expect(provider.isEnded, isFalse);
    });

    test('message_edited updates content and marks isEdited', () async {
      await seed();
      expect(provider.messages.first.isEdited, isFalse);

      provider.applyMessageEdited({
        'id': 'msg-1',
        'content': 'Updated via WS',
        'is_edited': true,
      });

      expect(provider.messages.first.content, 'Updated via WS');
      expect(provider.messages.first.isEdited, isTrue);
    });

    test('message_edited for an unknown id is a no-op', () async {
      await seed();
      final before = provider.messages.first.content;

      provider.applyMessageEdited({'id': 'nope', 'content': 'x', 'is_edited': true});

      expect(provider.messages.first.content, before);
      expect(provider.messages.first.isEdited, isFalse);
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
