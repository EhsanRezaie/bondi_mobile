import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dating_app/services/chat_list_websocket_service.dart';
import '../../helpers/fake_websocket_channel.dart';
import '../../helpers/test_helpers.dart';

void main() {
  late ChatListWebSocketService service;
  late FakeWebSocketChannel fake;

  setUpAll(() async {
    await initTestEnvironment();
  });

  ChatListWebSocketService buildService({String token = 'test-token'}) {
    fake = FakeWebSocketChannel();
    service = ChatListWebSocketService(
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
    test('opens /ws/matches with the token query param', () async {
      Uri? opened;
      fake = FakeWebSocketChannel();
      service = ChatListWebSocketService(
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
      expect(opened!.path, contains('/ws/matches'));
      expect(opened!.queryParameters['token'], 'tok-123');
      expect(states, [true]);
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

  group('incoming frames', () {
    test('emits parsed JSON events', () async {
      buildService();
      final events = <Map<String, dynamic>>[];
      service.events.listen(events.add);
      await service.connect();

      fake.emitIncoming('{"type":"new_chat","data":{"chat_id":"c1"}}');
      await Future<void>.delayed(Duration.zero);

      expect(events, [
        {'type': 'new_chat', 'data': {'chat_id': 'c1'}},
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
        final svc = ChatListWebSocketService(
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
  });

  group('dispose()', () {
    test('closes the channel sink and cancels heartbeat', () async {
      buildService();
      await service.connect();
      await service.dispose();
      expect(fake.closeCount, 1);
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
}