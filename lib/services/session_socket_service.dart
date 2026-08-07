import 'dart:async';
import 'dart:convert';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:dating_app/config/app_constants.dart';

/// Single persistent session socket (`/ws/stream`) held open for the whole app
/// session. Chat-level events are gated by subscribe/unsubscribe topics, so
/// opening a chat never creates a second connection.
class SessionSocketService {
  final String jwtToken;
  final StreamChannel<dynamic> Function(Uri url) channelFactory;

  StreamChannel<dynamic>? _channel;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 6;
  bool _disposed = false;

  final _eventsController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  SessionSocketService({
    required this.jwtToken,
    StreamChannel<dynamic> Function(Uri url)? channelFactory,
  }) : channelFactory = channelFactory ?? WebSocketChannel.connect;

  Stream<Map<String, dynamic>> get events => _eventsController.stream;
  Stream<bool> get connectionState => _connectionStateController.stream;

  Future<void> connect() async {
    if (_disposed) return;

    try {
      final baseUrl = AppConstants.wsBaseUrl;
      final url = '$baseUrl/ws/stream?token=$jwtToken';

      _channel = channelFactory(Uri.parse(url));

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
            _connectionStateController.add(false);
            _attemptReconnect();
          }
        },
        onDone: () {
          if (!_disposed) {
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
    if (_channel != null && !_disposed) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    await _channel?.sink.close();
    await _eventsController.close();
    await _connectionStateController.close();
  }
}
