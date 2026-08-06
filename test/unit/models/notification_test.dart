import 'package:flutter_test/flutter_test.dart';
import 'package:dating_app/models/notification.dart';
import '../../helpers/fixtures.dart';

void main() {
  group('AppNotification.fromJson', () {
    test('parses a full notification', () {
      final n = AppNotification.fromJson({
        'id': 'n-1',
        'type': 'new_message',
        'title': 'New message',
        'body': 'You have a new message',
        'data': {'chat_id': 'chat-1'},
        'is_read': false,
        'created_at': kNowIso,
      });
      expect(n.id, 'n-1');
      expect(n.type, 'new_message');
      expect(n.title, 'New message');
      expect(n.body, 'You have a new message');
      expect(n.data, {'chat_id': 'chat-1'});
      expect(n.isRead, isFalse);
      expect(n.createdAt, kNow);
    });

    test('defaults type and is_read when absent', () {
      final n = AppNotification.fromJson({'id': 'n-1'});
      expect(n.type, 'system');
      expect(n.title, '');
      expect(n.body, isNull);
      expect(n.data, isNull);
      expect(n.isRead, isFalse);
    });

    test('ignores data that is not a string-keyed map', () {
      final n = AppNotification.fromJson({
        'id': 'n-1',
        'data': [1, 2, 3],
      });
      expect(n.data, isNull);
    });
  });

  group('AppNotification.copyWith', () {
    test('marks as read without mutating original', () {
      final n = AppNotification.fromJson({
        'id': 'n-1',
        'type': 'new_message',
        'title': 't',
        'created_at': kNowIso,
      });
      final read = n.copyWith(isRead: true);
      expect(read.isRead, isTrue);
      expect(n.isRead, isFalse);
      expect(read.id, n.id);
      expect(read.createdAt, n.createdAt);
    });
  });
}