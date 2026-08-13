import 'package:flutter_test/flutter_test.dart';
import 'package:dating_app/models/ticket.dart';

void main() {
  group('TicketMessage.fromJson', () {
    test('parses a user message', () {
      final m = TicketMessage.fromJson({
        'id': 'm-1',
        'sender_type': 'user',
        'content': 'Please help me',
        'created_at': '2026-08-05T12:00:00.000',
      });

      expect(m.id, 'm-1');
      expect(m.senderType, 'user');
      expect(m.isFromAdmin, isFalse);
      expect(m.content, 'Please help me');
      expect(m.adminName, isNull);
    });

    test('parses an admin message with name', () {
      final m = TicketMessage.fromJson({
        'id': 'm-2',
        'sender_type': 'admin',
        'admin_name': 'admin-1',
        'content': 'Working on it',
        'created_at': '2026-08-05T12:00:00.000',
      });

      expect(m.isFromAdmin, isTrue);
      expect(m.adminName, 'admin-1');
    });
  });

  group('Ticket.fromJson', () {
    test('parses a ticket with a conversation thread', () {
      final t = Ticket.fromJson({
        'id': 't-1',
        'user_id': 'u-1',
        'subject': 'Payment / Premium',
        'message': 'Please help me',
        'status': 'open',
        'admin_response': null,
        'created_at': '2026-08-05T12:00:00.000',
        'updated_at': null,
        'messages': [
          {
            'id': 'm-1',
            'sender_type': 'user',
            'content': 'Please help me',
            'created_at': '2026-08-05T12:00:00.000',
          },
          {
            'id': 'm-2',
            'sender_type': 'admin',
            'admin_name': 'admin',
            'content': 'Hi, tell me more',
            'created_at': '2026-08-05T12:01:00.000',
          },
        ],
      });

      expect(t.id, 't-1');
      expect(t.userId, 'u-1');
      expect(t.subject, 'Payment / Premium');
      expect(t.status, 'open');
      expect(t.isClosed, isFalse);
      expect(t.messages, hasLength(2));
      expect(t.messages.first.isFromAdmin, isFalse);
      expect(t.messages.last.isFromAdmin, isTrue);
    });

    test('isClosed returns true only for closed status', () {
      final open = Ticket.fromJson({
        'id': 't-1',
        'user_id': 'u-1',
        'subject': 's',
        'message': 'm',
        'status': 'open',
        'created_at': '2026-08-05T12:00:00.000',
      });
      final inProgress = Ticket.fromJson({
        'id': 't-2',
        'user_id': 'u-1',
        'subject': 's',
        'message': 'm',
        'status': 'in_progress',
        'created_at': '2026-08-05T12:00:00.000',
      });
      final closed = Ticket.fromJson({
        'id': 't-3',
        'user_id': 'u-1',
        'subject': 's',
        'message': 'm',
        'status': 'closed',
        'created_at': '2026-08-05T12:00:00.000',
      });

      expect(open.isClosed, isFalse);
      expect(inProgress.isClosed, isFalse);
      expect(closed.isClosed, isTrue);
    });

    test('handles missing messages', () {
      final t = Ticket.fromJson({
        'id': 't-1',
        'user_id': 'u-1',
        'subject': 's',
        'message': 'm',
        'status': 'open',
        'created_at': '2026-08-05T12:00:00.000',
      });

      expect(t.messages, isEmpty);
    });
  });

  group('TicketPage.fromJson', () {
    test('parses list response with next_offset', () {
      final page = TicketPage.fromJson({
        'tickets': [
          {
            'id': 't-1',
            'user_id': 'u-1',
            'subject': 's',
            'message': 'm',
            'status': 'open',
            'created_at': '2026-08-05T12:00:00.000',
          },
        ],
        'total': 1,
        'next_offset': 20,
      });

      expect(page.tickets, hasLength(1));
      expect(page.tickets.first.id, 't-1');
      expect(page.total, 1);
      expect(page.nextOffset, 20);
    });

    test('next_offset is null for last page', () {
      final page = TicketPage.fromJson({
        'tickets': <Map<String, dynamic>>[],
        'total': 0,
        'next_offset': null,
      });

      expect(page.tickets, isEmpty);
      expect(page.nextOffset, isNull);
    });
  });
}