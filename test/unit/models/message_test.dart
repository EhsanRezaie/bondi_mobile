import 'package:flutter_test/flutter_test.dart';
import 'package:dating_app/models/message.dart';
import '../../helpers/fixtures.dart';

void main() {
  group('Message.fromJson', () {
    test('parses a text message', () {
      final m = Message.fromJson(jsonMessage());
      expect(m.id, 'msg-1');
      expect(m.matchId, 'match-1');
      expect(m.senderId, 'user-a');
      expect(m.receiverId, 'user-b');
      expect(m.messageType, MessageType.text);
      expect(m.content, 'Hello');
      expect(m.mediaUrl, isNull);
      expect(m.isSent, isTrue);
      expect(m.isDelivered, isTrue);
      expect(m.isRead, isTrue);
      expect(m.sentAt, kNow);
      expect(m.deliveredAt, kNow);
      expect(m.readAt, kNow);
    });

    test('parses a photo message', () {
      final m = Message.fromJson(
        jsonMessage(messageType: 'photo', content: null, mediaUrl: 'https://e.com/p.jpg'),
      );
      expect(m.messageType, MessageType.photo);
      expect(m.content, isNull);
      expect(m.mediaUrl, 'https://e.com/p.jpg');
    });

    test('parses a voice message with duration', () {
      final m = Message.fromJson(
        jsonMessage(messageType: 'voice', mediaUrl: 'https://e.com/v.mp3', mediaDuration: 12),
      );
      expect(m.messageType, MessageType.voice);
      expect(m.mediaDuration, 12);
    });

    test('parses nested reply_to', () {
      final reply = jsonMessage(id: 'msg-0', content: 'Original');
      final m = Message.fromJson(jsonMessage(replyTo: reply));
      expect(m.replyTo, isNotNull);
      expect(m.replyTo!.id, 'msg-0');
      expect(m.replyTo!.content, 'Original');
    });

    test('parses delivered/read flags as false when absent', () {
      final m = Message.fromJson(
        jsonMessage(isDelivered: false, isRead: false, deliveredAt: null, readAt: null),
      );
      expect(m.isDelivered, isFalse);
      expect(m.isRead, isFalse);
      expect(m.deliveredAt, isNull);
      expect(m.readAt, isNull);
    });

    test('defaults to text type for unknown message_type', () {
      final m = Message.fromJson(jsonMessage(messageType: 'sticker'));
      expect(m.messageType, MessageType.text);
    });

    test('unmatched message has empty matchId', () {
      final m = Message.fromJson(jsonMessage(matchId: null));
      expect(m.matchId, '');
    });
  });

  group('Message.fromSocketData', () {
    test('ignores delivered/read timestamps (not present on socket frames)', () {
      final m = Message.fromSocketData(
        jsonMessage(deliveredAt: null, readAt: null, isDelivered: false, isRead: false),
      );
      expect(m.id, 'msg-1');
      expect(m.isDelivered, isFalse);
      expect(m.isRead, isFalse);
    });
  });

  group('Message.local', () {
    test('creates an optimistic text message with now() timestamp', () {
      final before = DateTime.now();
      final m = Message.local('tmp-1', 'match-1', 'user-a', 'user-b', 'Hey');
      final after = DateTime.now();
      expect(m.id, 'tmp-1');
      expect(m.matchId, 'match-1');
      expect(m.content, 'Hey');
      expect(m.isSent, isTrue);
      expect(m.sentAt.isBefore(after) || m.sentAt.isAtSameMomentAs(after), isTrue);
      expect(m.sentAt.isAfter(before) || m.sentAt.isAtSameMomentAs(before), isTrue);
    });
  });

  group('Message.toJson round-trip', () {
    test('preserves all fields', () {
      final original = Message.fromJson(jsonMessage());
      final round = Message.fromJson(original.toJson());
      expect(round.id, original.id);
      expect(round.matchId, original.matchId);
      expect(round.messageType, original.messageType);
      expect(round.content, original.content);
      expect(round.isEdited, original.isEdited);
      expect(round.isDeleted, original.isDeleted);
      expect(round.sentAt, original.sentAt);
    });

    test('serialises a photo message', () {
      final m = Message.fromJson(
        jsonMessage(messageType: 'photo', mediaUrl: 'https://e.com/p.jpg'),
      );
      expect(m.toJson()['message_type'], 'photo');
      expect(m.toJson()['media_url'], 'https://e.com/p.jpg');
    });
  });

  group('Message.copyWith', () {
    test('only updates provided fields', () {
      final m = Message.fromJson(jsonMessage());
      final edited = m.copyWith(content: 'Edited', isEdited: true);
      expect(edited.content, 'Edited');
      expect(edited.isEdited, isTrue);
      expect(edited.isDeleted, isFalse);
      expect(edited.id, m.id);
    });
  });
}