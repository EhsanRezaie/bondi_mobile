import 'package:flutter_test/flutter_test.dart';
import 'package:dating_app/providers/ticket_provider.dart';
import '../../helpers/test_helpers.dart';
import '../../helpers/mock_api.dart';

void main() {
  late TicketProvider provider;
  late MockApi api;

  setUpAll(() async {
    await initTestEnvironment();
  });

  setUp(() {
    provider = TicketProvider();
    api = MockApi();
  });

  tearDown(() {
    provider.dispose();
  });

  Map<String, dynamic> ticketJson({
    String id = 't-1',
    String status = 'open',
    List<Map<String, dynamic>> messages = const [],
  }) {
    return {
      'id': id,
      'user_id': 'u-1',
      'subject': 'Payment / Premium',
      'message': 'Please help me',
      'status': status,
      'admin_response': null,
      'created_at': '2026-08-05T12:00:00.000',
      'updated_at': null,
      'messages': messages,
    };
  }

  Map<String, dynamic> messageJson({
    String id = 'm-1',
    String senderType = 'user',
    String content = 'hi',
  }) {
    return {
      'id': id,
      'sender_type': senderType,
      'content': content,
      'created_at': '2026-08-05T12:00:00.000',
    };
  }

  group('loadTickets', () {
    test('populates tickets and pagination state', () async {
      api.onGet('/tickets', body: {
        'tickets': [ticketJson(id: 't-1'), ticketJson(id: 't-2', status: 'closed')],
        'total': 2,
        'next_offset': null,
      });
      api.install();

      final ok = await provider.loadTickets();

      expect(ok, isTrue);
      expect(provider.tickets, hasLength(2));
      expect(provider.tickets.first.id, 't-1');
      expect(provider.tickets.last.isClosed, isTrue);
      expect(provider.hasMore, isFalse);
      expect(provider.isLoading, isFalse);
      api.expectCalled('/tickets');
    });

    test('sets hasMore when next_offset present', () async {
      api.onGet('/tickets', body: {
        'tickets': [ticketJson()],
        'total': 1,
        'next_offset': 20,
      });
      api.install();

      await provider.loadTickets();

      expect(provider.hasMore, isTrue);
    });

    test('sets errorMessage on failure and keeps list empty', () async {
      api.onGet('/tickets', body: {'detail': 'boom'}, statusCode: 500);
      api.install();

      await provider.loadTickets();

      expect(provider.tickets, isEmpty);
      expect(provider.errorMessage, isNotNull);
      expect(provider.isLoading, isFalse);
    });
  });

  group('loadMoreTickets', () {
    test('appends the next page without duplicates', () async {
      api.onGet('/tickets', body: {
        'tickets': [ticketJson(id: 't-1')],
        'total': 2,
        'next_offset': 20,
      });
      api.install();
      await provider.loadTickets();

      api.onGet('/tickets', body: {
        'tickets': [ticketJson(id: 't-1'), ticketJson(id: 't-2')],
        'total': 2,
        'next_offset': null,
      });
      await provider.loadMoreTickets();

      expect(provider.tickets, hasLength(2));
      expect(provider.tickets.map((t) => t.id).toSet(), {'t-1', 't-2'});
      expect(provider.hasMore, isFalse);
    });

    test('does nothing when no more pages', () async {
      api.onGet('/tickets', body: {
        'tickets': [ticketJson()],
        'total': 1,
        'next_offset': null,
      });
      api.install();
      await provider.loadTickets();

      await provider.loadMoreTickets();

      expect(provider.tickets, hasLength(1));
    });
  });

  group('createTicket', () {
    test('prepends the created ticket to the list', () async {
      api.onGet('/tickets', body: {
        'tickets': <Map<String, dynamic>>[],
        'total': 0,
        'next_offset': null,
      });
      api.install();
      await provider.loadTickets();
      expect(provider.tickets, isEmpty);

      api.onPost(
        '/tickets',
        body: ticketJson(id: 't-new'),
        statusCode: 201,
        data: {'subject': 'Payment / Premium', 'message': 'Please help me'},
      );
      final ok = await provider.createTicket('Payment / Premium', 'Please help me');

      expect(ok, isTrue);
      expect(provider.tickets, hasLength(1));
      expect(provider.tickets.first.id, 't-new');
      expect(provider.isCreating, isFalse);
    });

    test('returns false and sets error on failure', () async {
      api.onPost('/tickets', body: {'detail': 'boom'}, statusCode: 400);
      api.install();

      final ok = await provider.createTicket('Payment / Premium', 'Please help me');

      expect(ok, isFalse);
      expect(provider.errorMessage, isNotNull);
      expect(provider.tickets, isEmpty);
    });
  });

  group('loadTicket', () {
    test('loads ticket detail including messages', () async {
      api.onGet('/tickets/t-1', body: ticketJson(
        id: 't-1',
        messages: [
          messageJson(id: 'm-1'),
          messageJson(id: 'm-2', senderType: 'admin', content: 'Working on it'),
        ],
      ));
      api.install();

      final ok = await provider.loadTicket('t-1');

      expect(ok, isTrue);
      expect(provider.currentTicket, isNotNull);
      expect(provider.currentTicket!.messages, hasLength(2));
      expect(provider.currentTicket!.messages.last.isFromAdmin, isTrue);
    });

    test('sets error on failure', () async {
      api.onGet('/tickets/t-1', body: {'detail': 'nope'}, statusCode: 404);
      api.install();

      final ok = await provider.loadTicket('t-1');

      expect(ok, isFalse);
      expect(provider.currentTicket, isNull);
      expect(provider.errorMessage, isNotNull);
    });
  });

  group('replyToTicket', () {
    test('updates current ticket and the list item', () async {
      api.onGet('/tickets', body: {
        'tickets': [ticketJson(id: 't-1')],
        'total': 1,
        'next_offset': null,
      });
      api.install();
      await provider.loadTickets();
      expect(provider.tickets.first.messages, isEmpty);

      final replyMessages = [
        messageJson(id: 'm-1'),
        messageJson(id: 'm-2', senderType: 'admin', content: 'On it'),
      ];
      api.onPost(
        '/tickets/t-1/messages',
        body: ticketJson(id: 't-1', messages: replyMessages),
        statusCode: 201,
        data: {'content': 'hi'},
      );
      final ok = await provider.replyToTicket('t-1', 'hi');

      expect(ok, isTrue);
      expect(provider.currentTicket, isNotNull);
      expect(provider.currentTicket!.messages, hasLength(2));
      expect(provider.tickets.first.messages, hasLength(2));
      expect(provider.isReplying, isFalse);
    });
  });
}