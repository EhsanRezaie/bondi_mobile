import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dating_app/services/session_socket_service.dart';
import '../../helpers/fake_websocket_channel.dart';
import '../../helpers/test_helpers.dart';

void main() {
  late SessionSocketService service;
  late FakeWebSocketChannel fake;

  setUpAll(() async {
    await initTestEnvironment();
  });

  SessionSocketService buildService({String token = 'test-token'}) {
    fake = FakeWebSocketChannel();
    service = SessionSocketService(
      jwtToken: token,
      channelFactory: (_) => fake,
    );
    return service;
  }

  tearDown(() async {
    await service.dispose();
    fake.dispose();
  });

  group('connect()', () {
    test('opens /ws/stream with the token query param', () async {
      Uri? opened;
      fake = FakeWebSocketChannel();
      service = SessionSocketService(
        jwtToken: 'tok-123',
        channelFactory: (uri) {
          opened = uri;
          return fake;
        },
      );
      final states = <bool>[];
      service.connectionState.listen(states.add);

      await service.connect();

      expect(opened, isNotNull);
      expect(opened!.path, contains('/ws/stream'));
      expect(opened!.queryParameters['token'], 'tok-123');
      expect(states, [true]);
    });

    test('stays silent when disposed before connect', () async {
      buildService();
      final states = <bool>[];
      service.connectionState.listen(states.add);
      await service.dispose();
      await service.connect();
      expect(states, isEmpty);
    });
  });

  group('heartbeat', () {
    test('emits a ping every 30s', () {
      fakeAsync((async) {
        buildService();
        service.connect();
        async.flushMicrotasks();
        expect(fake.sent, isEmpty);

        async.elapse(const Duration(seconds: 30));
        async.flushMicrotasks();
        expect(fake.sent, ['{"type":"ping"}']);

        async.elapse(const Duration(seconds: 30));
        async.flushMicrotasks();
        expect(fake.sent.length, 2);
        expect(fake.sent[1], '{"type":"ping"}');
      });
    });
  });

  group('topic + chat frames', () {
    test('emit the correct JSON envelopes', () async {
      buildService();
      await service.connect();

      service.subscribe('c1');
      service.unsubscribe('c1');
      service.sendTyping('c1');
      service.sendTypingStopped('c1');
      service.sendReadReceipt('c1', ['a', 'b']);

      expect(fake.sent, [
        '{"type":"subscribe","chat_id":"c1"}',
        '{"type":"unsubscribe","chat_id":"c1"}',
        '{"type":"typing","chat_id":"c1"}',
        '{"type":"typing_stopped","chat_id":"c1"}',
        '{"type":"read","chat_id":"c1","message_ids":["a","b"]}',
      ]);
    });

    test('do nothing after dispose', () async {
      buildService();
      await service.connect();
      await service.dispose();

      service.sendTyping('c1');
      expect(fake.sent, isEmpty);
    });
  });

  group('incoming frames', () {
    test('emits parsed JSON events', () async {
      buildService();
      final events = <Map<String, dynamic>>[];
      service.events.listen(events.add);
      await service.connect();

      fake.emitIncoming('{"type":"new_message","data":{"chat_id":"c1"}}');
      await Future<void>.delayed(Duration.zero);

      expect(events, [
        {'type': 'new_message', 'data': {'chat_id': 'c1'}},
      ]);
    });

    test('ignores malformed frames without crashing', () async {
      buildService();
      final events = <Map<String, dynamic>>[];
      service.events.listen(events.add);
      await service.connect();

      fake.emitIncoming('not json');
      fake.emitIncoming('{"broken":');

      expect(events, isEmpty);
    });
  });

  group('reconnect', () {
    test('reconnects 1s after the server closes the connection', () {
      fakeAsync((async) {
        final fakes = <FakeWebSocketChannel>[];
        final svc = SessionSocketService(
          jwtToken: 't',
          channelFactory: (_) {
            final f = FakeWebSocketChannel();
            fakes.add(f);
            return f;
          },
        );
        final states = <bool>[];
        svc.connectionState.listen(states.add);

        svc.connect();
        async.flushMicrotasks();
        expect(fakes.length, 1);
        expect(states.last, isTrue);

        fakes.last.disconnect();
        async.flushMicrotasks();
        expect(states.last, isFalse);
        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
        expect(fakes.length, 2);
        expect(states.last, isTrue);

        svc.dispose();
        for (final f in fakes) {
          f.dispose();
        }
      });
    });

    test('backoff grows [1,2,4,8,16,30] capped at 6 retries', () {
      fakeAsync((async) {
        var connectCalls = 0;
        final svc = SessionSocketService(
          jwtToken: 't',
          channelFactory: (_) {
            connectCalls++;
            throw Exception('connection refused');
          },
        );
        final states = <bool>[];
        svc.connectionState.listen(states.add);

        svc.connect();
        async.flushMicrotasks();
        expect(connectCalls, 1);
        expect(states.last, isFalse);

        var expectedCalls = 1;
        for (final seconds in [1, 2, 4, 8, 16, 30]) {
          async.elapse(Duration(seconds: seconds));
          expectedCalls++;
          expect(connectCalls, expectedCalls);
        }
        expect(connectCalls, 7);

        async.elapse(const Duration(minutes: 10));
        expect(connectCalls, 7);

        svc.dispose();
      });
    });
  });

  group('dispose()', () {
    test('closes the channel sink and stops timers', () async {
      buildService();
      await service.connect();
      await service.dispose();
      expect(fake.closeCount, 1);
      service.sendTyping('c1');
      expect(fake.sent, isEmpty);
    });
  });

  group('edge cases', () {
    test('does not crash when channel factory throws', () {
      final svc = SessionSocketService(
        jwtToken: 'test-token',
        channelFactory: (Uri url) {
          throw Exception('Connection refused');
        },
      );

      svc.connect();
      svc.dispose();
    });

    test('does not crash on connect/dispose churn', () {
      final svc = SessionSocketService(
        jwtToken: 'test-token',
        channelFactory: (Uri url) {
          return FakeWebSocketChannel();
        },
      );

      svc.connect();
      svc.dispose();
      svc.sendTyping('c1');
    });
  });
}