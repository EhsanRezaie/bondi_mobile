import 'dart:async';
import 'package:stream_channel/stream_channel.dart';

/// In-memory fake [StreamChannel] for driving `ChatWebSocketService` in tests.
///
/// The test pushes raw frames through [emitIncoming] (the channel's stream)
/// and reads everything the service wrote via [sent].
class FakeWebSocketChannel extends StreamChannelMixin<dynamic> {
  final _incoming = StreamController<dynamic>(sync: true);
  final _outgoing = StreamController<dynamic>(sync: true);

  final List<String> sent = [];
  int closeCount = 0;

  FakeWebSocketChannel() {
    _outgoing.stream.listen(
      (data) => sent.add(data.toString()),
      onDone: () => closeCount++,
    );
  }

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  StreamSink<dynamic> get sink => _outgoing.sink;

  /// Emit a raw frame (string) as if it arrived from the server.
  void emitIncoming(dynamic data) => _incoming.add(data);

  /// Close the incoming stream (server side disconnect).
  void disconnect() => _incoming.close();

  void dispose() {
    _incoming.close();
    _outgoing.close();
  }
}
