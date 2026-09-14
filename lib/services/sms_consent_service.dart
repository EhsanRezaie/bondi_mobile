// lib/services/sms_consent_service.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Wraps Android's SMS User Consent API (implemented in MainActivity.kt).
///
/// The API shows a system "Allow app to read this SMS?" prompt; on approval the
/// message body is delivered here and the 6-digit code is parsed out. No
/// RECEIVE_SMS permission is required. iOS relies on the platform one-time-code
/// autofill instead, so this is a no-op there.
class SmsConsentService {
  SmsConsentService._();

  static final SmsConsentService _instance = SmsConsentService._();
  factory SmsConsentService() => _instance;

  static const MethodChannel _channel = MethodChannel('ir.bondi.app/sms_consent');

  final StreamController<String> _codes = StreamController<String>.broadcast();
  bool _handlerAttached = false;

  /// Emits a parsed 6-digit code whenever the user approves reading an SMS.
  Stream<String> get codes => _codes.stream;

  void _attachHandler() {
    if (_handlerAttached) return;
    _handlerAttached = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSmsReceived') {
        final message = call.arguments as String?;
        if (message != null) {
          final code = extractCode(message);
          if (code != null) _codes.add(code);
        }
      }
      return null;
    });
  }

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Begins listening for the next SMS (valid for ~5 minutes).
  Future<void> startListening() async {
    _attachHandler();
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod<void>('startListening');
    } catch (_) {
      // Autofill is best-effort; manual entry always works.
    }
  }

  Future<void> stopListening() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod<void>('stopListening');
    } catch (_) {
      // ignore
    }
  }

  /// Extracts the first standalone 6-digit code from an SMS body.
  static String? extractCode(String message) {
    final match = RegExp(r'\b(\d{6})\b').firstMatch(message);
    return match?.group(1);
  }
}
