import 'package:flutter_test/flutter_test.dart';
import 'package:dating_app/models/chat_card.dart';
import '../../helpers/fixtures.dart';

void main() {
  group('ChatUser.fromJson', () {
    test('parses user fields', () {
      final u = ChatUser.fromJson(const {
        'id': 'user-b',
        'name': 'Bob',
        'age': 28,
        'main_photo_url': 'https://e.com/p.jpg',
        'is_online': true,
        'last_seen_at': kNowIso,
      });
      expect(u.id, 'user-b');
      expect(u.name, 'Bob');
      expect(u.age, 28);
      expect(u.mainPhotoUrl, 'https://e.com/p.jpg');
      expect(u.isOnline, isTrue);
      expect(u.lastSeenAt, kNowIso);
    });

    test('defaults when fields absent', () {
      final u = ChatUser.fromJson(const {});
      expect(u.id, '');
      expect(u.name, '');
      expect(u.age, 0);
      expect(u.isOnline, isFalse);
    });
  });

  group('ChatLastMessage.fromJson', () {
    test('parses a text last message', () {
      final m = ChatLastMessage.fromJson({
        'content': 'Hello there',
        'message_type': 'text',
        'is_sent': true,
        'is_read': true,
        'sent_at': kNowIso,
      });
      expect(m.content, 'Hello there');
      expect(m.messageType, 'text');
      expect(m.isSent, isTrue);
      expect(m.isRead, isTrue);
      expect(m.sentAt, kNow);
    });

    test('defaults is_sent/is_read and type', () {
      final m = ChatLastMessage.fromJson({'sent_at': kNowIso});
      expect(m.messageType, 'text');
      expect(m.isSent, isTrue);
      expect(m.isRead, isFalse);
    });
  });

  group('ChatCard.fromJson', () {
    test('parses a full chat card', () {
      final c = ChatCard.fromJson({
        'id': 'chat-1',
        'status': 'accepted',
        'initiator_id': 'user-a',
        'user': {'id': 'user-b', 'name': 'Bob', 'age': 28},
        'last_message': {
          'content': 'Hey',
          'message_type': 'text',
          'sent_at': kNowIso,
        },
        'unread_count': 3,
        'updated_at': kNowIso,
      });
      expect(c.id, 'chat-1');
      expect(c.status, 'accepted');
      expect(c.initiatorId, 'user-a');
      expect(c.user.name, 'Bob');
      expect(c.lastMessage!.content, 'Hey');
      expect(c.unreadCount, 3);
      expect(c.updatedAt, kNow);
    });

    test('defaults when minimal JSON provided', () {
      final c = ChatCard.fromJson(const {});
      expect(c.id, '');
      expect(c.status, 'pending');
      expect(c.initiatorId, '');
      expect(c.user.id, '');
      expect(c.lastMessage, isNull);
      expect(c.unreadCount, 0);
      expect(c.updatedAt, isNull);
    });

    test('treats null user as an empty ChatUser', () {
      final c = ChatCard.fromJson({'id': 'x', 'user': null});
      expect(c.user.name, '');
    });
  });

  group('ChatCard.copyWith', () {
    test('only updates provided fields', () {
      final c = chatCard();
      final edited = c.copyWith(status: 'pending', unreadCount: 7);
      expect(edited.status, 'pending');
      expect(edited.unreadCount, 7);
      expect(edited.id, c.id);
      expect(edited.initiatorId, c.initiatorId);
      expect(edited.user.id, c.user.id);
    });
  });

  group('ChatCard toJson round-trip', () {
    test('preserves fields', () {
      final original = ChatCard.fromJson({
        'id': 'chat-1',
        'status': 'pending',
        'initiator_id': 'user-a',
        'user': {'id': 'user-b', 'name': 'Bob', 'age': 28},
        'last_message': {
          'content': 'Hi',
          'message_type': 'text',
          'sent_at': kNowIso,
        },
        'unread_count': 2,
        'updated_at': kNowIso,
      });
      final round = ChatCard.fromJson(original.toJson());
      expect(round.id, original.id);
      expect(round.status, original.status);
      expect(round.unreadCount, original.unreadCount);
      expect(round.lastMessage!.content, 'Hi');
      expect(round.updatedAt, kNow);
    });
  });
}