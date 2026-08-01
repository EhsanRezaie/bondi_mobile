import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:dating_app/config/app_constants.dart';

class ChatWebSocketService {
  final String matchId;
  final String jwtToken;

  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 6;
  bool _disposed = false;

  final _eventsController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  ChatWebSocketService({
    required this.matchId,
    required this.jwtToken,
  });

  Stream<Map<String, dynamic>> get events => _eventsController.stream;
  Stream<bool> get connectionState => _connectionStateController.stream;

  Future<void> connect() async {
    if (_disposed) return;

    try {
      final baseUrl = AppConstants.wsBaseUrl;
      final url = '$baseUrl/ws/chat/$matchId?token=$jwtToken';

      _channel = WebSocketChannel.connect(Uri.parse(url));

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
      sendPing();
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

  void sendPing() {
    _send({'type': 'ping'});
  }

  void sendTyping() {
    _send({'type': 'typing'});
  }

  void sendTypingStopped() {
    _send({'type': 'typing_stopped'});
  }

  void sendReadReceipt(List<String> messageIds) {
    _send({
      'type': 'read',
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
