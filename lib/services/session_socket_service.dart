import 'dart:async';
import 'dart:convert';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:dating_app/config/app_constants.dart';

/// Single persistent session socket (`/ws/stream`) held open for the whole app
/// session. Chat-level events are gated by subscribe/unsubscribe topics, so
/// opening a chat never creates a second connection.
class SessionSocketService {
  /// Resolves the auth token fresh on every (re)connect so reconnects after a
  /// 401 never reuse an expired token.
  final Future<String?> Function() tokenProvider;
  final StreamChannel<dynamic> Function(Uri url) channelFactory;

  StreamChannel<dynamic>? _channel;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 6;
  bool _disposed = false;

  final _eventsController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  SessionSocketService._({
    required this.tokenProvider,
    required this.channelFactory,
  });

  factory SessionSocketService({
    required String jwtToken,
    StreamChannel<dynamic> Function(Uri url)? channelFactory,
  }) {
    return SessionSocketService._(
      tokenProvider: () async => jwtToken,
      channelFactory: channelFactory ?? WebSocketChannel.connect,
    );
  }

  factory SessionSocketService.withTokenProvider({
    required Future<String?> Function() tokenProvider,
    StreamChannel<dynamic> Function(Uri url)? channelFactory,
  }) {
    return SessionSocketService._(
      tokenProvider: tokenProvider,
      channelFactory: channelFactory ?? WebSocketChannel.connect,
    );
  }

  Stream<Map<String, dynamic>> get events => _eventsController.stream;
  Stream<bool> get connectionState => _connectionStateController.stream;

  Future<void> connect() async {
    if (_disposed) return;

    try {
      final baseUrl = AppConstants.wsBaseUrl;
      final token = await tokenProvider();
      if (token == null || token.isEmpty || _disposed) return;
      final url = '$baseUrl/ws/stream?token=$token';

      // Drop any previous (closed) channel so writes never hit a dead sink.
      try {
        await _channel?.sink.close();
      } catch (_) {}
      _channel = null;

      _channel = channelFactory(Uri.parse(url));

      // Deliver any frames queued while we were disconnected (subscribe /
      // typing / read). The sink buffers until the socket actually opens.
      _flushOutbox();

      _connectionStateController.add(true);
      _reconnectAttempts = 0;

      _channel!.stream.listen(
        (data) {
          if (_disposed) return;
          try {
            final parsed = jsonDecode(data.toString());
            _eventsController.add(parsed);
          } catch (e) {
            // Ignore malformed messages
          }
        },
        onError: (error) {
          if (!_disposed) {
            _channel = null;
            _connectionStateController.add(false);
            _attemptReconnect();
          }
        },
        onDone: () {
          if (!_disposed) {
            _channel = null;
            _connectionStateController.add(false);
            _attemptReconnect();
          }
        },
      );

      _startHeartbeat();
    } catch (e) {
      if (!_disposed) {
        _connectionStateController.add(false);
        _attemptReconnect();
      }
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _send({'type': 'ping'});
    });
  }

  void _attemptReconnect() {
    if (_disposed || _reconnectAttempts >= _maxReconnectAttempts) return;

    final delay = Duration(
      seconds: [1, 2, 4, 8, 16, 30][_reconnectAttempts.clamp(0, 5)],
    );
    _reconnectAttempts++;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (!_disposed) connect();
    });
  }

  // ── Topic control ───────────────────────────────────────────────────

  void subscribe(String chatId) {
    _send({'type': 'subscribe', 'chat_id': chatId});
  }

  void unsubscribe(String chatId) {
    _send({'type': 'unsubscribe', 'chat_id': chatId});
  }

  // ── Outbound chat frames ────────────────────────────────────────────

  void sendTyping(String chatId) {
    _send({'type': 'typing', 'chat_id': chatId});
  }

  void sendTypingStopped(String chatId) {
    _send({'type': 'typing_stopped', 'chat_id': chatId});
  }

  void sendReadReceipt(String chatId, List<String> messageIds) {
    _send({
      'type': 'read',
      'chat_id': chatId,
      'message_ids': messageIds,
    });
  }

  void _send(Map<String, dynamic> data) {
    if (_disposed) return;
    if (_channel == null) {
      // Socket not (yet) connected — queue the frame so it isn't silently
      // dropped (realtime typing/read/subscribe must survive reconnects).
      _enqueue(data);
      return;
    }
    _flushOutbox();
    try {
      _channel!.sink.add(jsonEncode(data));
    } catch (_) {
      // Sink is dead — drop the channel and queue for the next reconnect.
      _channel = null;
      _enqueue(data);
    }
  }

  // ── Outbox (reliable delivery across reconnects) ─────────────────

  final List<Map<String, dynamic>> _outbox = [];

  void _enqueue(Map<String, dynamic> data) {
    final type = data['type'] as String;
    if (type == 'typing' || type == 'typing_stopped') {
      // Ephemeral — keep only the latest typing state.
      _outbox.removeWhere(
        (f) => f['type'] == 'typing' || f['type'] == 'typing_stopped',
      );
    } else if (type == 'subscribe' || type == 'unsubscribe') {
      final chatId = data['chat_id'];
      _outbox.removeWhere(
        (f) =>
            (f['type'] == 'subscribe' || f['type'] == 'unsubscribe') &&
            f['chat_id'] == chatId,
      );
    } else if (type == 'read') {
      // Merge message ids for the same chat into one frame.
      final chatId = data['chat_id'];
      final existingIdx = _outbox.indexWhere(
        (f) => f['type'] == 'read' && f['chat_id'] == chatId,
      );
      if (existingIdx != -1) {
        final existingIds =
            (_outbox[existingIdx]['message_ids'] as List? ?? const [])
                .cast<String>()
                .toSet();
        final newIds = (data['message_ids'] as List? ?? const [])
            .cast<String>();
        existingIds.addAll(newIds);
        _outbox[existingIdx]['message_ids'] = existingIds.toList();
        return;
      }
    }
    _outbox.add(data);
  }

  void _flushOutbox() {
    if (_channel == null) return;
    while (_outbox.isNotEmpty) {
      final frame = _outbox.removeAt(0);
      try {
        _channel!.sink.add(jsonEncode(frame));
      } catch (_) {
        _outbox.insert(0, frame);
        break;
      }
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _outbox.clear();
    await _channel?.sink.close();
    _channel = null;
    await _eventsController.close();
    await _connectionStateController.close();
  }
}
