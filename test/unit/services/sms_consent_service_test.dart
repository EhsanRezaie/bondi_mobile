import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dating_app/services/sms_consent_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SmsConsentService.extractCode', () {
    test('parses the English OTP template', () {
      expect(
        SmsConsentService.extractCode('Bondi verification code: 123456'),
        '123456',
      );
    });

    test('parses the Persian OTP template', () {
      expect(
        SmsConsentService.extractCode('کد تایید باندی: 654321'),
        '654321',
      );
    });

    test('returns null when there is no 6-digit code', () {
      expect(SmsConsentService.extractCode('Bondi: welcome!'), isNull);
      expect(SmsConsentService.extractCode('code 12345'), isNull);
    });
  });

  group('SmsConsentService stream', () {
    test('emits the parsed code when native delivers an SMS', () async {
      final service = SmsConsentService();
      await service.startListening();

      final codeFuture = service.codes.first;

      await TestDefaultBinaryMessengerBinding
          .instance
          .defaultBinaryMessenger
          .handlePlatformMessage(
            'ir.bondi.app/sms_consent',
            const StandardMethodCodec().encodeMethodCall(
              const MethodCall('onSmsReceived', 'Bondi verification code: 246810'),
            ),
            (_) {},
          );

      expect(await codeFuture, '246810');
    });

    test('ignores messages without a valid code', () async {
      final service = SmsConsentService();
      await service.startListening();

      var emitted = false;
      final sub = service.codes.listen((_) => emitted = true);

      await TestDefaultBinaryMessengerBinding
          .instance
          .defaultBinaryMessenger
          .handlePlatformMessage(
            'ir.bondi.app/sms_consent',
            const StandardMethodCodec().encodeMethodCall(
              const MethodCall('onSmsReceived', 'No code here'),
            ),
            (_) {},
          );
      await Future<void>.delayed(Duration.zero);

      expect(emitted, isFalse);
      await sub.cancel();
    });
  });
}
