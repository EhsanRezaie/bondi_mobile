import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dating_app/services/chat_websocket_service.dart';
import '../../helpers/fake_websocket_channel.dart';
import '../../helpers/test_helpers.dart';

void main() {
  late ChatWebSocketService service;
  late FakeWebSocketChannel fake;

  setUpAll(() async {
    await initTestEnvironment();
  });

  ChatWebSocketService buildService({String matchId = 'm1'}) {
    fake = FakeWebSocketChannel();
    service = ChatWebSocketService(
      matchId: matchId,
      jwtToken: 'test-token',
      channelFactory: (_) => fake,
    );
    return service;
  }

  tearDown(() {
    service.dispose();
    fake.dispose();
  });

  group('connect()', () {
    test('opens the channel with the expected URL', () async {
      Uri? opened;
      fake = FakeWebSocketChannel();
      service = ChatWebSocketService(
        matchId: 'm1',
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
      expect(opened!.path, contains('/ws/chat/m1'));
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

  group('send helpers', () {
    test('emit the correct JSON envelopes', () async {
      buildService();
      await service.connect();

      service.sendPing();
      service.sendTyping();
      service.sendTypingStopped();
      service.sendReadReceipt(['a', 'b']);

      expect(fake.sent, [
        '{"type":"ping"}',
        '{"type":"typing"}',
        '{"type":"typing_stopped"}',
        '{"type":"read","message_ids":["a","b"]}',
      ]);
    });

    test('do nothing after dispose', () async {
      buildService();
      await service.connect();
      await service.dispose();

      service.sendPing();
      expect(fake.sent, isEmpty);
    });
  });

  group('incoming frames', () {
    test('emits parsed JSON events', () async {
      buildService();
      final events = <Map<String, dynamic>>[];
      service.events.listen(events.add);
      await service.connect();

      fake.emitIncoming('{"type":"new_message","data":{"id":"m1"}}');
      await Future<void>.delayed(Duration.zero);

      expect(events, [
        {'type': 'new_message', 'data': {'id': 'm1'}},
      ]);
    });

    test('ignores malformed frames without crashing', () async {
      buildService();
      final events = <Map<String, dynamic>>[];
      service.events.listen(events.add);
      await service.connect();

      fake.emitIncoming('this is not json');
      fake.emitIncoming('{"broken":');

      expect(events, isEmpty);
    });
  });

  group('reconnect', () {
    test('reconnects 1s after the server closes a healthy connection', () {
      fakeAsync((async) {
        final fakes = <FakeWebSocketChannel>[];
        final svc = ChatWebSocketService(
          matchId: 'm1',
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

    test('backoff grows [1,2,4,8,16,30] when open keeps failing, capped at 6', () {
      fakeAsync((async) {
        var connectCalls = 0;
        final svc = ChatWebSocketService(
          matchId: 'm1',
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
        // 1 initial + 6 reconnects = 7; further failures are not retried.
        expect(connectCalls, 7);

        async.elapse(const Duration(minutes: 10));
        expect(connectCalls, 7);

        svc.dispose();
      });
    });
  });

  group('dispose()', () {
    test('closes the channel sink and stops heartbeat timers', () async {
      buildService();
      await service.connect();
      await service.dispose();
      expect(fake.closeCount, 1);
      // Sending after dispose must be a no-op.
      service.sendTyping();
      expect(fake.sent, isEmpty);
    });
  });
}